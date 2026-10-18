if EUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (EllesmereUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  EllesmereUI_RestedStyle \ RestedStyle.lua   (standalone add-on)
--
--  Replaces the plain "ZZZ" text of EllesmereUI's Rested Indicator (QoL page)
--  with a selectable, customizable style. No EllesmereUI file is modified:
--    * EUI keeps its own FontString (pf._restIndicator) and keeps driving it
--      (Show/Hide on PLAYER_UPDATE_RESTING, X/Y offsets from its cog).
--    * We hook that FontString's Show/Hide/SetShown/SetPoint, make it
--      invisible (alpha 0) and mirror its visibility on our own frame.
--
--  Styles (EllesmereUI_RestedStyleDB.style):
--    eui      - EllesmereUI's original "ZZZ" text (nothing changed)
--    blizzard - Blizzard's animated rest flipbook (read from the client's own
--               PlayerFrame when present; static UI-StateIcon as fallback)
--    badge    - round badge with "Zz"
--    float    - rising, fading Z letters (UI Accent Color by default)
--    square   - buff-icon style square with a pulsing "Z"
--
--  Options: RestedStyle_Options.lua (QoL > Rested Indicator cog).
-------------------------------------------------------------------------------
local EllesmereUI = _G.EllesmereUI
local ns = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS["EllesmereUIUnitFrames"]

local RS = {}
_G.EllesmereUI_RestedStyle = RS

RS.STYLES = {
    eui      = "EllesmereUI (ZZZ text)",
    blizzard = "Blizzard (animated)",
    badge    = "Classic Badge",
    float    = "Floating Letters",
    square   = "Icon Square",
}
RS.STYLE_ORDER = { "blizzard", "badge", "float", "square", "eui" }

-- point on our icon, relative point on the anchor target
RS.ANCHORS = {
    inside_tl = { "TOPLEFT",     "TOPLEFT",     "Inside Top Left" },
    inside_t  = { "TOP",         "TOP",         "Inside Top" },
    inside_tr = { "TOPRIGHT",    "TOPRIGHT",    "Inside Top Right" },
    center    = { "CENTER",      "CENTER",      "Center" },
    above_l   = { "BOTTOMLEFT",  "TOPLEFT",     "Above Left" },
    above_c   = { "BOTTOM",      "TOP",         "Above Center" },
    above_r   = { "BOTTOMRIGHT", "TOPRIGHT",    "Above Right" },
    out_l     = { "RIGHT",       "LEFT",        "Outside Left" },
    out_r     = { "LEFT",        "RIGHT",       "Outside Right" },
}
RS.ANCHOR_ORDER = { "inside_tl", "inside_t", "inside_tr", "center", "above_l", "above_c", "above_r", "out_l", "out_r" }
RS.ANCHOR_VALUES = {}
for k, v in pairs(RS.ANCHORS) do RS.ANCHOR_VALUES[k] = v[3] end

RS.ANCHOR_TO_VALUES = { health = "Health Bar", frame = "Player Frame" }
RS.ANCHOR_TO_ORDER  = { "health", "frame" }

RS.FONTS = {
    eui      = { "EllesmereUI Font", nil },
    friz     = { "Friz Quadrata", "Fonts\\FRIZQT__.TTF" },
    morpheus = { "Morpheus", "Fonts\\MORPHEUS.TTF" },
    skurri   = { "Skurri", "Fonts\\SKURRI.TTF" },
    arialn   = { "Arial Narrow", "Fonts\\ARIALN.TTF" },
}
RS.FONT_ORDER = { "eui", "morpheus", "friz", "skurri", "arialn" }
RS.FONT_VALUES = {}
for k, v in pairs(RS.FONTS) do RS.FONT_VALUES[k] = v[1] end

RS.OUTLINE_VALUES = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" }
RS.OUTLINE_ORDER  = { "NONE", "OUTLINE", "THICKOUTLINE" }

