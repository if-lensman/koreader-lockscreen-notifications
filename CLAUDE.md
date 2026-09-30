# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A KOReader plugin (Lua) centered on a read-only notification feed rendered on an e-reader's sleep screen. Optional inherited weather displays remain available. It runs *inside* the KOReader runtime — there is no standalone app. KOReader globals/modules (`G_reader_settings`, `Screen`, `Blitbuffer`, `UIManager`, `require("ui/widget/...")`, `require("device")`, etc.) only exist at runtime on-device, so screen behavior must ultimately be checked in KOReader on a device.

## Commands

```bash
# Syntax-check (this is the entire CI "test" suite; uses lua5.1 / luac)
luac -p main.lua                 # check a single file
find . -name '*.lua' -not -path './.git/*' -exec luac -p {} \;   # check all

# Compile translations (.po -> .mo); run before packaging if .po changed
./compile_translations.sh

# Build the distributable notificationslockscreen.koplugin zip (also compiles translations)
./create-release.sh <version>    # e.g. ./create-release.sh v0.9.7-beta.1
```

CI (`.github/workflows/test.yml`) only runs `luac -p` on every `.lua` file — there are no unit tests. `compile-translations.yml` auto-recompiles `.mo` files on push when `.po`/`.pot` files change and commits them back, so a missing `.mo` is corrected by CI but should be compiled locally for PRs.

Version lives in `_meta.lua`. Release archives are named `notificationslockscreen.koplugin-<version>.zip`.

## Architecture

### Entry + screensaver injection (the non-obvious core)
`_meta.lua` declares the plugin; `main.lua` is the entry point. KOReader has no public "custom screensaver type" API, so `main.lua` **monkey-patches** at `init()`:

- `patchScreensaver()` wraps `Screensaver.show`. It handles `screensaver_type == "notifications"` as the primary screen and `"weather"` as an optional inherited mode. The original method is stashed as `Screensaver._orig_show_before_notifications` and used as the fallback path.
- `patchDofile()` wraps the global `dofile` to inject notification and optional weather radio options into KOReader's Sleep Screen > Wallpaper menu.

This is why the plugin appears as a wallpaper choice without modifying KOReader itself. Changes to how the sleep screen is entered usually touch these two patches.

### Display strategy pattern
`createWeatherWidget()` reads the `weather_display_style` setting and dispatches through a map to a `display_*.lua` module:

| setting value | module          |
|---------------|-----------------|
| `default`     | display_default |
| `card`        | display_card    |
| `day`         | display_day     |
| `nightowl`    | display_nightowl|
| `retro`       | display_retro   |
| `reading`     | display_reading |

Every display module exposes `Module:create(weather_lockscreen, weather_data)` returning a KOReader widget. To add a mode: create `display_<name>.lua` with that method, add it to the `display_modules` map in `main.lua:createWeatherWidget()`, and add a menu entry in `weather_menu.lua`.

`display_helper.lua` holds the shared building blocks every display reuses: `createHeaderWidgets`, `createLoadingWidget`, `buildHourlyRow`, and `scaleToFit(buildFunc, available_height, default_fill)`.

### Dynamic scaling
Displays define DPI-independent **base** sizes, build content at scale 1.0, measure `getSize().h`, then rebuild at a computed scale factor so content fills the screen. Use `DisplayHelper:scaleToFit` rather than re-implementing this. Respect the `weather_override_scaling` / `weather_fill_percent` settings.

### Module responsibilities
- `main.lua` — notification-first lifecycle, settings init/defaults, the two monkey-patches, periodic-refresh scheduling, event handlers (`onSuspend`/`onResume`/etc).
- `notification_api.lua` — fetches, validates, bounds, and caches a plain-text JSON feed. It does not execute feed content or store model credentials.
- `display_notifications.lua` — renders the cached/current feed as a non-interactive sleep-screen canvas.
- `weather_api.lua` — HTTP fetch (`fetchWeatherData`), `processWeatherData` (API JSON → internal table), location search. All network calls go through a `pcall` wrapper; on failure it falls back to cache.
- `weather_utils.lua` — caching, icon path resolution/download, device detection, time/hour formatting, localization helpers. Plugin dir is resolved via `debug.getinfo`.
- `weather_dashboard.lua` — full-screen live dashboard mode.
- `display_*.lua` / `display_helper.lua` — rendering only.

### Periodic refresh — two distinct mechanisms
- **Active Sleep (RTC)**: device wakes from suspend, refreshes, re-sleeps. Uses `WakeupMgr` (`schedulePeriodicRefresh()`). Kindle supported; Kobo experimental; gated on Wi-Fi auto-on and a battery-floor (`weather_active_sleep_min_battery`). Setting: `weather_periodic_refresh_rtc` (minutes, 0 = off).
- **Dashboard**: screen stays on, refreshes via `UIManager:scheduleIn`. All devices, higher battery use. Setting: `weather_periodic_refresh_dashboard`.

## Settings conventions
Inherited weather settings are prefixed `weather_`; notification settings use `notification_`. They are persisted in `G_reader_settings` and **must be given a default in `main.lua:initDefaultSettings()`** (the loop only writes a default when the key is currently `nil`, so existing users keep their value — preserve backward compatibility). Always `G_reader_settings:flush()` after saving. Time values are stored in **seconds**.

Debug-only menu items are gated on `G_reader_settings:isTrue("weather_debug_options")`; debug mode is toggled by entering `debug on` / `debug off` in the location search box.

## Localization
Custom gettext: `require("l10n/gettext")`, strings wrapped `_("...")`, formatted strings via `T(_("... %1"), x)` (`T = require("ffi/util").template`). Sources live in `l10n/<lang>/koreader.po` (`de`, `es`, `tr`, `zh_CN`) plus `l10n/template.pot`. Adding a user-facing string means updating `template.pot` and each `.po`, then recompiling. Weather *conditions* are localized server-side by WeatherAPI based on the language code.

## External API
WeatherAPI.com forecast endpoint. A shared community key is bundled as `default_api_key` in `main.lua` (users may override via `weather_api_key`). It backs all users — honor the rate-limit guards: `weather_min_update_delay` between live calls and `weather_cache_max_age` for serving cached data offline (cached timestamps are marked with `*`).
