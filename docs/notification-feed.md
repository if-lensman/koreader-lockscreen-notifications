# Notification feed

The notification canvas reads one JSON document with an HTTP `GET`. It is intended for a trusted home network. Keep model credentials and upstream API keys on the computer or server that creates this document; do not put them in the Kindle URL or feed.

## Response format

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

`items` must be an array. `title` and either `summary` or `body` are plain text. `updated_at`, `unread_count`, and `created_at` are optional. The display shows at most three items. Long text is shortened to keep the sleep screen readable. The feed is informational; it cannot send commands to KOReader or the Kindle.

## Setup

1. Serve the JSON from a stable address reachable on the same trusted Wi-Fi network as the Kindle. A small endpoint on a home computer or NAS is sufficient.
2. In KOReader, open **Tools > Weather & Notifications Lockscreen** and enter the feed URL, for example `http://192.168.1.20:8080/notifications.json`.
3. In **Settings > Screen > Sleep Screen > Wallpaper**, choose **Show notifications on sleep screen**.
4. Set **Active Sleep** to a refresh interval if you want the sleep screen to refresh while the Kindle is on battery. It remains off until enabled. The feature requires KOReader's Wi-Fi action to be set to **Turn on**.

On battery, the existing RTC-based Active Sleep path wakes the device at the configured interval, fetches the feed, updates the screen, and suspends again. While connected to external power, the upstream plugin uses a standby timer because Kindle RTC wakeups do not fire during deep suspend on power. Device behavior and battery use still need to be checked on each Kindle model and firmware.

The plugin stores the last successful response locally and can show it when the feed is unreachable. Do not expose an unauthenticated notification feed outside your trusted LAN; this first version intentionally has no credential or arbitrary-header setting.