RS.COLOR_MODE_VALUES = { accent = "UI Accent Color", class = "Class Color", gold = "Gold", custom = "Custom" }
RS.COLOR_MODE_ORDER  = { "accent", "class", "gold", "custom" }

RS.BADGE_TEXT_VALUES = { Zz = "Zz", Zzz = "Zzz", zZ = "zZ", Z = "Z" }
RS.BADGE_TEXT_ORDER  = { "Zz", "Zzz", "zZ", "Z" }

RS.CASE_VALUES = { mixed = "Growing (z z Z)", upper = "Upper (Z Z Z)", lower = "Lower (z z z)" }
RS.CASE_ORDER  = { "mixed", "upper", "lower" }

RS.DEFAULTS = {
    style    = "blizzard",
    anchor   = "inside_tl",
    anchorTo = "health",

    -- Blizzard flipbook
    b_size     = 24,
    b_color    = { r = 1, g = 1, b = 1, a = 1 },
    b_animate  = true,
    b_speed    = 100,
    b_desat    = false,

    -- Classic badge
    c_size      = 20,
    c_text      = "Zz",
    c_textScale = 60,
    c_font      = "morpheus",
    c_textColor = { r = 0.96, g = 0.83, b = 0.37, a = 1 },
    c_bgColor   = { r = 0.16, g = 0.11, b = 0.03, a = 0.92 },
    c_ring      = true,
    c_ringAccent = false,
    c_ringColor = { r = 0.79, g = 0.64, b = 0.24, a = 1 },
    c_ringSize  = 2,
    c_pulse     = false,

    -- Floating letters
    f_count    = 3,
    f_size     = 14,
    f_case     = "mixed",
    f_font     = "morpheus",
    f_outline  = "OUTLINE",
    f_colorMode = "accent",
    f_color    = { r = 0.96, g = 0.83, b = 0.37, a = 1 },
    f_cycle    = 2.4,    -- seconds per rise
    f_rise     = 14,
    f_drift    = 8,
    f_alpha    = 100,

    -- Icon square
    q_size      = 20,
    q_text      = "Z",
    q_textScale = 70,
    q_font      = "morpheus",
    q_textColor = { r = 0.91, g = 0.88, b = 1, a = 1 },
    q_bgColor   = { r = 0.23, g = 0.16, b = 0.42, a = 1 },
    q_borderAccent = false,
    q_borderColor = { r = 0.61, g = 0.53, b = 0.91, a = 1 },
    q_borderSize = 1,
    q_pulse     = true,
    q_pulseAmt  = 12,
}

local WHITE  = "Interface\\Buttons\\WHITE8X8"
local CIRCLE = "Interface\\AddOns\\EllesmereUIUnitFrames\\Media\\circle-mask.png"
local REST_ATLAS = "UI-HUD-UnitFrame-Player-Rest-Flipbook"
local STATE_ICON = "Interface\\CharacterFrame\\UI-StateIcon"

-------------------------------------------------------------------------------
--  Settings
-------------------------------------------------------------------------------
function RS.DB()
    if type(EllesmereUI_RestedStyleDB) ~= "table" then EllesmereUI_RestedStyleDB = {} end
    return EllesmereUI_RestedStyleDB
end

function RS.Get(k)
    local v = RS.DB()[k]
    if v == nil then v = RS.DEFAULTS[k] end
    return v
end

function RS.Set(k, v)
    RS.DB()[k] = v
    RS.Apply()
end

function RS.GetColor(k)
    local c = RS.Get(k) or {}
    return c.r or 1, c.g or 1, c.b or 1, c.a or 1
end

function RS.SetColor(k, r, g, b, a)
    RS.DB()[k] = { r = r, g = g, b = b, a = a or 1 }
    RS.Apply()
end

function RS.Style()
    local s = RS.Get("style")
    return RS.STYLES[s] and s or "blizzard"
end

