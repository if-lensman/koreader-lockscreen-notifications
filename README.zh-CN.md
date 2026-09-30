# KOReader 锁屏通知

这是一个 KOReader 插件，可在 Kindle 睡眠屏幕显示只读通知。插件按设定间隔唤醒设备，从电脑或家庭服务器获取 JSON，再刷新屏幕并返回睡眠。Kindle 不运行 AI 模型，也不能批准或执行通知中的操作。

通知画布沿用了 [loeffner/WeatherLockscreen](https://github.com/loeffner/WeatherLockscreen) 的睡眠屏幕刷新机制。项目现在以锁屏通知为主，天气显示作为可选功能保留。

## 功能

- 显示未读数量和最多三条简短通知。
- 通过 HTTP 或 HTTPS 获取 JSON。
- 缓存上次成功获取的内容，离线时继续显示。
- 使用 KOReader 的 Active Sleep 唤醒计划和电量阈值。
- AI 模型与 API 凭据留在生成通知的电脑或服务器上。
- 通知为只读内容；没有确认按钮，也不接受远程命令。
- 插件界面默认简体中文，可切换英语或跟随 KOReader 语言。

通知卡片的标题和摘要直接显示 JSON 中的文本，支持中文和 UTF-8 内容；插件不会翻译或改写通知正文。

## 安装

从 Release 下载插件，将 `notificationslockscreen.koplugin` 文件夹放入 KOReader 插件目录，然后重启 KOReader。Kindle 上的目录为：

```text
/mnt/us/koreader/plugins/notificationslockscreen.koplugin/
```

## 配置

1. 在 KOReader 中打开“工具 > 锁屏通知”，设置通知源 URL。插件语言默认是简体中文，可在此菜单中切换英语或跟随 KOReader 语言。
2. 打开“设置 > 屏幕 > 睡眠屏幕 > 壁纸”，选择“在睡眠屏幕显示通知”。
3. 在“工具 > 锁屏通知”中设置 Active Sleep 刷新间隔。该功能默认关闭；需要将 KOReader 的 Wi-Fi 动作设为“开启”。
4. 如需天气画布，可在“工具 > 天气显示（可选）”配置。

设备使用电池时，Active Sleep 使用设备唤醒管理器。连接外部电源时，插件改用 KOReader 待机计时器，因为 Kindle 深度休眠时不会响应 RTC 闹钟。实际休眠、唤醒和耗电表现需在目标 Kindle 与固件上验证。

## 通知 JSON 示例

```json
{
  "updated_at": "2026-09-30 14:30",
  "unread_count": 1,
  "items": [
    {
      "title": "需要你查看项目记录",
      "summary": "AI 工作流发现一条可能需要处理的记录。",
      "created_at": "2026-09-30 14:25"
    }
  ]
}
```

字段限制和配置说明见 [`docs/notification-feed.md`](docs/notification-feed.md)。请使用可信的家庭网络，不要在 URL 中放入密码或 API Key。当前版本不支持认证请求头。

## 许可与来源

本项目使用 GNU AGPL-3.0 许可。项目基于 Andreas Lösel 的 [WeatherLockscreen](https://github.com/loeffner/WeatherLockscreen) 修改，保留其原有许可与署名。
