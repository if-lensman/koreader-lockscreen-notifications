# 局域网通知示例服务

此目录提供一个只依赖 Python 3 标准库的只读 JSON 服务。它把 `notifications.json` 提供给同一可信局域网内的 KOReader Kindle。

在 Mac 上运行：

```sh
cd examples
python3 serve_feed.py --host 192.168.1.20 --port 8765
```

在 KOReader 中打开“工具 > 锁屏通知”，将通知源地址设置为：

```text
http://192.168.1.20:8765/notifications.json
```

先用 Kindle 浏览器访问该地址，确认能看到 JSON；再回到 KOReader 的“锁屏通知”菜单保存该地址。刷新或重新进入睡眠屏幕后，测试通知会显示在画布上。服务终端会记录 Kindle 的请求。

编辑 `notifications.json` 即可更新标题、摘要和未读数量。服务每次请求都会重新读取文件。按 `Ctrl+C` 停止。

示例里的 `192.168.1.20` 要替换为 Mac 当前的局域网地址。macOS 可先用 `route -n get default` 确认默认路由接口，再运行 `ipconfig getifaddr <接口名>` 查询地址。服务只绑定到指定的局域网接口；地址变化时请用新地址重启服务。建议在路由器里给 Mac 设置 DHCP 地址保留。

这个示例只适合可信的家庭局域网，不包含身份验证，也不要配置路由器端口映射将它暴露到公网。Mac 休眠或关机时服务会停止。