local function Accent()
    local c = EllesmereUI and EllesmereUI.ELLESMERE_GREEN
    if c then return c.r, c.g, c.b end
    return 0.05, 0.82, 0.62
end

-- Preview: show the indicator even outside a resting area (session only).
RS.preview = false
function RS.SetPreview(v)
    RS.preview = v and true or false
    RS.Sync()
end

-------------------------------------------------------------------------------
--  Helpers
-------------------------------------------------------------------------------
local function ApplyFont(fs, key, size, flags)
    size = math.max(6, math.floor(size + 0.5))
    if flags == "NONE" then flags = "" end
    local f = RS.FONTS[key]
    local path = f and f[2]
    if path and fs:SetFont(path, size, flags or "") then return end
    local I = ns and ns._internals
    if I and I.SetFSFont then
        I.SetFSFont(fs, size, flags)
    else
        fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, flags or "")
    end
end

local function Circle(parent, layer, sub)
    local t = parent:CreateTexture(nil, layer, nil, sub)
    t:SetTexture(WHITE)
    local m = parent:CreateMaskTexture()
    m:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m:SetAllPoints(t)
    t:AddMaskTexture(m)
    return t
end

-- Blizzard's own rest flipbook: read the live PlayerFrame once (atlas + grid),
-- so whatever art this client ships is used exactly as Blizzard plays it.
local blizzInfo
local function ReadBlizzardRest()
    if blizzInfo then return blizzInfo end
    local info = { atlas = REST_ATLAS, rows = 7, cols = 6, frames = 42, duration = 1.5 }
    local c = PlayerFrame and PlayerFrame.PlayerFrameContent
        and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual
    local tex = c and c.PlayerRestLoop
    if tex then
        local a = tex.GetAtlas and tex:GetAtlas()
        if a and a ~= "" then info.atlas = a end
        local w, h = tex:GetSize()
        if w and h and w > 0 and h > 0 then info.ratio = w / h end
        local ag = tex.PlayerRestLoopAnim or (c and c.PlayerRestLoopAnim)
        if ag and ag.GetAnimations then
            for _, anim in ipairs({ ag:GetAnimations() }) do
                if anim.GetObjectType and anim:GetObjectType() == "FlipBook" then
                    info.rows     = anim:GetFlipBookRows() or info.rows
                    info.cols     = anim:GetFlipBookColumns() or info.cols
                    info.frames   = anim:GetFlipBookFrames() or info.frames
                    info.duration = anim:GetDuration() or info.duration
                    break
                end
            end
        end
    end
    local ai = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(info.atlas)
    if ai and ai.width and ai.height and ai.width > 0 then
        info.hasAtlas = true
        if not info.ratio then
            info.ratio = (ai.width / math.max(1, info.cols)) / (ai.height / math.max(1, info.rows))
        end
    else
        info.hasAtlas = false
        info.ratio = 1
    end
    if info.rows < 1 or info.cols < 1 or info.frames < 1 then
        info.rows, info.cols, info.frames = 1, 1, 1
    end
    blizzInfo = info
    return info
end

