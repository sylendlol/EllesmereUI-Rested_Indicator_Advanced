if EUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (EllesmereUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  EllesmereUI_RestedStyle \ RestedStyle_Options.lua   (standalone add-on)
--
--  QoL > Rested Indicator cog, without touching EllesmereUI files:
--  EllesmereUI.BuildInlineCog (EllesmereUI_Widgets_RowAddons.lua, deferred
--  init of the LoD EllesmereUIOptions) is wrapped. The stock cog titled
--  "Rested Indicator Position" (X/Y Offset) gets our rows around its own:
--  Style, Preview, Anchor, Anchor To, X/Y (stock), then the selected style's
--  settings (rows of the other styles use row.hidden, so the popup swaps to
--  the matching layout when the Style changes).
--  If EUI renames that cog title, the interception silently stops and the
--  stock X/Y cog is shown unchanged.
-------------------------------------------------------------------------------
local EllesmereUI = _G.EllesmereUI
local RS = _G.EllesmereUI_RestedStyle
if not (EllesmereUI and RS) then return end

local STOCK_TITLE = "Rested Indicator Position"

local function Is(style) return function() return RS.Style() ~= style end end
local function NotEUI() return RS.Style() == "eui" end

local function Slider(label, key, mn, mx, step, hidden, extra)
    local r = { type = "slider", label = label, min = mn, max = mx, step = step, hidden = hidden,
        get = function() return RS.Get(key) end,
        set = function(v) RS.Set(key, v) end }
    if extra then for k, v in pairs(extra) do r[k] = v end end
    return r
end

local function Toggle(label, key, hidden, extra)
    local r = { type = "toggle", label = label, hidden = hidden,
        get = function() return RS.Get(key) and true or false end,
        set = function(v) RS.Set(key, v and true or false) end }
    if extra then for k, v in pairs(extra) do r[k] = v end end
    return r
end

local function Drop(label, key, values, order, hidden, extra)
    local r = { type = "dropdown", label = label, values = values, order = order, hidden = hidden,
        get = function()
            local v = RS.Get(key)
            if values[v] == nil then v = RS.DEFAULTS[key] end
            return v
        end,
        set = function(v) RS.Set(key, v) end }
    if extra then for k, v in pairs(extra) do r[k] = v end end
    return r
end

local function Color(label, key, hasAlpha, hidden, extra)
    local r = { type = "colorpicker", label = label, hasAlpha = hasAlpha, hidden = hidden,
        get = function() return RS.GetColor(key) end,
        set = function(cr, cg, cb, ca) RS.SetColor(key, cr, cg, cb, hasAlpha and ca or 1) end }
    if extra then for k, v in pairs(extra) do r[k] = v end end
    return r
end

local function BuildRows(stockRows)
    local rows = {}
    local function add(r) rows[#rows + 1] = r end

    add(Drop("Style", "style", RS.STYLES, RS.STYLE_ORDER, nil,
        { tooltip = "Look of the rested indicator on your player frame." }))
    add({ type = "toggle", label = "Preview",
        tooltip = "Shows the indicator outside a resting area too, so you can see your changes. Not saved (also /eurest).",
        get = function() return RS.preview end,
        set = function(v) RS.SetPreview(v) end })
    add(Drop("Anchor", "anchor", RS.ANCHOR_VALUES, RS.ANCHOR_ORDER, NotEUI))
    add(Drop("Anchor To", "anchorTo", RS.ANCHOR_TO_VALUES, RS.ANCHOR_TO_ORDER, NotEUI))
    for _, r in ipairs(stockRows or {}) do add(r) end

    -- Blizzard (animated)
    local hb = Is("blizzard")
    add(Slider("Size", "b_size", 10, 64, 1, hb))
    add(Color("Tint", "b_color", true, hb,
        { tooltip = "White keeps Blizzard's original colors." }))
    add(Toggle("Animate", "b_animate", hb))
    add(Slider("Animation Speed %", "b_speed", 25, 300, 5, hb,
        { disabled = function() return not RS.Get("b_animate") end, disabledTooltip = "Animate" }))
    add(Toggle("Desaturate", "b_desat", hb,
        { tooltip = "Grey version of the art; combine with Tint for any color." }))

    -- Classic Badge
    local hc = Is("badge")
    add(Slider("Size", "c_size", 10, 64, 1, hc))
    add(Drop("Text", "c_text", RS.BADGE_TEXT_VALUES, RS.BADGE_TEXT_ORDER, hc))
    add(Slider("Text Size %", "c_textScale", 30, 100, 1, hc))
    add(Drop("Font", "c_font", RS.FONT_VALUES, RS.FONT_ORDER, hc))
    add(Color("Text Color", "c_textColor", false, hc))
    add(Color("Background", "c_bgColor", true, hc))
    add(Toggle("Ring", "c_ring", hc))
    local function ringOff() return not RS.Get("c_ring") end
    add(Toggle("Ring Uses Accent Color", "c_ringAccent", hc,
        { disabled = ringOff, disabledTooltip = "Ring" }))
    add(Color("Ring Color", "c_ringColor", false, hc,
        { disabled = function() return ringOff() or RS.Get("c_ringAccent") end,
          disabledTooltip = "Ring, and Ring Uses Accent Color off" }))
    add(Slider("Ring Thickness", "c_ringSize", 1, 5, 1, hc,
        { disabled = ringOff, disabledTooltip = "Ring" }))
    add(Toggle("Pulse", "c_pulse", hc))

    -- Floating Letters
    local hf = Is("float")
    add(Slider("Letters", "f_count", 1, 5, 1, hf))
    add(Slider("Letter Size", "f_size", 8, 40, 1, hf,
        { tooltip = "Size of the largest letter; the earlier ones are smaller." }))
    add(Drop("Letters Case", "f_case", RS.CASE_VALUES, RS.CASE_ORDER, hf))
    add(Drop("Font", "f_font", RS.FONT_VALUES, RS.FONT_ORDER, hf))
    add(Drop("Outline", "f_outline", RS.OUTLINE_VALUES, RS.OUTLINE_ORDER, hf))
    add(Drop("Color", "f_colorMode", RS.COLOR_MODE_VALUES, RS.COLOR_MODE_ORDER, hf))
    add(Color("Custom Color", "f_color", false, function() return hf() or RS.Get("f_colorMode") ~= "custom" end))
    add(Slider("Cycle Time (sec)", "f_cycle", 0.5, 6, 0.1, hf,
        { tooltip = "Seconds a letter needs to rise and fade. Lower is faster." }))
    add(Slider("Rise Height", "f_rise", 0, 40, 1, hf))
    add(Slider("Drift", "f_drift", -30, 30, 1, hf,
        { tooltip = "Sideways movement while rising: positive to the right, negative to the left." }))
    add(Slider("Opacity %", "f_alpha", 10, 100, 5, hf))

    -- Icon Square
    local hq = Is("square")
    add(Slider("Size", "q_size", 10, 64, 1, hq))
    add(Drop("Text", "q_text", RS.BADGE_TEXT_VALUES, RS.BADGE_TEXT_ORDER, hq))
    add(Slider("Text Size %", "q_textScale", 30, 100, 1, hq))
    add(Drop("Font", "q_font", RS.FONT_VALUES, RS.FONT_ORDER, hq))
    add(Color("Text Color", "q_textColor", false, hq))
    add(Color("Background", "q_bgColor", true, hq))
    add(Slider("Border Thickness", "q_borderSize", 0, 4, 1, hq))
    local function borderOff() return RS.Get("q_borderSize") <= 0 end
    add(Toggle("Border Uses Accent Color", "q_borderAccent", hq,
        { disabled = borderOff, disabledTooltip = "Border Thickness above 0" }))
    add(Color("Border Color", "q_borderColor", false, hq,
        { disabled = function() return borderOff() or RS.Get("q_borderAccent") end,
          disabledTooltip = "Border Thickness above 0, and Border Uses Accent Color off" }))
    add(Toggle("Pulse", "q_pulse", hq))
    add(Slider("Pulse Amount %", "q_pulseAmt", 2, 40, 1, hq,
        { disabled = function() return not RS.Get("q_pulse") end, disabledTooltip = "Pulse" }))

    return rows
end

local function Wrap()
    if RS.cogWrapped then return true end
    local orig = EllesmereUI.BuildInlineCog
    if type(orig) ~= "function" then return false end
    RS.cogWrapped = true
    EllesmereUI.BuildInlineCog = function(rgn, opts, ...)
        if type(opts) == "table" and opts.title == STOCK_TITLE and not opts._rsDone then
            local o = {}
            for k, v in pairs(opts) do o[k] = v end
            o._rsDone = true
            o.title = "Rested Indicator"
            o.rows = BuildRows(opts.rows)
            o.minWidth = math.max(opts.minWidth or 0, 300)
            return orig(rgn, o, ...)
        end
        return orig(rgn, opts, ...)
    end
    return true
end

local function Install()
    if Wrap() then return end
    local list = EllesmereUI._deferredInits
    if type(list) == "table" then
        list[#list + 1] = function() Wrap() end
    end
end

local IsLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
if IsLoaded and IsLoaded("EllesmereUIOptions") then
    Install()
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
        if name == "EllesmereUIOptions" then
            Install()
            self:UnregisterAllEvents()
        end
    end)
end
