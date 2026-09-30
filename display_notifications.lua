--[[ Read-only notification canvas for the KOReader sleep screen. ]]

local Device = require("device")
local Screen = Device.screen
local Blitbuffer = require("ffi/blitbuffer")
local Font = require("ui/font")
local TextWidget = require("ui/widget/textwidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local CenterContainer = require("ui/widget/container/centercontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local OverlapGroup = require("ui/widget/overlapgroup")
local _ = require("l10n/gettext")
local T = require("ffi/util").template

local NotificationDisplay = {}

function NotificationDisplay:create(_, data)
    local margin = Screen:scaleBySize(28)
    local title_size = Screen:scaleBySize(36)
    local heading_size = Screen:scaleBySize(28)
    local body_size = Screen:scaleBySize(24)
    local meta_size = Screen:scaleBySize(18)
    local width = Screen:getWidth() - margin * 2
    local widgets = {}

    table.insert(widgets, TextWidget:new {
        text = _("AI NOTIFICATIONS"),
        face = Font:getFace("cfont", title_size),
        bold = true,
    })
    table.insert(widgets, VerticalSpan:new { width = Screen:scaleBySize(10) })
    table.insert(widgets, TextWidget:new {
        text = T(_("%1 pending"), tonumber(data.unread_count) or #data.items),
        face = Font:getFace("cfont", heading_size),
    })
    table.insert(widgets, VerticalSpan:new { width = Screen:scaleBySize(16) })

    if data.needs_setup then
        table.insert(widgets, TextBoxWidget:new {
            text = _("Set the notification feed URL in Tools > Weather & Notifications Lockscreen."),
            face = Font:getFace("cfont", body_size),
            width = width - margin,
            alignment = "center",
        })
    elseif #data.items == 0 then
        table.insert(widgets, TextBoxWidget:new {
            text = _("No pending notifications."),
            face = Font:getFace("cfont", body_size),
            width = width - margin,
            alignment = "center",
        })
    else
        for index, item in ipairs(data.items) do
            if index > 1 then table.insert(widgets, VerticalSpan:new { width = Screen:scaleBySize(12) }) end
            local card = VerticalGroup:new {
                align = "left",
                TextBoxWidget:new {
                    text = item.title,
                    face = Font:getFace("cfont", heading_size),
                    bold = true,
                    width = width - margin,
                },
                VerticalSpan:new { width = Screen:scaleBySize(5) },
                TextBoxWidget:new {
                    text = item.summary,
                    face = Font:getFace("cfont", body_size),
                    width = width - margin,
                    alignment = "left",
                },
            }
            table.insert(widgets, FrameContainer:new {
                padding = Screen:scaleBySize(14),
                margin = 0,
                bordersize = Screen:scaleBySize(1),
                radius = 0,
                background = Blitbuffer.COLOR_WHITE,
                card,
            })
        end
    end

    table.insert(widgets, VerticalSpan:new { width = Screen:scaleBySize(18) })
    local update_label = data.updated_at and data.updated_at ~= "" and data.updated_at
        or data.fetched_at and os.date("%Y-%m-%d %H:%M", data.fetched_at)
        or _("Not updated yet")
    if data.cached then update_label = update_label .. "  ·  " .. _("cached") end
    table.insert(widgets, TextWidget:new {
        text = T(_("Updated: %1"), update_label),
        face = Font:getFace("cfont", meta_size),
        fgcolor = Blitbuffer.COLOR_DARK_GRAY,
    })
    local content = VerticalGroup:new { align = "center", unpack(widgets) }
    local framed = FrameContainer:new {
        width = width,
        height = Screen:getHeight() - margin * 2,
        padding = margin,
        margin = 0,
        bordersize = 0,
        content,
    }
    return OverlapGroup:new {
        dimen = Screen:getSize(),
        CenterContainer:new { dimen = Screen:getSize(), framed },
    }
end

return NotificationDisplay