-------------------------------------------------------------------------------
--  Build (one frame holding every style's layers)
-------------------------------------------------------------------------------
local function Build(parent)
    local F = CreateFrame("Frame", nil, parent)
    F:SetSize(20, 20)
    F:Hide()

    -- Blizzard flipbook
    F.blizz = F:CreateTexture(nil, "OVERLAY")
    F.blizz:SetAllPoints(F)
    F.blizzAG = F.blizz:CreateAnimationGroup()
    F.blizzAG:SetLooping("REPEAT")
    F.blizzFB = F.blizzAG:CreateAnimation("FlipBook")

    -- Classic badge
    F.badgeRing = Circle(F, "ARTWORK", 1)
    F.badgeRing:SetAllPoints(F)
    F.badgeBg = Circle(F, "ARTWORK", 2)
    F.badgeText = F:CreateFontString(nil, "OVERLAY")
    F.badgeText:SetPoint("CENTER", F, "CENTER", 0, 0)

    -- Icon square
    F.sqBorder = F:CreateTexture(nil, "ARTWORK", nil, 1)
    F.sqBorder:SetTexture(WHITE)
    F.sqBorder:SetAllPoints(F)
    F.sqBg = F:CreateTexture(nil, "ARTWORK", nil, 2)
    F.sqBg:SetTexture(WHITE)
    F.sqText = F:CreateFontString(nil, "OVERLAY")
    F.sqText:SetPoint("CENTER", F, "CENTER", 0, 0)

    -- Pulses (alpha for the badge, scale for the square)
    F.pulseAG = F:CreateAnimationGroup()
    F.pulseAG:SetLooping("BOUNCE")
    local pa = F.pulseAG:CreateAnimation("Alpha")
    pa:SetFromAlpha(1); pa:SetToAlpha(0.45); pa:SetDuration(1.1); pa:SetSmoothing("IN_OUT")

    F.scaleHolder = CreateFrame("Frame", nil, F)
    F.scaleHolder:SetAllPoints(F)
    F.scaleAG = F.scaleHolder:CreateAnimationGroup()
    F.scaleAG:SetLooping("BOUNCE")
    F.scaleAnim = F.scaleAG:CreateAnimation("Scale")
    F.scaleAnim:SetOrigin("CENTER", 0, 0)
    F.scaleAnim:SetDuration(1.2)
    F.scaleAnim:SetSmoothing("IN_OUT")
    -- the square's layers live on the scaled holder
    F.sqBorder:SetParent(F.scaleHolder)
    F.sqBg:SetParent(F.scaleHolder)
    F.sqText:SetParent(F.scaleHolder)

    -- Floating letters (OnUpdate driven while shown)
    F.letters = {}
    for i = 1, 5 do
        local fs = F:CreateFontString(nil, "OVERLAY")
        fs:Hide()
        F.letters[i] = fs
    end
    F.t = 0
    return F
end

local function HideAllLayers(F)
    F.blizz:Hide(); F.blizzAG:Stop()
    F.badgeRing:Hide(); F.badgeBg:Hide(); F.badgeText:Hide()
    F.sqBorder:Hide(); F.sqBg:Hide(); F.sqText:Hide()
    F.pulseAG:Stop(); F.scaleAG:Stop()
    F:SetAlpha(1)
    for i = 1, 5 do F.letters[i]:Hide() end
    F:SetScript("OnUpdate", nil)
end

-------------------------------------------------------------------------------
--  Paint per style
-------------------------------------------------------------------------------
local function PaintBlizzard(F)
    local info = ReadBlizzardRest()
    local h = RS.Get("b_size")
    local w = h * (info.ratio or 1)
    F:SetSize(w, h)
    local tex = F.blizz
    F.blizzAG:Stop()
    if info.hasAtlas then
        tex:SetAtlas(info.atlas, false)
        F.blizzFB:SetFlipBookRows(info.rows)
        F.blizzFB:SetFlipBookColumns(info.cols)
        F.blizzFB:SetFlipBookFrames(info.frames)
        F.blizzFB:SetFlipBookFrameWidth(0)
        F.blizzFB:SetFlipBookFrameHeight(0)
        local speed = math.max(10, RS.Get("b_speed")) / 100
        F.blizzFB:SetDuration((info.duration or 1.5) / speed)
    else
        tex:SetTexture(STATE_ICON)
        tex:SetTexCoord(0, 0.5, 0, 0.421875)
    end
    local r, g, b, a = RS.GetColor("b_color")
    tex:SetVertexColor(r, g, b, a)
    tex:SetDesaturated(RS.Get("b_desat") and true or false)
    tex:Show()
    if info.hasAtlas and RS.Get("b_animate") then
        F.blizzAG:Play()
    elseif info.hasAtlas then
        -- static: first frame of the sheet
        local ai = C_Texture.GetAtlasInfo(info.atlas)
        if ai then
            local l, rr = ai.leftTexCoord or 0, ai.rightTexCoord or 1
            local t, bb = ai.topTexCoord or 0, ai.bottomTexCoord or 1
            tex:SetTexCoord(l, l + (rr - l) / info.cols, t, t + (bb - t) / info.rows)
        end
    else
        F.pulseAG:Play()
    end
end

local function PaintBadge(F)
    local size = RS.Get("c_size")
    F:SetSize(size, size)
    local ringOn = RS.Get("c_ring")
    local thick = ringOn and RS.Get("c_ringSize") or 0
    if ringOn then
        if RS.Get("c_ringAccent") then
            local r, g, b = Accent()
            F.badgeRing:SetVertexColor(r, g, b, 1)
        else
            F.badgeRing:SetVertexColor(RS.GetColor("c_ringColor"))
        end
        F.badgeRing:Show()
    end
    F.badgeBg:ClearAllPoints()
    F.badgeBg:SetPoint("TOPLEFT", F, "TOPLEFT", thick, -thick)
    F.badgeBg:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -thick, thick)
    F.badgeBg:SetVertexColor(RS.GetColor("c_bgColor"))
    F.badgeBg:Show()

    local fs = F.badgeText
    ApplyFont(fs, RS.Get("c_font"), size * RS.Get("c_textScale") / 100, "")
    fs:SetText(RS.Get("c_text"))
    fs:SetTextColor(RS.GetColor("c_textColor"))
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 0.8)
    fs:Show()
    if RS.Get("c_pulse") then F.pulseAG:Play() end
