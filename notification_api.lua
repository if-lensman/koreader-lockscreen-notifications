--[[
    Read-only notification feed for the notification sleep screen.
    The feed contains plain text only; it cannot trigger device actions.
]]

local DataStorage = require("datastorage")
local logger = require("logger")

local NotificationAPI = {}
local CACHE_PATH = DataStorage:getDataDir() .. "/notification_feed_cache.json"
local MAX_RESPONSE_BYTES = 65536
local MAX_ITEMS = 3

local function limitedSink(chunks)
    local size = 0
    return function(chunk)
        if chunk then
            size = size + #chunk
            if size > MAX_RESPONSE_BYTES then
                return nil, "notification response too large"
            end
            chunks[#chunks + 1] = chunk
        end
        return 1
    end
end

local function httpGet(url)
    local chunks = {}
    local sink = limitedSink(chunks)
    local ok_ssl, https = pcall(require, "ssl.https")
    if url:match("^https://") and ok_ssl and https and https.request then
        https.TIMEOUT = 15
        local ok, result, code, _, status = pcall(https.request, { url = url, sink = sink })
        if not ok then return nil, table.concat(chunks), result end
        if not status and result ~= 1 then status = result end
        return code, table.concat(chunks), status
    end

    if url:match("^https://") then return nil, "", "HTTPS client unavailable" end
    local ok_http, http = pcall(require, "socket.http")
    if not ok_http or not http or not http.request then
        return nil, "", "no HTTP client available"
    end
    http.TIMEOUT = 15
    local ok, result, code, _, status = pcall(http.request, { url = url, sink = sink })
    if not ok then return nil, table.concat(chunks), result end
    if not status and result ~= 1 then status = result end
    return code, table.concat(chunks), status
end

local function boundedText(value, max_bytes)
    if type(value) ~= "string" then return "" end
    value = value:gsub("\r\n", "\n"):gsub("\r", "\n")
        :gsub("[%z\1-\8\11\12\14-\31\127]", "")
    if #value <= max_bytes then return value end

    -- Avoid cutting a UTF-8 continuation sequence at the end of the field.
    local cut = max_bytes
    while cut > 0 do
        local byte = value:byte(cut)
        if not byte or byte < 128 or byte >= 192 then break end
        cut = cut - 1
    end
    local lead = value:byte(cut)
    local expected = lead and lead >= 240 and 4 or lead and lead >= 224 and 3 or lead and lead >= 192 and 2 or 1
    if cut + expected - 1 > max_bytes then cut = cut - 1 end
    return value:sub(1, math.max(cut, 0))
end

local function normalize(payload)
    if type(payload) ~= "table" or type(payload.items) ~= "table" then
        return nil, "expected an object with an items array"
    end

    local data = {
        updated_at = boundedText(payload.updated_at, 48),
        unread_count = math.max(0, math.min(999, tonumber(payload.unread_count) or #payload.items)),
        items = {},
    }
    for _, item in ipairs(payload.items) do
        if #data.items >= MAX_ITEMS then break end
        if type(item) == "table" then
            local title = boundedText(item.title, 180)
            local summary = boundedText(item.summary or item.body, 420)
            if title ~= "" or summary ~= "" then
                data.items[#data.items + 1] = {
                    title = title ~= "" and title or "Notification",
                    summary = summary,
                    created_at = boundedText(item.created_at, 48),
                }
            end
        end
    end
    return data
end

local function readCache()
    local file = io.open(CACHE_PATH, "r")
    if not file then return nil end
    local contents = file:read("*a")
    file:close()
    local ok, value = pcall(require("json").decode, contents)
    if not ok or type(value) ~= "table" or type(value.data) ~= "table" then return nil end
    local data = normalize(value.data)
    if not data then return nil end
    data.cached = true
    data.fetched_at = tonumber(value.fetched_at)
    return data
end

local function writeCache(data)
    local json = require("json")
    local file = io.open(CACHE_PATH .. ".tmp", "w")
    if not file then return end
    file:write(json.encode { fetched_at = os.time(), data = data })
    file:close()
    os.rename(CACHE_PATH .. ".tmp", CACHE_PATH)
end

function NotificationAPI:fetchNotificationData(plugin)
    local cached = readCache()
    if plugin.prefer_cache then return cached or { items = {}, unread_count = 0, cached = true } end

    local max_age = tonumber(G_reader_settings:readSetting("notification_cache_max_age")) or 86400
    if not plugin.refresh and cached and cached.fetched_at and os.time() - cached.fetched_at < 60 then
        return cached
    end

    local url = G_reader_settings:readSetting("notification_feed_url") or ""
    if url == "" then
        return cached or { items = {}, unread_count = 0, needs_setup = true }
    end
    if not url:match("^https?://") or url:match("^https?://[^/]*@") then
        logger.warn("LockscreenNotifications: Notification feed URL must be HTTP(S) without embedded credentials")
        if cached and cached.fetched_at and os.time() - cached.fetched_at <= max_age then return cached end
        return nil
    end

    local code, body, status = httpGet(url)
    if tonumber(code) ~= 200 then
        logger.warn("LockscreenNotifications: Notification feed request failed:", code or status or "network error")
        if cached and cached.fetched_at and os.time() - cached.fetched_at <= max_age then return cached end
        return nil
    end

    local ok, payload = pcall(require("json").decode, body)
    local data, err
    if ok then data, err = normalize(payload) else err = payload end
    if not data then
        logger.warn("LockscreenNotifications: Invalid notification feed:", err or "invalid JSON")
        if cached and cached.fetched_at and os.time() - cached.fetched_at <= max_age then return cached end
        return nil
    end

    data.cached = false
    data.fetched_at = os.time()
    writeCache(data)
    plugin.refresh = false
    return data
end

function NotificationAPI:clearCache()
    return os.remove(CACHE_PATH)
end

return NotificationAPI
