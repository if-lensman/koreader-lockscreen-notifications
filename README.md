# KOReader Lock Screen Notifications

A KOReader plugin for showing a small, read-only notification feed on the Kindle sleep screen. The plugin wakes on a configurable interval, fetches JSON from a computer or home server, refreshes the screen, and suspends again. It does not require an AI model on the Kindle and it cannot approve or execute actions.

The notification feature reuses the sleep-screen lifecycle from [loeffner/WeatherLockscreen](https://github.com/loeffner/WeatherLockscreen). The project has a new identity and focuses on lock-screen notifications; optional weather display remains available as a secondary mode.

## Features

- Render the unread count and up to three short notification cards.
- Fetch a plain JSON feed over HTTP or HTTPS.
- Cache the last successful response for offline display.
- Reuse KOReader's Active Sleep refresh scheduling and battery threshold.
- Keep model/API credentials on the host that produces the feed.
- Keep notifications read-only: there are no approval buttons or remote commands.

## Install

Copy the contents of `notificationslockscreen.koplugin` from a release into KOReader's plugins directory, then restart KOReader. On Kindle the directory is `/mnt/us/koreader/plugins/notificationslockscreen.koplugin/`.

## Configure

1. In KOReader, open **Tools > Lock Screen Notifications** and set the notification feed URL.
2. Open **Settings > Screen > Sleep Screen > Wallpaper** and select **Show notifications on sleep screen**.
3. In **Tools > Lock Screen Notifications**, set an **Active Sleep** refresh interval. Refreshing remains disabled until configured. The Wi-Fi action must be set to **Turn on**.
4. Optionally configure **Tools > Weather display (optional)** to use the inherited weather screen.

On battery, Active Sleep uses the device wakeup manager. While external power is connected, the plugin uses KOReader's standby timer because a Kindle in deep suspend does not respond to the RTC alarm. Actual sleep/wake and battery behavior must be confirmed on the target Kindle and firmware.

## Feed format

```json
{
  "updated_at": "2026-09-30 14:30",
  "unread_count": 1,
  "items": [
    {
      "title": "Review the project note",
      "summary": "The AI workflow found a note that may need your attention.",
      "created_at": "2026-09-30 14:25"
    }
  ]
}
```

See [`docs/notification-feed.md`](docs/notification-feed.md) for field limits and setup notes. Use a trusted home network and do not put passwords or API keys in the URL. This first version does not support authentication headers.

## License and credits

This project is distributed under the GNU Affero General Public License v3.0. It is derived from [WeatherLockscreen](https://github.com/loeffner/WeatherLockscreen) by Andreas Lösel; its original license and attribution are retained.