end

local function PaintSquare(F)
    local size = RS.Get("q_size")
    F:SetSize(size, size)
    local bs = RS.Get("q_borderSize")
    if bs > 0 then
        if RS.Get("q_borderAccent") then
            local r, g, b = Accent()
            F.sqBorder:SetVertexColor(r, g, b, 1)
        else
            F.sqBorder:SetVertexColor(RS.GetColor("q_borderColor"))
        end
        F.sqBorder:Show()
    end
    F.sqBg:ClearAllPoints()
    F.sqBg:SetPoint("TOPLEFT", F.scaleHolder, "TOPLEFT", bs, -bs)
    F.sqBg:SetPoint("BOTTOMRIGHT", F.scaleHolder, "BOTTOMRIGHT", -bs, bs)
    F.sqBg:SetVertexColor(RS.GetColor("q_bgColor"))
    F.sqBg:Show()

    local fs = F.sqText
    ApplyFont(fs, RS.Get("q_font"), size * RS.Get("q_textScale") / 100, "")
    fs:SetText(RS.Get("q_text"))
    fs:SetTextColor(RS.GetColor("q_textColor"))
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 0.8)
    fs:Show()

    if RS.Get("q_pulse") then
        local s = 1 + RS.Get("q_pulseAmt") / 100
        F.scaleAnim:SetScaleFrom(1, 1)
        F.scaleAnim:SetScaleTo(s, s)
        F.scaleAG:Play()
    end
end

local function FloatColor()
    local mode = RS.Get("f_colorMode")
    if mode == "accent" then
        return Accent()
    elseif mode == "class" then
        local _, cls = UnitClass("player")
        local c = cls and (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(cls)
            or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]))
        if c then return c.r, c.g, c.b end
        return 1, 1, 1
    elseif mode == "gold" then
        return 0.96, 0.83, 0.37
    end
    local r, g, b = RS.GetColor("f_color")
    return r, g, b
end
RS.FloatColor = FloatColor

local function PaintFloat(F)
    local n     = math.max(1, math.min(5, RS.Get("f_count")))
    local size  = RS.Get("f_size")
    local rise  = RS.Get("f_rise")
    local drift = RS.Get("f_drift")
    local case  = RS.Get("f_case")
    local font  = RS.Get("f_font")
    local outl  = RS.Get("f_outline")
    local maxA  = RS.Get("f_alpha") / 100
    local dur   = math.max(0.5, RS.Get("f_cycle"))
    local r, g, b = FloatColor()

    -- the frame is the box the letters start in (keeps anchoring sensible)
    F:SetSize(size, size)
    for i = 1, 5 do
        local fs = F.letters[i]
        if i <= n then
            local frac = (n == 1) and 1 or (0.6 + 0.4 * (i - 1) / (n - 1))
            local ch = "Z"
            if case == "lower" or (case == "mixed" and i < n) then ch = "z" end
            ApplyFont(fs, font, size * frac, outl)
            fs:SetText(ch)
            fs:SetTextColor(r, g, b, 1)
            if outl == "NONE" then
                fs:SetShadowOffset(1, -1); fs:SetShadowColor(0, 0, 0, 0.9)
            else
                fs:SetShadowOffset(0, 0)
            end
            fs:SetAlpha(0)
            fs:Show()
        else
            fs:Hide()
        end
    end

    F.t = 0
    F:SetScript("OnUpdate", function(self, elapsed)
        self.t = (self.t + elapsed) % dur
        for i = 1, n do
            local fs = self.letters[i]
            local p = (self.t / dur + (i - 1) / n) % 1
            local a
            if p < 0.2 then a = p / 0.2
            elseif p > 0.7 then a = (1 - p) / 0.3
            else a = 1 end
            fs:SetAlpha(a * maxA)
            fs:ClearAllPoints()
            fs:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", p * drift, p * rise)
        end
    end)
end

-------------------------------------------------------------------------------
--  Runtime: hook EUI's FontString
-------------------------------------------------------------------------------
local pf, euiFS, F, hooked

local function AnchorTarget()
    if not pf then return nil end
    if RS.Get("anchorTo") == "frame" then return pf end
    return pf.Health or pf
end

local function Anchor()
    if not (F and pf) then return end
    local a = RS.ANCHORS[RS.Get("anchor")] or RS.ANCHORS.inside_tl
    local rx = (EllesmereUIDB and EllesmereUIDB.restedIndicatorXOffset) or 0
    local ry = (EllesmereUIDB and EllesmereUIDB.restedIndicatorYOffset) or 0
    -- EUI's own base inset (3, -2) applies to the inside-top-left corner only
    local bx, by = 0, 0
    if a[1] == "TOPLEFT" and a[2] == "TOPLEFT" then bx, by = 3, -2 end
    F:ClearAllPoints()
    F:SetPoint(a[1], AnchorTarget(), a[2], bx + rx, by + ry)
end

local syncing = false
function RS.Sync()
    if syncing or not (F and euiFS) then return end
    local style = RS.Style()
    if style == "eui" then
        syncing = true
        euiFS:SetAlpha(1)
        F:Hide()
        local enabled = EllesmereUIDB and EllesmereUIDB.showRestedIndicator == true
        local want = enabled and (IsResting() or RS.preview)
        if want and not euiFS:IsShown() then euiFS:Show()
        elseif not want and euiFS:IsShown() then euiFS:Hide() end
        syncing = false
        return
    end
    euiFS:SetAlpha(0)
    if pf then F:SetFrameLevel(math.max(pf:GetFrameLevel() + 25, F:GetFrameLevel())) end
    local enabled = EllesmereUIDB and EllesmereUIDB.showRestedIndicator == true
    local show = euiFS:IsShown() or (RS.preview and enabled)
    F:SetShown(show and true or false)
end

function RS.Apply()
    if not F then return end
    HideAllLayers(F)
    local style = RS.Style()
    if style == "blizzard" then PaintBlizzard(F)
    elseif style == "badge" then PaintBadge(F)
    elseif style == "float" then PaintFloat(F)
    elseif style == "square" then PaintSquare(F)
    end
    Anchor()
    RS.Sync()
end

local function Install()
    if hooked then return true end
    local p = _G["EllesmereUIUnitFrames_Player"]
    local fs = p and p._restIndicator
    if not (fs and p._restHolder) then return false end
    pf, euiFS = p, fs
    hooked = true

    -- Parented to the player frame itself: pf.Health lives in EUI's bar clip
    -- (SetClipsChildren), which would cut off any anchor outside the bars,
    -- and the portrait backdrop sits at frame level +15.
    F = Build(p)
    F:SetFrameStrata(p:GetFrameStrata())
    F:SetFrameLevel(math.max(p:GetFrameLevel() + 25, p._restHolder:GetFrameLevel() + 2))

    hooksecurefunc(fs, "Show", RS.Sync)
    hooksecurefunc(fs, "Hide", RS.Sync)
    if fs.SetShown then hooksecurefunc(fs, "SetShown", RS.Sync) end
    hooksecurefunc(fs, "SetPoint", Anchor)

    if EllesmereUI and EllesmereUI.RegAccent then
        EllesmereUI.RegAccent({ type = "callback", fn = function()
            local s = RS.Style()
            if s == "float" or (s == "badge" and RS.Get("c_ringAccent"))
                or (s == "square" and RS.Get("q_borderAccent")) then
                RS.Apply()
            end
        end })
    end

    RS.Apply()
    return true
end
RS.Install = Install

local tries = 0
local function TryInstall()
    if Install() then return end
    tries = tries + 1
    if tries < 30 then C_Timer.After(1, TryInstall) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        RS.DB()
        TryInstall()
    elseif hooked then
        RS.Sync()
    else
        TryInstall()
    end
end)

SLASH_EUIRESTED1 = "/eurest"
SlashCmdList.EUIRESTED = function(msg)
    msg = (msg or ""):lower()
    if msg == "preview" or msg == "" then
        RS.SetPreview(not RS.preview)
        print("|cff0cd29fRested Style|r preview " .. (RS.preview and "on" or "off"))
    elseif msg == "debug" then
        local p = "|cff0cd29fRested Style|r "
        print(p .. "hooked=" .. tostring(hooked) .. " style=" .. RS.Style() .. " preview=" .. tostring(RS.preview)
            .. " resting=" .. tostring(IsResting()) .. " enabled=" .. tostring(EllesmereUIDB and EllesmereUIDB.showRestedIndicator))
        if euiFS then print(p .. "euiFS shown=" .. tostring(euiFS:IsShown()) .. " visible=" .. tostring(euiFS:IsVisible())) end
        if F then
            local w, h = F:GetSize()
            print(p .. "icon shown=" .. tostring(F:IsShown()) .. " visible=" .. tostring(F:IsVisible())
                .. (" size=%.0fx%.0f"):format(w or 0, h or 0) .. " alpha=" .. tostring(F:GetEffectiveAlpha())
                .. " level=" .. tostring(F:GetFrameLevel()) .. " strata=" .. tostring(F:GetFrameStrata()))
            local l, b = F:GetLeft(), F:GetBottom()
            print(p .. "pos left=" .. tostring(l and math.floor(l)) .. " bottom=" .. tostring(b and math.floor(b)))
            print(p .. "blizz tex shown=" .. tostring(F.blizz:IsShown()) .. " atlas=" .. tostring(F.blizz:GetAtlas())
                .. " texture=" .. tostring(F.blizz:GetTexture()))
        end
        if pf and pf._restHolder then
            print(p .. "holder visible=" .. tostring(pf._restHolder:IsVisible()))
        end
        local i = ReadBlizzardRest()
        print(p .. "flipbook atlas=" .. tostring(i.atlas) .. " hasAtlas=" .. tostring(i.hasAtlas)
            .. (" grid=%dx%d frames=%d ratio=%.2f"):format(i.rows, i.cols, i.frames, i.ratio or 0))
    elseif msg == "reset" then
        EllesmereUI_RestedStyleDB = {}
        RS.Apply()
        print("|cff0cd29fRested Style|r settings reset")
    end
end
