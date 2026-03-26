--[[
+====================================================================+
|       [*]  A M E T H Y S T   U L T I M A T E   V 3 . 0  [*]      |
|       Professional-Grade Universal Mod Menu                        |
+====================================================================+
|   TABS:                                                            |
|   1. Home        - Quick toggles, info, one-click presets          |
|   2. Combat      - Aimbot, Aimlock, FOV, Silent Aim, Hitbox       |
|   3. Visuals     - ESP Box/Name/Tracers/Skeleton, Radar, HUD      |
|   4. Gameplay    - Movement, Weapon, Fly, Noclip, Mobile Tools    |
|   5. Performance - Omega FPS, Lighting, Texture/Particle Purge    |
|   6. Server      - Find Smallest, Hop, Rejoin, Anti-AFK           |
|   7. Credits     - Info, Version, Branding                         |
+====================================================================+
|   FEATURES:                                                        |
|   - Deep Amethyst Purple theme with TweenService animations       |
|   - Custom drag system for 100% mobile/PC compatibility            |
|   - Every toggle fires Rayfield notification (3s)                  |
|   - Omega AntiLag engine (smart lava/kill/damage filter)           |
|   - Box ESP + Tracers with Amethyst outlines                       |
|   - Aimbot + Aimlock using Camera.CFrame + ClosestPlayer           |
|   - Jump Button resizer slider (1x-3x) for mobile                 |
|   - Persistent watermark with GothamBold pulse animation           |
|   - All errors via xpcall + debug.traceback [Amethyst Error]      |
+====================================================================+
]]

-- ============================================================
-- DOUBLE EXECUTION GUARD + PREVIOUS INSTANCE CLEANUP
-- ============================================================
if _G.__AmethystCleanup then
    pcall(_G.__AmethystCleanup)
end
if _G.__AmethystUltimateV3 then
    warn("[Amethyst V3] Already running.")
    return
end
_G.__AmethystUltimateV3 = true

-- ============================================================
-- ROBUST ERROR HANDLER (xpcall + debug.traceback)
-- ============================================================
-- All runtime operations are routed through _safeCall for unified
-- error logging. Errors are printed to console in the format:
--     [Amethyst Error]: <message>
--     <full stack trace>
-- This replaces basic pcall() with xpcall() + debug.traceback().
-- ============================================================

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local CoreGui          = game:GetService("CoreGui")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
-- CENTRAL CONFIG (_G.Config) — FIX 25
-- ============================================================
_G.Config = {
    Version            = "3.0.0",
    ESPThrottle        = 1/60,       -- ~16ms, max 60 FPS (FIX 11)
    SkeletonThrottle   = 1/30,       -- ~33ms, max 30 FPS
    AimRefreshInterval = 0.15,       -- Target refresh rate
    KillAuraCooldown   = 0.2,        -- FIX 7
    WeaponScanInterval = 0.2,        -- FIX 12
    AimPredictVelMin   = 5,          -- FIX 8: minimum velocity for prediction
    AimHumanization    = 0.5,        -- Section 4: randomization (studs)
    AutoHopInterval    = 15,
    AntiAFKInterval    = 55,
    CacheBuildDelay    = 0.5,        -- Delay before building bone cache
}

-- ============================================================
-- CONNECTION TRACKING SYSTEM — FIX 15
-- ============================================================
local _connections = {}

local function track(conn)
    _connections[#_connections + 1] = conn
    return conn
end

local function cleanupAll()
    for _, c in ipairs(_connections) do
        _safeCall(function() c:Disconnect() end)
    end
    _connections = {}
end

-- ============================================================
-- THEME CONSTANTS (Deep Amethyst Purple)
-- ============================================================
local THEME = {
    Background   = Color3.fromRGB(35, 10, 50),
    Main         = Color3.fromRGB(50, 20, 70),
    Accent       = Color3.fromRGB(180, 100, 255),
    AccentSoft   = Color3.fromRGB(140, 80, 210),
    AccentDim    = Color3.fromRGB(100, 50, 160),
    AccentBright = Color3.fromRGB(220, 160, 255),
    AccentGlow   = Color3.fromRGB(200, 140, 255),
    DeepPurple   = Color3.fromRGB(80, 30, 120),
    RoyalPurple  = Color3.fromRGB(120, 50, 180),
    NeonPurple   = Color3.fromRGB(220, 160, 255),
    DarkAmethyst = Color3.fromRGB(25, 5, 40),
    CrystalWhite = Color3.fromRGB(240, 230, 255),
    Shadow       = Color3.fromRGB(25, 5, 35),
    TextPrimary  = Color3.fromRGB(240, 235, 255),
    TextSecondary = Color3.fromRGB(180, 160, 210),
    Lavender     = Color3.fromRGB(200, 180, 240),
    ESPColor     = Color3.fromRGB(180, 100, 255),
    ESPTracer    = Color3.fromRGB(153, 85, 217),
    HealthGreen  = Color3.fromRGB(100, 255, 100),
    HealthRed    = Color3.fromRGB(255, 60, 60),
    AlertRed     = Color3.fromRGB(255, 40, 40),
    White        = Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- TWEEN PRESETS (liquid-like smooth animations)
-- ============================================================
local TI_SMOOTH = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_FAST   = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_PULSE  = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local TI_BOUNCE = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function tweenProp(obj, props, tweenInfo)
    _safeCall(function()
        TweenService:Create(obj, tweenInfo or TI_SMOOTH, props):Play()
    end)
end

-- ============================================================
-- DRAWING LIBRARY POLYFILL (executor compatibility)
-- ============================================================
do
    local _drawOk = false
    _safeCall(function()
        local _t = Drawing.new("Line")
        if _t then _t:Remove(); _drawOk = true end
    end)
    if not _drawOk then
        local _noop = function() end
        local _DummyMT = {
            __newindex = function(self, k, v) rawset(self, k, v) end,
            __index = function(_, k)
                if k == "Remove" or k == "Destroy" then return _noop end
                return nil
            end,
        }
        local function _makeDummy()
            return setmetatable({
                Visible = false, Color = Color3.new(1,1,1), Thickness = 1,
                Filled = false, Transparency = 1, NumSides = 64,
                Position = Vector2.new(0,0), Size = Vector2.new(0,0),
                From = Vector2.new(0,0), To = Vector2.new(0,0),
                Radius = 0, Text = "", Outline = false, Center = false,
                TextSize = 14, Font = 0,
            }, _DummyMT)
        end
        _safeCall(function() Drawing = { new = function() return _makeDummy() end } end)
        if not Drawing then
            rawset(_G, "Drawing", { new = function() return _makeDummy() end })
        end
        warn("[Amethyst V3] Drawing library not available - visual overlays will be no-ops")
    end
end

-- ============================================================
-- MOBILE DETECTION
-- ============================================================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
-- RAYFIELD (multi-URL + HTTP fallback)
-- ============================================================
local Rayfield
do
    local _rfUrls = {
        "https://sirius.menu/rayfield",
        "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
    }
    for _, _rfUrl in ipairs(_rfUrls) do
        if Rayfield then break end
        _safeCall(function()
            local _src
            _safeCall(function() _src = game:HttpGet(_rfUrl) end)
            if not _src or #_src < 200 then
                _safeCall(function()
                    local _fn = request or http_request or (syn and syn.request) or (http and http.request)
                    if _fn then
                        local _r = _fn({Url = _rfUrl, Method = "GET"})
                        if _r and _r.Body then _src = _r.Body end
                    end
                end)
            end
            if _src and #_src > 200 then
                Rayfield = loadstring(_src)()
            end
        end)
    end
end
if not Rayfield then
    warn("[Amethyst V3] Rayfield failed to load from all sources.")
    _G.__AmethystUltimateV3 = nil
    return
end

-- ============================================================
-- AMETHYST RAYFIELD THEME (Deep Amethyst Purple)
-- ============================================================
local AmethystTheme = {
    Background                    = THEME.Background,
    Topbar                        = THEME.Main,
    Shadow                        = THEME.Shadow,
    NotificationBackground        = Color3.fromRGB(45, 15, 65),
    NotificationActionsBackground = Color3.fromRGB(55, 25, 75),
    TabBackground                 = Color3.fromRGB(45, 15, 65),
    TabStroke                     = Color3.fromRGB(80, 40, 120),
    TabBackgroundSelected         = Color3.fromRGB(65, 30, 95),
    TabStrokeSelected             = THEME.Accent,
    ElementBackground             = Color3.fromRGB(55, 25, 75),
    ElementBackgroundHover        = Color3.fromRGB(65, 35, 90),
    SecondaryElementBackground    = THEME.Main,
    ElementStroke                 = Color3.fromRGB(80, 40, 120),
    SliderBackground              = THEME.Background,
    SliderProgress                = THEME.Accent,
    SliderStroke                  = Color3.fromRGB(120, 60, 180),
    ToggleBackground              = Color3.fromRGB(55, 25, 75),
    ToggleEnabled                 = THEME.Accent,
    ToggleDisabled                = Color3.fromRGB(80, 40, 100),
    ToggleEnabledStroke           = Color3.fromRGB(200, 130, 255),
    ToggleDisabledStroke          = Color3.fromRGB(70, 35, 90),
    ToggleEnabledOuterStroke      = Color3.fromRGB(150, 80, 220),
    ToggleDisabledOuterStroke     = Color3.fromRGB(55, 25, 75),
    DropdownSelected              = Color3.fromRGB(65, 30, 95),
    DropdownUnselected            = Color3.fromRGB(45, 15, 65),
    InputBackground               = Color3.fromRGB(45, 15, 65),
    InputStroke                   = Color3.fromRGB(80, 40, 120),
    PlaceholderColor              = Color3.fromRGB(140, 100, 170),
    TextColor                     = THEME.TextPrimary,
    SecondaryTextColor            = THEME.TextSecondary,
}

-- ============================================================
-- WINDOW (pcall-wrapped with fallback)
-- ============================================================
local Window
local _winOk = _safeCall(function()
    Window = Rayfield:CreateWindow({
        Name            = "  Amethyst  |  Universal  ",
        LoadingTitle    = "A M E T H Y S T",
        LoadingSubtitle = "Ultimate V3.0 | by Lutfie kenape ek",
        Theme           = "Amethyst",
        ConfigurationSaving = {
            Enabled    = true,
            FolderName = "AmethystUltimateV3",
            FileName   = "Config_v3"
        },
        KeySystem = false,
    })
end)
if not _winOk or not Window then
    _safeCall(function()
        Window = Rayfield:CreateWindow({
            Name            = "  Amethyst  |  Universal  ",
            LoadingTitle    = "A M E T H Y S T",
            LoadingSubtitle = "Ultimate V3.0 | Loading...",
            Theme           = "Amethyst",
            ConfigurationSaving = {
                Enabled    = true,
                FolderName = "AmethystUltimateV3",
                FileName   = "Config_v3"
            },
            KeySystem = false,
        })
    end)
end
if not Window then
    warn("[Amethyst V3] Failed to create window.")
    _G.__AmethystUltimateV3 = nil
    return
end

-- ============================================================
-- UI DUPLICATION PREVENTION (FIX 26)
-- ============================================================
_safeCall(function()
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui.Name == "AmethystWatermarkV3" or gui.Name == "AmethystToggleV3" then
            gui:Destroy()
        end
    end
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            if gui.Name == "AmethystWatermarkV3" or gui.Name == "AmethystToggleV3" then
                gui:Destroy()
            end
        end
    end
end)

-- ============================================================
-- PERSISTENT WATERMARK (FIX 1: single wmGlow, FIX 14: TweenService pulse)
-- ============================================================
local _wmGui
_safeCall(function()
    _wmGui = Instance.new("ScreenGui")
    _wmGui.Name = "AmethystWatermarkV3"
    _wmGui.ResetOnSpawn = false
    _wmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _wmGui.DisplayOrder = 999
    _wmGui.IgnoreGuiInset = true
    local pOk = _safeCall(function() _wmGui.Parent = CoreGui end)
    if not pOk then
        _safeCall(function() _wmGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
    end

    -- Background pill
    local wmBg = Instance.new("Frame")
    wmBg.Size = UDim2.new(0, 180, 0, 34)
    wmBg.Position = UDim2.new(1, -190, 1, -44)
    wmBg.BackgroundColor3 = Color3.fromRGB(20, 8, 30)
    wmBg.BackgroundTransparency = 0.3
    wmBg.BorderSizePixel = 0
    wmBg.Parent = _wmGui

    local wmCorner = Instance.new("UICorner")
    wmCorner.CornerRadius = UDim.new(0, 8)
    wmCorner.Parent = wmBg

    local wmStroke = Instance.new("UIStroke")
    wmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual  -- Premium contextual glow
    wmStroke.Color = THEME.AccentDim
    wmStroke.Thickness = 1.5
    wmStroke.Transparency = 0.4
    wmStroke.Parent = wmBg

    -- Glow frame behind watermark (FIX 1: ONE instance only)
    local wmGlow = Instance.new("Frame")
    wmGlow.Size = UDim2.new(1, 12, 1, 12)
    wmGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    wmGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    wmGlow.BackgroundColor3 = THEME.Accent
    wmGlow.BackgroundTransparency = 0.9
    wmGlow.BorderSizePixel = 0
    wmGlow.ZIndex = 9999
    wmGlow.Parent = wmBg
    local wmGlowCorner = Instance.new("UICorner")
    wmGlowCorner.CornerRadius = UDim.new(0, 10)
    wmGlowCorner.Parent = wmGlow

    -- FIX 14: TweenService looping pulse (replaces manual while loop)
    TweenService:Create(wmGlow, TI_PULSE, {BackgroundTransparency = 0.7}):Play()

    -- Amethyst gradient on watermark background
    local wmGrad = Instance.new("UIGradient")
    wmGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 8, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 18, 65)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 8, 40)),
    })
    wmGrad.Rotation = 0
    wmGrad.Parent = wmBg

    -- FIX 9/14: Gradient rotation via TweenService (replaces while loop)
    TweenService:Create(wmGrad,
        TweenInfo.new(18, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        {Rotation = 360}
    ):Play()

    -- Accent bar (left side)
    local wmAccent = Instance.new("Frame")
    wmAccent.Name = "Accent"
    wmAccent.Size = UDim2.new(0, 3, 0.6, 0)
    wmAccent.Position = UDim2.new(0, 8, 0.2, 0)
    wmAccent.BackgroundColor3 = THEME.Accent
    wmAccent.BorderSizePixel = 0
    wmAccent.Parent = wmBg
    local acCorner = Instance.new("UICorner")
    acCorner.CornerRadius = UDim.new(0, 2)
    acCorner.Parent = wmAccent

    -- Main text
    local wmText = Instance.new("TextLabel")
    wmText.Size = UDim2.new(1, -20, 1, 0)
    wmText.Position = UDim2.new(0, 18, 0, 0)
    wmText.BackgroundTransparency = 1
    wmText.Text = "Amethyst | Lutfie kenape ek"
    wmText.TextColor3 = THEME.Lavender
    wmText.TextTransparency = 0.15
    wmText.TextSize = 15
    wmText.Font = Enum.Font.GothamBold
    wmText.TextXAlignment = Enum.TextXAlignment.Left
    wmText.Parent = wmBg

    -- Premium Amethyst UIStroke on watermark text (contextual breathing glow)
    -- Creates a soft glowing outline that oscillates for premium visual impact
    local wmTextStroke = Instance.new("UIStroke")
    wmTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    wmTextStroke.Color = THEME.Accent
    wmTextStroke.Thickness = 1.2
    wmTextStroke.Transparency = 0.5
    wmTextStroke.Parent = wmText

    -- Breathing animation: transparency oscillates 0.5 → 0.1 → 0.5 (infinite)
    TweenService:Create(wmTextStroke, TI_PULSE, {Transparency = 0.1}):Play()

    -- Pulse animation on accent bar (TweenService)
    tweenProp(wmAccent, {BackgroundTransparency = 0.5}, TI_PULSE)

    -- FIX 14: Stroke + text pulse via TweenService (replaces manual while loop)
    wmStroke.Color = Color3.fromRGB(60, 25, 110)
    -- Breathing glow: color + transparency oscillation for premium visual impact
    TweenService:Create(wmStroke, TI_PULSE, {
        Color = Color3.fromRGB(140, 75, 210),
        Transparency = 0.1  -- breathes 0.4 → 0.1 → 0.4 (smooth oscillation)
    }):Play()
    wmText.TextTransparency = 0.1
    TweenService:Create(wmText, TI_PULSE, {TextTransparency = 0.25}):Play()
end)

-- ============================================================
-- ORGANIZED STATE TABLE — FIX 22, 23, 26
-- ============================================================
local S = {
    -- FIX 23: Split into categories
    Combat = {
        Aimbot        = false,
        AimbotSmooth  = 3,
        AimPart       = "Head",
        AimPredict    = false,
        AimPredictStr = 0.12,
        FOV_Show      = false,
        FOV_Lock      = false,
        FOV_Radius    = 120,
        SilentAim     = false,
        TriggerBot    = false,
        KillAura      = false,
        KillAuraRange = 25,
        Hitbox        = false,
        HitboxScale   = 2,
        NoRecoil      = false,
        NoSpread      = false,
        FastReload    = false,
        InfAmmo       = false,
    },
    Visuals = {
        Wallhack      = false,
        ESP_Box       = false,
        ESP_Name      = false,
        ESP_Health    = false,
        ESP_Skeleton  = false,
        ESP_Tracer    = false,
        ESP_Distance  = false,
        VisCheck      = false,
        ESPColor      = Color3.fromRGB(180, 100, 255),
        Crosshair     = false,
        XH_Size       = 8,
        XH_Gap        = 4,
        Fullbright    = false,
        EnemyAlert    = false,
        EnemyAlertDist = 40,
        Radar         = false,
        RadarRange    = 120,
        RadarSize     = 130,
        PlayerBotHUD  = false,
        KillCounter   = false,
    },
    Movement = {
        Speed      = false,
        SpeedVal   = 16,
        Jump       = false,
        JumpVal    = 50,
        AutoStrafe = false,
        InfJump    = false,
        NoFallDmg  = false,
        FastRespawn = false,
        JumpScale  = 1,
        Fly        = false,
        FlySpeed   = 50,
        Noclip     = false,
    },
    Utility = {
        GodMode       = false,
        FPSBoost      = false,
        LightingUltra = false,
        TexturePurge  = false,
        ParticlePurge = false,
        TerrainSimple = false,
        AntiAFK       = false,
        AutoHop       = false,
        AutoHopMax    = 6,
        ServerList    = {},
        TargetPlaceId = game.PlaceId,
        SilentMode    = false, -- FIX 26: Silent Mode
    },
}

-- Proxy metatable for flat access (S.Aimbot -> S.Combat.Aimbot)
-- Preserves all existing S.Key references without changes
do
    local _subs = {S.Combat, S.Visuals, S.Movement, S.Utility}
    setmetatable(S, {
        __index = function(_, k)
            for _, sub in ipairs(_subs) do
                if rawget(sub, k) ~= nil then return sub[k] end
            end
        end,
        __newindex = function(_, k, v)
            for _, sub in ipairs(_subs) do
                if rawget(sub, k) ~= nil then sub[k] = v; return end
            end
            rawset(S, k, v)
        end,
    })
end

-- ============================================================
-- NOTIFICATION HELPER (FIX 26: Silent Mode support)
-- ============================================================
local function notify(title, content, dur)
    if S.SilentMode then return end
    _safeCall(function()
        Rayfield:Notify({
            Title    = title or "",
            Content  = content or "",
            Duration = dur or 3,
            Image    = "diamond",
        })
    end)
end

-- Toggle notification shorthand (fires on every toggle)
local function notifyToggle(name, state)
    notify(
        name .. (state and " ON" or " OFF"),
        state and "Enabled" or "Disabled",
        3
    )
end

-- FIX 26: Toggle debounce system
local _toggleDebounce = {}
local function debounced(name, callback)
    return function(v)
        local now = tick()
        if _toggleDebounce[name] and now - _toggleDebounce[name] < 0.3 then return end
        _toggleDebounce[name] = now
        callback(v)
    end
end

-- ============================================================
-- SAFE HTTP GET (multi-executor)
-- ============================================================
local function safeHttpGet(url)
    local ok, res = _safeCall(function() return game:HttpGet(url) end)
    if ok and res and res ~= "" then return res end
    ok, res = _safeCall(function()
        if request then return request({Url = url, Method = "GET"}).Body end
    end)
    if ok and res and res ~= "" then return res end
    ok, res = _safeCall(function()
        if http_request then return http_request({Url = url, Method = "GET"}).Body end
    end)
    if ok and res and res ~= "" then return res end
    return nil
end

-- ============================================================
-- MODULAR EXTERNAL FETCHING (loadstring-based component loader)
-- ============================================================
-- Large subsystems (CombatLogic, VisualLibrary, MovementKit) can be
-- hosted externally and loaded at runtime via loadstring(HttpGet(...)).
-- This keeps the main script lean and allows independent module updates.
--
-- USAGE:
--   _ModuleURLs.CombatLogic = "https://your-host.com/amethyst/combat.lua"
--   local Combat = loadExternalModule("CombatLogic")
--   if Combat then Combat.init(S, PartCache) end
--
-- Module contract: each module returns a table with callable methods.
-- ============================================================
local _ModuleURLs = {
    CombatLogic   = nil,  -- URL to external combat module (nil = use built-in)
    VisualLibrary = nil,  -- URL to external visual module (nil = use built-in)
    MovementKit   = nil,  -- URL to external movement module (nil = use built-in)
}

local _LoadedModules = {}

--- Loads and caches an external module by name.
--- Falls through to built-in logic when URL is nil.
--- @param name string  Key from _ModuleURLs table
--- @return table|nil   Module table, or nil if URL not set / load failed
local function loadExternalModule(name)
    if _LoadedModules[name] then return _LoadedModules[name] end
    local url = _ModuleURLs[name]
    if not url then return nil end  -- No URL configured → fall through to built-in
    local src = safeHttpGet(url)
    if not src or src == "" then
        warn("[Amethyst Error]: Failed to fetch module \'" .. tostring(name) .. "\'")
        return nil
    end
    local ok, mod = xpcall(function()
        return loadstring(src)()
    end, function(err)
        warn("[Amethyst Error]: Module \'" .. name .. "\' load failed: "
            .. tostring(err) .. "\n" .. debug.traceback())
    end)
    if ok and mod then
        _LoadedModules[name] = mod
        return mod
    end
    return nil
end

-- ============================================================
-- BONE DEFINITIONS (Skeleton ESP)
-- ============================================================
local BONES_R6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"},  {"Torso","Right Arm"},
    {"Torso","Left Leg"},  {"Torso","Right Leg"},
}
local BONES_R15 = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},  {"LeftUpperArm","LeftLowerArm"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"},
    {"LowerTorso","LeftUpperLeg"},  {"LeftUpperLeg","LeftLowerLeg"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"},
}
local MAX_BONES = #BONES_R15

-- ============================================================
-- PART CACHE (zero FindFirstChild in render loop)
-- ============================================================
local PartCache = {}

local function buildPartCache(player)
    local char = player.Character
    if not char then PartCache[player] = nil return end
    local hum   = char:FindFirstChildOfClass("Humanoid")
    local head  = char:FindFirstChild("Head")
    local root  = char:FindFirstChild("HumanoidRootPart")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not hum or not head or not root then PartCache[player] = nil return end

    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    local defs  = isR15 and BONES_R15 or BONES_R6
    local bp    = {}
    for _, pair in ipairs(defs) do
        bp[#bp + 1] = { char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2]) }
    end

    PartCache[player] = {
        hum = hum, head = head, root = root,
        torso = torso or root,
        boneParts = bp, numBones = #bp,
    }
end

-- ============================================================
-- HITBOX SYSTEM
-- ============================================================
local headOrigSizes = {}

local function applyHitbox(player)
    local pc = PartCache[player]
    if not pc or not pc.head then return end
    if S.Hitbox then
        if not headOrigSizes[player] then
            headOrigSizes[player] = pc.head.Size
        end
        local orig = headOrigSizes[player]
        if orig then
            _safeCall(function()
                pc.head.Size = orig * S.HitboxScale
                pc.head.Transparency = 0.85
                pc.head.CanCollide = false
            end)
        end
    else
        if headOrigSizes[player] then
            _safeCall(function()
                pc.head.Size = headOrigSizes[player]
                pc.head.Transparency = 0
                pc.head.CanCollide = true
            end)
            headOrigSizes[player] = nil
        end
    end
end

local function applyAllHitboxes()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then applyHitbox(p) end
    end
end

-- ============================================================
-- SMART PART FILTER (protects lava/kill/damage bricks)
-- ============================================================
local DANGER_WORDS = {
    "damagebrick","lava","kill","killbrick","killpart",
    "damage","deathbrick","acid","poison","fire","hazard"
}

local function isDangerPart(part)
    if not part or not part:IsA("BasePart") then return false end
    local ln = string.lower(part.Name)
    for _, w in ipairs(DANGER_WORDS) do
        if string.find(ln, w) then return true end
    end
    local c = part.Color
    if c.R > 0.7 and c.G < 0.3 and c.B < 0.3 then return true end
    if c.R > 0.8 and c.G > 0.3 and c.G < 0.6 and c.B < 0.2 then return true end
    return false
end

-- ============================================================
-- OMEGA ANTILAG ENGINE (FPS Boost with smart filter)
-- ============================================================
local matProcessed = {}
local fpsBoostConn = nil

local function simplifyPart(part)
    if not part:IsA("BasePart") then return end
    if matProcessed[part] then return end
    if isDangerPart(part) then return end
    _safeCall(function()
        part.Material = Enum.Material.SmoothPlastic
        part.Reflectance = 0
        part.CastShadow = false
    end)
    matProcessed[part] = true
end

local function runOmegaFPS()
    local count = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if S.FPSBoost then
            _safeCall(function()
                simplifyPart(d)
                count = count + 1
            end)
        end
    end
    return count
end

local function enableFPSListener()
    if fpsBoostConn then return end
    fpsBoostConn = workspace.DescendantAdded:Connect(function(d)
        if S.FPSBoost and d:IsA("BasePart") then
            task.defer(function() _safeCall(function() simplifyPart(d) end) end)
        end
    end)
end

local function disableFPSListener()
    if fpsBoostConn then fpsBoostConn:Disconnect() fpsBoostConn = nil end
end

-- ============================================================
-- LIGHTING ULTRA
-- ============================================================
local savedLighting = {}
_safeCall(function()
    savedLighting = {
        GS = Lighting.GlobalShadows,
        BR = Lighting.Brightness,
        FE = Lighting.FogEnd,
        FS = Lighting.FogStart,
        AM = Lighting.Ambient,
        OA = Lighting.OutdoorAmbient,
        CT = Lighting.ClockTime,
    }
end)

local function applyLightingUltra()
    _safeCall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
        Lighting.Brightness = 1.5
        Lighting.Ambient = Color3.fromRGB(160, 160, 160)
        Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
        Lighting.ClockTime = 12
        _safeCall(function() Lighting.Technology = Enum.Technology.Compatibility end)
        for _, fx in ipairs(Lighting:GetDescendants()) do
            _safeCall(function()
                if fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
                   or fx:IsA("SunRaysEffect") or fx:IsA("DepthOfFieldEffect") then
                    fx.Enabled = false
                end
                if fx:IsA("Atmosphere") then
                    fx.Density = 0; fx.Glare = 0; fx.Haze = 0
                end
            end)
        end
    end)
end

local function restoreLighting()
    _safeCall(function()
        Lighting.GlobalShadows = savedLighting.GS or true
        Lighting.Brightness = savedLighting.BR or 1
        Lighting.FogEnd = savedLighting.FE or 10000
        Lighting.FogStart = savedLighting.FS or 0
        Lighting.Ambient = savedLighting.AM or Color3.new(0, 0, 0)
        Lighting.OutdoorAmbient = savedLighting.OA or Color3.fromRGB(128, 128, 128)
        Lighting.ClockTime = savedLighting.CT or 14
        for _, fx in ipairs(Lighting:GetDescendants()) do
            _safeCall(function()
                if fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
                   or fx:IsA("SunRaysEffect") or fx:IsA("DepthOfFieldEffect") then
                    fx.Enabled = true
                end
            end)
        end
    end)
end

-- ============================================================
-- TEXTURE PURGE
-- ============================================================
local texPurgeConn = nil

local function purgeTextures()
    local n = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        _safeCall(function()
            if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1; n = n + 1 end
        end)
    end
    for _, c in ipairs(Lighting:GetChildren()) do
        _safeCall(function() if c:IsA("Sky") then c:Destroy(); n = n + 1 end end)
    end
    return n
end

local function enableTexListener()
    if texPurgeConn then return end
    texPurgeConn = workspace.DescendantAdded:Connect(function(d)
        if S.TexturePurge then
            task.defer(function()
                _safeCall(function()
                    if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1 end
                end)
            end)
        end
    end)
end

local function disableTexListener()
    if texPurgeConn then texPurgeConn:Disconnect() texPurgeConn = nil end
end

-- ============================================================
-- PARTICLE PURGE + TERRAIN
-- ============================================================
local function purgeParticles()
    local n = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        _safeCall(function()
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
               or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                d.Enabled = false; n = n + 1
            end
        end)
    end
    return n
end

local function simplifyTerrain()
    _safeCall(function()
        local t = workspace.Terrain
        t.WaterWaveSize = 0; t.WaterWaveSpeed = 0
        t.WaterReflectance = 0; t.WaterTransparency = 0
        t.Decoration = false
    end)
end

-- ============================================================
-- FULLBRIGHT
-- ============================================================
local function applyFullbright(on)
    _safeCall(function()
        if on then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        else
            restoreLighting()
        end
    end)
end

-- ============================================================
-- ESP POOL (Amethyst-colored Box ESP + Tracers)
-- ============================================================
local ESPPool = {}

local function makeHighlight(char)
    local hl = Instance.new("Highlight")
    hl.Name = "AmethystHL"
    hl.FillColor = THEME.ESPColor
    hl.OutlineColor = THEME.White
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = S.Wallhack
    hl.Parent = char
    return hl
end

local function createESP(player)
    if ESPPool[player] or player == LocalPlayer then return end
    local c = THEME.ESPColor

    -- Box (Amethyst outline)
    local box = Drawing.new("Square")
    box.Visible = false; box.Color = c; box.Thickness = 1.4; box.Filled = false

    -- Tracer (dimmer Amethyst)
    local tracer = Drawing.new("Line")
    tracer.Visible = false; tracer.Color = THEME.ESPTracer; tracer.Thickness = 1

    -- Distance label
    local distLabel = Drawing.new("Text")
    distLabel.Visible = false; distLabel.Color = Color3.fromRGB(255, 230, 80)
    distLabel.Size = 13; distLabel.Outline = true; distLabel.Center = true

    -- Name label (slightly brighter amethyst)
    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false; nameLabel.Size = 13; nameLabel.Outline = true; nameLabel.Center = true
    nameLabel.Color = THEME.AccentBright
    nameLabel.Text = player.DisplayName or player.Name

    -- Health bar background
    local healthBg = Drawing.new("Square")
    healthBg.Visible = false; healthBg.Color = Color3.fromRGB(15, 5, 20); healthBg.Filled = true

    -- Health bar fill
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false; healthBar.Color = THEME.HealthGreen; healthBar.Filled = true

    -- Skeleton bones
    local bones = {}
    for i = 1, MAX_BONES do
        local b = Drawing.new("Line")
        b.Visible = false; b.Color = c; b.Thickness = 1.2
        bones[i] = b
    end

    -- Radar dot
    local radarDot = Drawing.new("Circle")
    radarDot.Radius = 4; radarDot.Filled = true; radarDot.Color = c; radarDot.Visible = false

    -- Wallhack highlight
    local highlight = nil
    if player.Character then highlight = makeHighlight(player.Character) end

    ESPPool[player] = {
        box = box, tracer = tracer, distLabel = distLabel,
        nameLabel = nameLabel, healthBg = healthBg, healthBar = healthBar,
        bones = bones, highlight = highlight, radarDot = radarDot,
    }
end

local function removeESP(player)
    local esp = ESPPool[player]
    if not esp then return end
    local function rm(o) _safeCall(function() o:Remove() end) end
    rm(esp.box); rm(esp.tracer); rm(esp.distLabel); rm(esp.nameLabel)
    rm(esp.healthBg); rm(esp.healthBar); rm(esp.radarDot)
    for _, b in ipairs(esp.bones) do rm(b) end
    if esp.highlight then _safeCall(function() esp.highlight:Destroy() end) end
    ESPPool[player] = nil
    PartCache[player] = nil
end

local function hideESP(esp)
    esp.box.Visible = false; esp.tracer.Visible = false
    esp.distLabel.Visible = false; esp.nameLabel.Visible = false
    esp.healthBg.Visible = false; esp.healthBar.Visible = false
    esp.radarDot.Visible = false
    for _, b in ipairs(esp.bones) do b.Visible = false end
end

local function healthColor(pct)
    if pct > 0.5 then
        return Color3.fromRGB(math.floor(255*(1-pct)*2), 255, 0)
    end
    return Color3.fromRGB(255, math.floor(255*pct*2), 0)
end

-- ============================================================
-- CROSSHAIR
-- ============================================================
local xhLines = {}
for i = 1, 4 do
    local l = Drawing.new("Line")
    l.Color = THEME.White; l.Thickness = 1.5; l.Visible = false
    xhLines[i] = l
end

local function updateCrosshair()
    if not S.Crosshair then
        for _, l in ipairs(xhLines) do l.Visible = false end
        return
    end
    local cx = Camera.ViewportSize.X * 0.5
    local cy = Camera.ViewportSize.Y * 0.5
    local g, sz = S.XH_Gap, S.XH_Size
    xhLines[1].From = Vector2.new(cx, cy-g-sz); xhLines[1].To = Vector2.new(cx, cy-g)
    xhLines[2].From = Vector2.new(cx, cy+g);    xhLines[2].To = Vector2.new(cx, cy+g+sz)
    xhLines[3].From = Vector2.new(cx-g-sz, cy); xhLines[3].To = Vector2.new(cx-g, cy)
    xhLines[4].From = Vector2.new(cx+g, cy);    xhLines[4].To = Vector2.new(cx+g+sz, cy)
    for _, l in ipairs(xhLines) do l.Visible = true end
end

-- ============================================================
-- FOV CIRCLE (Amethyst-colored)
-- ============================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Color = THEME.Accent; fovCircle.Thickness = 1.5
fovCircle.Filled = false; fovCircle.Visible = false; fovCircle.NumSides = 64

local function updateFOV()
    if not S.FOV_Show then fovCircle.Visible = false return end
    local vp = Camera.ViewportSize
    fovCircle.Position = Vector2.new(vp.X*0.5, vp.Y*0.5)
    fovCircle.Radius = S.FOV_Radius
    fovCircle.Color = THEME.Accent
    fovCircle.Visible = true
end

-- ============================================================
-- ENEMY ALERT
-- ============================================================
local alertCircle = Drawing.new("Circle")
alertCircle.Color = THEME.AlertRed; alertCircle.Thickness = 3
alertCircle.Filled = false; alertCircle.Visible = false; alertCircle.NumSides = 48; alertCircle.Radius = 60

local alertText = Drawing.new("Text")
alertText.Color = THEME.AlertRed; alertText.Size = 16
alertText.Outline = true; alertText.Center = true
alertText.Text = "ENEMY NEARBY"; alertText.Visible = false

local alertThrottle = 0

local function updateEnemyAlert(now)
    if not S.EnemyAlert then
        alertCircle.Visible = false; alertText.Visible = false; return
    end
    if now - alertThrottle < 0.25 then return end
    alertThrottle = now

    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not lr then alertCircle.Visible = false; alertText.Visible = false; return end

    local found = false
    local look = lr.CFrame.LookVector
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pc = PartCache[p]
            if pc and pc.root and pc.hum and pc.hum.Health > 0 then
                local diff = pc.root.Position - lr.Position
                if diff.Magnitude <= S.EnemyAlertDist then
                    local dot = look.X * diff.Unit.X + look.Z * diff.Unit.Z
                    if dot < 0.2 then found = true; break end
                end
            end
        end
    end

    if found then
        local vp = Camera.ViewportSize
        alertCircle.Position = Vector2.new(vp.X*0.5, vp.Y*0.5)
        alertCircle.Radius = 60 + math.sin(now * 8) * 15
        alertCircle.Visible = true
        alertText.Position = Vector2.new(vp.X*0.5, vp.Y*0.5 - 80)
        alertText.Visible = true
    else
        alertCircle.Visible = false; alertText.Visible = false
    end
end

-- ============================================================
-- RADAR
-- ============================================================
local radarBg = Drawing.new("Square")
radarBg.Filled = true; radarBg.Color = Color3.fromRGB(8, 4, 18); radarBg.Transparency = 0.3; radarBg.Visible = false
local radarBorder = Drawing.new("Square")
radarBorder.Filled = false; radarBorder.Color = THEME.ESPColor; radarBorder.Thickness = 1.5; radarBorder.Visible = false
local radarSelf = Drawing.new("Circle")
radarSelf.Filled = true; radarSelf.Color = Color3.fromRGB(80, 255, 100); radarSelf.Radius = 4; radarSelf.Visible = false
local radarLabel = Drawing.new("Text")
radarLabel.Color = THEME.Accent; radarLabel.Size = 11; radarLabel.Outline = true
radarLabel.Center = true; radarLabel.Text = "RADAR"; radarLabel.Visible = false

local radarThrottle = 0

local function updateRadar(now)
    if not S.Radar then
        radarBg.Visible = false; radarBorder.Visible = false
        radarSelf.Visible = false; radarLabel.Visible = false
        for _, esp in pairs(ESPPool) do esp.radarDot.Visible = false end
        return
    end
    if now - radarThrottle < 0.05 then return end
    radarThrottle = now

    local sz = S.RadarSize
    local vp = Camera.ViewportSize
    local rx, ry = vp.X - sz - 10, vp.Y - sz - 10
    local half = sz * 0.5
    local rcx, rcy = rx + half, ry + half

    radarBg.Position = Vector2.new(rx, ry); radarBg.Size = Vector2.new(sz, sz); radarBg.Visible = true
    radarBorder.Position = Vector2.new(rx, ry); radarBorder.Size = Vector2.new(sz, sz)
    radarBorder.Color = THEME.ESPColor; radarBorder.Visible = true
    radarSelf.Position = Vector2.new(rcx, rcy); radarSelf.Visible = true
    radarLabel.Position = Vector2.new(rcx, ry + sz + 2); radarLabel.Visible = true

    local look = Camera.CFrame.LookVector
    local yaw = math.atan2(look.X, look.Z)
    local cosY, sinY = math.cos(-yaw), math.sin(-yaw)
    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for player, esp in pairs(ESPPool) do
        local pc = PartCache[player]
        if not pc or not pc.root or not lr then
            esp.radarDot.Visible = false
        else
            if not pc.hum or pc.hum.Health <= 0 then
                esp.radarDot.Visible = false
            else
                local relX = pc.root.Position.X - lr.Position.X
                local relZ = pc.root.Position.Z - lr.Position.Z
                local dist = math.sqrt(relX*relX + relZ*relZ)
                if dist > S.RadarRange then
                    esp.radarDot.Visible = false
                else
                    local rotX = relX*cosY - relZ*sinY
                    local rotZ = relX*sinY + relZ*cosY
                    local scale = half / S.RadarRange
                    esp.radarDot.Position = Vector2.new(
                        math.clamp(rcx + rotX*scale, rx+4, rx+sz-4),
                        math.clamp(rcy - rotZ*scale, ry+4, ry+sz-4)
                    )
                    esp.radarDot.Color = THEME.ESPColor
                    esp.radarDot.Visible = true
                end
            end
        end
    end
end

-- ============================================================
-- HUD: PLAYER/BOT COUNTER + KILL COUNTER
-- ============================================================
local SessionKills, SessionDeaths = 0, 0
local trackedHP = {}

local hudPBg = Drawing.new("Square"); hudPBg.Filled = true; hudPBg.Color = Color3.fromRGB(200, 40, 40); hudPBg.Visible = false
local hudBBg = Drawing.new("Square"); hudBBg.Filled = true; hudBBg.Color = Color3.fromRGB(40, 180, 60); hudBBg.Visible = false
local hudPTxt = Drawing.new("Text"); hudPTxt.Color = THEME.White; hudPTxt.Size = 15; hudPTxt.Outline = true; hudPTxt.Center = true; hudPTxt.Visible = false
local hudBTxt = Drawing.new("Text"); hudBTxt.Color = THEME.White; hudBTxt.Size = 15; hudBTxt.Outline = true; hudBTxt.Center = true; hudBTxt.Visible = false
local killBg = Drawing.new("Square"); killBg.Filled = true; killBg.Color = Color3.fromRGB(30, 10, 50); killBg.Visible = false
local killTxt = Drawing.new("Text"); killTxt.Color = Color3.fromRGB(255, 200, 80); killTxt.Size = 14; killTxt.Outline = true; killTxt.Center = true; killTxt.Visible = false

local hudThrottle = 0

local function updateHUDs(now)
    if not S.PlayerBotHUD then
        hudPBg.Visible = false; hudBBg.Visible = false
        hudPTxt.Visible = false; hudBTxt.Visible = false
    else
        if now - hudThrottle >= 0.5 then
            hudThrottle = now
            local realCount = #Players:GetPlayers()
            local playerChars = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then playerChars[p.Character] = true end
            end
            local botCount = 0
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and not playerChars[obj] then
                    if obj:FindFirstChildOfClass("Humanoid") then botCount = botCount + 1 end
                end
            end
            local vp = Camera.ViewportSize
            local bW, bH, gap = 56, 26, 6
            local sx = (vp.X - bW*2 - gap) * 0.5
            hudPBg.Position = Vector2.new(sx, 8); hudPBg.Size = Vector2.new(bW, bH); hudPBg.Visible = true
            hudBBg.Position = Vector2.new(sx+bW+gap, 8); hudBBg.Size = Vector2.new(bW, bH); hudBBg.Visible = true
            local cy = 8 + bH*0.5 - 8
            hudPTxt.Text = "P:" .. realCount; hudPTxt.Position = Vector2.new(sx+bW*0.5, cy); hudPTxt.Visible = true
            hudBTxt.Text = "B:" .. botCount; hudBTxt.Position = Vector2.new(sx+bW+gap+bW*0.5, cy); hudBTxt.Visible = true
        end
    end

    if not S.KillCounter then
        killBg.Visible = false; killTxt.Visible = false
    else
        if now - hudThrottle >= 0.4 then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local pc = PartCache[p]
                    if pc and pc.hum then
                        local hp = pc.hum.Health
                        local last = trackedHP[p]
                        if last and last > 0 and hp <= 0 then SessionKills = SessionKills + 1 end
                        trackedHP[p] = hp
                    end
                end
            end
            local vp = Camera.ViewportSize
            killBg.Position = Vector2.new(10, vp.Y - 36); killBg.Size = Vector2.new(120, 26); killBg.Visible = true
            local kd = SessionDeaths > 0 and string.format("%.1f", SessionKills/SessionDeaths) or tostring(SessionKills)
            killTxt.Text = "K:" .. SessionKills .. " D:" .. SessionDeaths .. " R:" .. kd
            killTxt.Position = Vector2.new(70, vp.Y - 31); killTxt.Visible = true
        end
    end
end

-- ============================================================
-- AIMBOT TARGET CACHE (Camera.CFrame + ClosestPlayer logic)
-- ============================================================
local cachedTarget = nil
local lastTargetRefresh = 0
_G.__AmethystTargetV3 = nil

local function getClosestEnemy(now)
    if now - lastTargetRefresh < 0.15 then return cachedTarget end
    lastTargetRefresh = now

    local best, bestDist = nil, math.huge
    local vp = Camera.ViewportSize
    local cx, cy = vp.X*0.5, vp.Y*0.5

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pc = PartCache[p]
            if pc and pc.hum and pc.head and pc.hum.Health > 0 then
                local skip = false
                if S.VisCheck then
                    local char = p.Character
                    if char then
                        local obs = Camera:GetPartsObscuringTarget({pc.head.Position}, {LocalPlayer.Character, char})
                        if #obs > 0 then skip = true end
                    end
                end
                if not skip then
                    local sp, onScreen = Camera:WorldToViewportPoint(pc.head.Position)
                    if onScreen then
                        local dx, dy = sp.X - cx, sp.Y - cy
                        local d = math.sqrt(dx*dx + dy*dy)
                        if (not S.FOV_Lock or d <= S.FOV_Radius) and d < bestDist then
                            bestDist = d; best = p
                        end
                    end
                end
            end
        end
    end

    cachedTarget = best; _G.__AmethystTargetV3 = best
    return best
end

-- ============================================================
-- WEAPON MODIFIER — FIX 12: Cached tool scan
-- ============================================================
local weaponThrottle = 0
local weaponCache = {} -- FIX 12: [tool] = {recoil, spread, reload, ammo}

local function applyWeaponMods(now)
    if now - weaponThrottle < _G.Config.WeaponScanInterval then return end
    weaponThrottle = now
    _safeCall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end

        -- FIX 12: Build cache on first scan for this tool
        if not weaponCache[tool] then
            local cache = {recoil = {}, spread = {}, reload = {}, ammo = {}}
            for _, d in ipairs(tool:GetDescendants()) do
                if d:IsA("NumberValue") or d:IsA("IntValue") then
                    local n = string.lower(d.Name)
                    if n == "recoil" or n == "kick" or n:find("recoilforce") then
                        cache.recoil[#cache.recoil + 1] = d
                    end
                    if n == "spread" or n == "accuracy" or n:find("bulletspread") then
                        cache.spread[#cache.spread + 1] = d
                    end
                    if n == "reloadtime" or n == "reload" then
                        cache.reload[#cache.reload + 1] = d
                    end
                    if n == "ammo" or n == "currentammo" or n == "magsize" or n == "clipsize" then
                        cache.ammo[#cache.ammo + 1] = d
                    end
                end
            end
            weaponCache[tool] = cache
        end

        local c = weaponCache[tool]
        if S.NoRecoil then for _, d in ipairs(c.recoil) do _safeCall(function() d.Value = 0 end) end end
        if S.NoSpread then for _, d in ipairs(c.spread) do _safeCall(function() d.Value = 0 end) end end
        if S.FastReload then for _, d in ipairs(c.reload) do _safeCall(function() d.Value = 0.05 end) end end
        if S.InfAmmo then for _, d in ipairs(c.ammo) do _safeCall(function() d.Value = math.max(d.Value, 999) end) end end
    end)
end

-- FIX 24: Reusable helper — IsVisible
local function IsVisible(fromChar, targetHead, targetChar)
    if not fromChar or not targetHead then return false end
    local obs = Camera:GetPartsObscuringTarget({targetHead.Position}, {fromChar, targetChar})
    return #obs == 0
end

-- ============================================================
-- SERVER FINDER
-- ============================================================
local serverFetching = false

local function fetchSmallestServers(placeId, maxPages)
    placeId = placeId or game.PlaceId
    maxPages = maxPages or 5
    serverFetching = true
    local all = {}
    local cursor = ""
    local page = 0

    while page < maxPages do
        page = page + 1
        local url = "https://games.roblox.com/v1/games/" .. tostring(placeId)
            .. "/servers/0?sortOrder=1&excludeFullGames=true&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end

        local raw = safeHttpGet(url)
        if not raw then break end
        local ok, data = _safeCall(function() return HttpService:JSONDecode(raw) end)
        if not ok or not data or not data.data then break end

        for _, sv in ipairs(data.data) do
            if sv.playing and sv.id and sv.id ~= game.JobId and sv.playing > 0 then
                all[#all + 1] = { id = sv.id, playing = sv.playing, maxPlayers = sv.maxPlayers or 0 }
            end
        end

        if data.nextPageCursor and data.nextPageCursor ~= "" then
            cursor = data.nextPageCursor
        else break end
        task.wait(0.4)
    end

    table.sort(all, function(a, b) return a.playing < b.playing end)
    serverFetching = false
    S.ServerList = all
    return all
end

local function teleportToServer(placeId, jobId)
    notify("Teleporting...", "Joining " .. string.sub(jobId, 1, 8) .. "...", 4)
    task.wait(0.5)
    local ok, err = _safeCall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
    end)
    if not ok then
        notify("Failed", tostring(err), 4)
        task.wait(2)
        _safeCall(function() TeleportService:TeleportToPlaceInstance(placeId, jobId) end)
    end
end

local function findSmallestAndJoin(placeId)
    if serverFetching then notify("Wait", "Already scanning...", 2) return end
    placeId = placeId or game.PlaceId
    notify("Scanning...", "Fetching servers...", 3)
    local list = fetchSmallestServers(placeId)
    if not list or #list == 0 then notify("Error", "No servers found.", 4) return end
    notify("Found " .. #list, "Smallest: " .. list[1].playing .. " players. Joining...", 4)
    task.wait(1)
    teleportToServer(placeId, list[1].id)
end

-- ============================================================
-- SILENT AIM TOOL HOOK — Section 4: smooth interpolation
-- ============================================================
local function hookSilentAim(tool)
    tool.Activated:Connect(function()
        if not S.SilentAim then return end
        local t = _G.__AmethystTargetV3
        if not t then return end
        local pc = PartCache[t]
        if not pc then return end
        local aim = (S.AimPart == "Torso") and pc.torso or pc.head
        if not aim then return end
        -- Section 4: Smooth lerp instead of instant snap
        local saved = Camera.CFrame
        Camera.CFrame = saved:Lerp(
            CFrame.new(Camera.CFrame.Position, aim.Position),
            0.85
        )
        task.defer(function() Camera.CFrame = saved end)
    end)
end

-- ============================================================
-- MOBILE JUMP BUTTON SCALE (1x to 3x)
-- ============================================================
local _jumpOrigSizes = {}

local function scaleJumpButton(mult)
    _safeCall(function()
        local function processJumpButtons(parent)
            if not parent then return end
            for _, d in ipairs(parent:GetDescendants()) do
                _safeCall(function()
                    if string.lower(d.Name):find("jump") and (d:IsA("ImageButton") or d:IsA("TextButton")) then
                        if not _jumpOrigSizes[d] then
                            _jumpOrigSizes[d] = d.Size
                        end
                        local orig = _jumpOrigSizes[d]
                        if orig then
                            d.Size = UDim2.new(
                                orig.X.Scale * mult, orig.X.Offset * mult,
                                orig.Y.Scale * mult, orig.Y.Offset * mult
                            )
                        end
                    end
                end)
            end
        end
        processJumpButtons(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
        _safeCall(function() processJumpButtons(CoreGui:FindFirstChild("TouchGui")) end)
    end)
end

-- ============================================================
-- FLY SYSTEM — FIX 19: Mobile ▲▼ buttons
-- ============================================================
local flyBodyVel, flyBodyGyro
local flyConn
local flyUp, flyDown = false, false  -- FIX 19: mobile state
local flyMobileGui = nil

-- FIX 19: Create mobile fly buttons
local function createMobileFlyButtons()
    if not IS_MOBILE or flyMobileGui then return end
    _safeCall(function()
        flyMobileGui = Instance.new("ScreenGui")
        flyMobileGui.Name = "AmethystFlyButtons"
        flyMobileGui.ResetOnSpawn = false
        flyMobileGui.DisplayOrder = 1001
        local pgOk = _safeCall(function() flyMobileGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
        if not pgOk then flyMobileGui = nil; return end

        local upBtn = Instance.new("TextButton")
        upBtn.Name = "FlyUp"
        upBtn.Size = UDim2.new(0, 60, 0, 60)
        upBtn.Position = UDim2.new(1, -80, 0.5, -70)
        upBtn.BackgroundColor3 = THEME.Main
        upBtn.BackgroundTransparency = 0.3
        upBtn.TextColor3 = THEME.Accent
        upBtn.Text = "▲"
        upBtn.TextSize = 28
        upBtn.Font = Enum.Font.GothamBold
        upBtn.BorderSizePixel = 0
        upBtn.Parent = flyMobileGui
        Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 10)

        upBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then flyUp = true end
        end)
        upBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then flyUp = false end
        end)

        local downBtn = Instance.new("TextButton")
        downBtn.Name = "FlyDown"
        downBtn.Size = UDim2.new(0, 60, 0, 60)
        downBtn.Position = UDim2.new(1, -80, 0.5, 10)
        downBtn.BackgroundColor3 = THEME.Main
        downBtn.BackgroundTransparency = 0.3
        downBtn.TextColor3 = THEME.Accent
        downBtn.Text = "▼"
        downBtn.TextSize = 28
        downBtn.Font = Enum.Font.GothamBold
        downBtn.BorderSizePixel = 0
        downBtn.Parent = flyMobileGui
        Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 10)

        downBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then flyDown = true end
        end)
        downBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then flyDown = false end
        end)
    end)
end

local function destroyMobileFlyButtons()
    flyUp, flyDown = false, false
    if flyMobileGui then
        _safeCall(function() flyMobileGui:Destroy() end)
        flyMobileGui = nil
    end
end

local function startFly()
    _safeCall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        if flyBodyVel then _safeCall(function() flyBodyVel:Destroy() end) end
        if flyBodyGyro then _safeCall(function() flyBodyGyro:Destroy() end) end

        flyBodyVel = Instance.new("BodyVelocity")
        flyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVel.Velocity = Vector3.new(0, 0, 0)
        flyBodyVel.Parent = root

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyGyro.P = 9e4
        flyBodyGyro.D = 600
        flyBodyGyro.Parent = root

        hum.PlatformStand = true

        -- FIX 19: Create mobile buttons
        createMobileFlyButtons()

        if flyConn then flyConn:Disconnect() end
        flyConn = RunService.RenderStepped:Connect(function()
            if not S.Fly then return end
            _safeCall(function()
                if not root or not root.Parent then
                    _safeCall(function() if flyConn then flyConn:Disconnect(); flyConn = nil end end)
                    return
                end
                local camCF = Camera.CFrame
                flyBodyGyro.CFrame = camCF

                local dir = Vector3.new(0, 0, 0)
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    dir = camCF.LookVector * moveDir.Z * -1
                    dir = dir + camCF.RightVector * moveDir.X
                    if dir.Magnitude < 0.1 then
                        dir = camCF.LookVector * moveDir.Magnitude
                    end
                    if dir.Magnitude > 0 then dir = dir.Unit end
                end

                -- FIX 19: Mobile vs keyboard controls
                local upDown = 0
                if IS_MOBILE then
                    if flyUp then upDown = 1 end
                    if flyDown then upDown = -1 end
                else
                    _safeCall(function()
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDown = 1 end
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or
                           UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then upDown = -1 end
                    end)
                end
                if hum.Jump then upDown = 1 end

                local finalVel = dir * S.FlySpeed
                finalVel = Vector3.new(finalVel.X, upDown * S.FlySpeed * 0.8, finalVel.Z)
                flyBodyVel.Velocity = finalVel
            end)
        end)
    end)
end

local function stopFly()
    _safeCall(function()
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
        -- FIX 19: Destroy mobile buttons on stopFly
        destroyMobileFlyButtons()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end)
end

-- ============================================================
-- NOCLIP SYSTEM
-- ============================================================
local noclipConn

local function enableNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        if not S.Noclip then return end
        _safeCall(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

local function disableNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    _safeCall(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end)
end

-- ============================================================
-- GOD MODE (Client-side)
-- ============================================================
local godConn

local function enableGodMode()
    if godConn then return end
    godConn = RunService.Heartbeat:Connect(function()
        if not S.GodMode then return end
        _safeCall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = hum.MaxHealth end
        end)
    end)
end

local function disableGodMode()
    if godConn then godConn:Disconnect(); godConn = nil end
end

-- ============================================================
-- TELEPORT TO PLAYER
-- ============================================================
local function teleportToPlayer(targetName)
    _safeCall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local pName = string.lower(p.Name)
                local pDisplay = string.lower(p.DisplayName)
                local search = string.lower(targetName)
                if pName:find(search) or pDisplay:find(search) then
                    local tChar = p.Character
                    if tChar then
                        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                        if tRoot then
                            root.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
                            notify("Teleported", "Teleported to " .. p.DisplayName, 3)
                            return
                        end
                    end
                end
            end
        end
        notify("Not Found", "Player not found: " .. targetName, 3)
    end)
end

local function teleportToNearest()
    _safeCall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    local d = (tRoot.Position - root.Position).Magnitude
                    if d < bestDist then bestDist = d; best = p end
                end
            end
        end
        if best and best.Character then
            local tRoot = best.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                root.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
                notify("Teleported", "Teleported to " .. best.DisplayName .. " (" .. math.floor(bestDist) .. "m)", 3)
            end
        else
            notify("No Players", "No other players found.", 3)
        end
    end)
end

-- ============================================================
-- KILL AURA — FIX 7: 0.2s Activate cooldown
-- ============================================================
local kaThrottle = 0
local kaActivateCooldown = 0  -- FIX 7

local function updateKillAura(now)
    if not S.KillAura then return end
    if now - kaThrottle < 0.15 then return end
    kaThrottle = now
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local tool = char:FindFirstChildOfClass("Tool")
    if not root or not tool then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pc = PartCache[p]
            if pc and pc.root and pc.hum and pc.hum.Health > 0 then
                if (pc.root.Position - root.Position).Magnitude <= S.KillAuraRange then
                    _safeCall(function()
                        local aim = (S.AimPart == "Torso") and pc.torso or pc.head
                        if aim then
                            -- Section 4: Smooth camera interpolation
                            Camera.CFrame = Camera.CFrame:Lerp(
                                CFrame.new(Camera.CFrame.Position, aim.Position),
                                0.5
                            )
                            -- FIX 7: Internal cooldown before tool:Activate()
                            if now - kaActivateCooldown >= _G.Config.KillAuraCooldown then
                                kaActivateCooldown = now
                                tool:Activate()
                            end
                        end
                    end)
                    break
                end
            end
        end
    end
end

-- ============================================================
-- CHARACTER HOOKS — FIX 16, 20
-- ============================================================
local function onCharAdded(player, char)
    headOrigSizes[player] = nil
    -- FIX 16: Wait for full character load
    if not char:IsDescendantOf(workspace) then
        char.AncestryChanged:Wait()
    end
    task.wait(_G.Config.CacheBuildDelay)
    buildPartCache(player)

    -- Event-Driven ESP: auto-create ESP entry on character spawn if missing.
    -- Handles late-joining players or players whose ESP was cleaned up.
    if player ~= LocalPlayer and not ESPPool[player] then
        task.defer(function() createESP(player) end)
    end

    local esp = ESPPool[player]
    if esp then
        if esp.highlight then _safeCall(function() esp.highlight:Destroy() end) end
        esp.highlight = makeHighlight(char)
    end

    if player == LocalPlayer then
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") then hookSilentAim(obj) end
        end
        char.ChildAdded:Connect(function(obj)
            if obj:IsA("Tool") then hookSilentAim(obj) end
        end)

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            _safeCall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end)
        end

        -- FIX 20: Fast Respawn safety — search ONLY PlayerGui, EXACT names, pcall Activate
        if hum and S.FastRespawn then
            hum.Died:Connect(function()
                if not S.FastRespawn then return end
                task.wait(0.5)
                _safeCall(function()
                    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    if gui then
                        local RESPAWN_NAMES = {
                            Respawn = true, RespawnButton = true,
                            PlayAgain = true, DeployButton = true,
                        }
                        for _, d in ipairs(gui:GetDescendants()) do
                            if (d:IsA("TextButton") or d:IsA("ImageButton")) and RESPAWN_NAMES[d.Name] then
                                _safeCall(function() d:Activate() end)
                                break
                            end
                        end
                    end
                end)
            end)
        end
    end

    task.wait(0.5)
    if S.Hitbox and player ~= LocalPlayer then applyHitbox(player) end
end

local function hookPlayer(player)
    if player.Character then
        task.spawn(function()
            task.wait(_G.Config.CacheBuildDelay)
            buildPartCache(player)
        end)
    end
    player.CharacterAdded:Connect(function(char) onCharAdded(player, char) end)
end

-- Death tracking + fly cleanup
track(LocalPlayer.CharacterRemoving:Connect(function()
    SessionDeaths = SessionDeaths + 1
    if S.Fly then _safeCall(stopFly) end
end))

track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    if S.Fly then _safeCall(startFly) end
end))

-- Init all existing players (task.defer prevents frame drops on bulk load)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        task.defer(function() createESP(p) end)
    end
    hookPlayer(p)
end

-- Event-Driven: PlayerRemoving auto-cleans ESP + memory immediately
-- Event-Driven: PlayerAdded auto-inserts into ESP cache via task.defer
track(Players.PlayerAdded:Connect(function(p)
    if p == LocalPlayer then return end
    task.defer(function()
        createESP(p)
        hookPlayer(p)
    end)
end))
track(Players.PlayerRemoving:Connect(function(p)
    removeESP(p); headOrigSizes[p] = nil; trackedHP[p] = nil
    weaponCache = {} -- Clear weapon cache when players change
end))

-- ============================================================
-- VIEWPORT CACHE
-- ============================================================
local lastVP = Vector2.new(0, 0)
local bottomCenter = Vector2.new(0, 0)

local function refreshVP()
    local vp = Camera.ViewportSize
    if vp ~= lastVP then lastVP = vp; bottomCenter = Vector2.new(vp.X*0.5, vp.Y) end
end

-- ============================================================
-- ESP UPDATE (split throttle: box 60fps, skeleton 30fps)
-- ============================================================
local skelThrottle = 0

local function updateESP(now)
    refreshVP()
    local anyESP = S.ESP_Box or S.ESP_Skeleton or S.ESP_Tracer or S.ESP_Distance or S.ESP_Name or S.ESP_Health
    if not anyESP then
        for _, esp in pairs(ESPPool) do hideESP(esp) end
        return
    end

    local camPos = Camera.CFrame.Position
    local doSkel = S.ESP_Skeleton and (now - skelThrottle >= 0.033)
    if doSkel then skelThrottle = now end

    for player, esp in pairs(ESPPool) do
        local pc = PartCache[player]
        if not pc then hideESP(esp)
        else
            local hum, head, root = pc.hum, pc.head, pc.root
            if not hum or hum.Health <= 0 or not head or not root then hideESP(esp)
            else
                local skipVis = false
                if S.VisCheck then
                    local char = player.Character
                    if char then
                        local obs = Camera:GetPartsObscuringTarget({head.Position}, {LocalPlayer.Character, char})
                        if #obs > 0 then hideESP(esp); skipVis = true end
                    end
                end

                if not skipVis then
                    -- Section 8: R6 vs R15 rig-aware box sizing
                    local isR15 = pc.torso and pc.torso.Name == "UpperTorso"
                    local headOff = isR15 and 0.7 or 0.5
                    local feetOff = isR15 and 3.2 or 2.8
                    local hSP, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, headOff, 0))
                    local rSP = Camera:WorldToViewportPoint(root.Position)
                    local fSP = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, feetOff, 0))

                    if not hOn then hideESP(esp)
                    else
                        local boxH = math.max(fSP.Y - hSP.Y, 4)
                        local boxW = boxH * 0.55
                        local boxL = rSP.X - boxW * 0.5
                        local boxT = hSP.Y

                        -- Amethyst-colored Box ESP
                        if S.ESP_Box then
                            esp.box.Size = Vector2.new(boxW, boxH)
                            esp.box.Position = Vector2.new(boxL, boxT)
                            esp.box.Color = S.ESPColor; esp.box.Visible = true
                        else esp.box.Visible = false end

                        if S.ESP_Name then
                            esp.nameLabel.Position = Vector2.new(rSP.X, boxT - 16)
                            esp.nameLabel.Visible = true
                        else esp.nameLabel.Visible = false end

                        if S.ESP_Health then
                            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                            local bW, bX = 3, boxL - 5
                            local fH = math.max(math.floor(boxH * pct), 1)
                            esp.healthBg.Size = Vector2.new(bW, boxH)
                            esp.healthBg.Position = Vector2.new(bX, boxT); esp.healthBg.Visible = true
                            esp.healthBar.Size = Vector2.new(bW, fH)
                            esp.healthBar.Position = Vector2.new(bX, boxT + boxH - fH)
                            esp.healthBar.Color = healthColor(pct); esp.healthBar.Visible = true
                        else
                            esp.healthBg.Visible = false; esp.healthBar.Visible = false
                        end

                        -- Amethyst-colored Tracers
                        if S.ESP_Tracer then
                            esp.tracer.From = bottomCenter
                            esp.tracer.To = Vector2.new(rSP.X, rSP.Y)
                            esp.tracer.Color = THEME.ESPTracer
                            esp.tracer.Visible = true
                        else esp.tracer.Visible = false end

                        if S.ESP_Distance then
                            local d = math.floor((camPos - root.Position).Magnitude)
                            esp.distLabel.Position = Vector2.new(rSP.X, boxT + boxH + 2)
                            esp.distLabel.Text = d .. "m"; esp.distLabel.Visible = true
                        else esp.distLabel.Visible = false end

                        if S.ESP_Skeleton and doSkel then
                            for i = 1, pc.numBones do
                                local bone = esp.bones[i]
                                if not bone then break end
                                local pair = pc.boneParts[i]
                                if pair[1] and pair[2] then
                                    local sA, oA = Camera:WorldToViewportPoint(pair[1].Position)
                                    local sB, oB = Camera:WorldToViewportPoint(pair[2].Position)
                                    if oA and oB then
                                        bone.From = Vector2.new(sA.X, sA.Y)
                                        bone.To = Vector2.new(sB.X, sB.Y)
                                        bone.Color = S.ESPColor; bone.Visible = true
                                    else bone.Visible = false end
                                else bone.Visible = false end
                            end
                            for i = pc.numBones + 1, MAX_BONES do
                                if esp.bones[i] then esp.bones[i].Visible = false end
                            end
                        elseif not S.ESP_Skeleton then
                            for _, b in ipairs(esp.bones) do b.Visible = false end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- ===================  T A B S  ==============================
-- ============================================================

-- TAB 1: HOME ------------------------------------------------
local HomeTab = Window:CreateTab("Home", "home")

HomeTab:CreateSection("Welcome")
HomeTab:CreateParagraph({
    Title = "  Amethyst  |  Universal  ",
    Content = "Professional-Grade Universal Mod Menu\n"
        .. "7 Tabs | Combat + Visuals + Gameplay + Performance\n"
        .. "Game: " .. tostring(game.PlaceId) .. "\n"
        .. "Players: " .. #Players:GetPlayers(),
})

HomeTab:CreateSection("Quick Presets")

HomeTab:CreateButton({
    Name = "Enable All FPS Optimizations",
    Callback = function()
        S.FPSBoost = true; S.LightingUltra = true
        S.TexturePurge = true; S.ParticlePurge = true; S.TerrainSimple = true
        task.spawn(runOmegaFPS); enableFPSListener()
        applyLightingUltra()
        local tc = purgeTextures(); enableTexListener()
        local pc = purgeParticles(); simplifyTerrain()
        notify("Omega FPS ON", tc .. " textures + " .. pc .. " particles removed.", 4)
    end,
})

HomeTab:CreateButton({
    Name = "Enable Full ESP Suite",
    Callback = function()
        S.ESP_Box = true; S.ESP_Name = true; S.ESP_Health = true
        S.ESP_Tracer = true; S.Wallhack = true
        for _, esp in pairs(ESPPool) do
            if esp.highlight then esp.highlight.Enabled = true end
        end
        notify("Full ESP ON", "Box + Name + Health + Tracers + Wallhack", 3)
    end,
})

HomeTab:CreateButton({
    Name = "Enable Combat Suite",
    Callback = function()
        S.Aimbot = true; S.SilentAim = true; S.FOV_Show = true
        S.FOV_Lock = true; S.NoRecoil = true; S.NoSpread = true
        notify("Combat Suite ON", "Aimbot + Silent Aim + FOV Lock + No Recoil", 3)
    end,
})

HomeTab:CreateButton({
    Name = "Enable Movement Suite",
    Callback = function()
        S.Speed = true; S.SpeedVal = 50; S.InfJump = true; S.NoFallDmg = true
        _safeCall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end)
        notify("Movement Suite ON", "Speed + Inf Jump + No Fall Damage", 3)
    end,
})

HomeTab:CreateButton({
    Name = "Disable Everything",
    Callback = function()
        S.FPSBoost = false; S.LightingUltra = false
        S.TexturePurge = false; S.ParticlePurge = false; S.TerrainSimple = false
        S.ESP_Box = false; S.ESP_Name = false; S.ESP_Health = false
        S.ESP_Tracer = false; S.ESP_Skeleton = false; S.ESP_Distance = false
        S.Wallhack = false; S.Aimbot = false; S.SilentAim = false
        S.TriggerBot = false; S.KillAura = false; S.Crosshair = false
        S.Radar = false; S.EnemyAlert = false
        S.Fly = false; S.Noclip = false; S.GodMode = false
        S.NoRecoil = false; S.NoSpread = false; S.FastReload = false; S.InfAmmo = false
        _safeCall(stopFly); _safeCall(disableNoclip); _safeCall(disableGodMode)
        disableFPSListener(); disableTexListener(); restoreLighting()
        for _, esp in pairs(ESPPool) do
            hideESP(esp)
            if esp.highlight then esp.highlight.Enabled = false end
        end
        notify("All OFF", "Every feature disabled.", 3)
    end,
})

-- TAB 2: COMBAT ----------------------------------------------
local CombatTab = Window:CreateTab("Combat", "crosshair")

CombatTab:CreateSection("-- Aimbot (Camera.CFrame + ClosestPlayer) --")

CombatTab:CreateToggle({
    Name = "Aimbot", CurrentValue = false,
    Callback = debounced("Aimbot", function(v) S.Aimbot = v; notifyToggle("Aimbot", v) end),
})

CombatTab:CreateSlider({
    Name = "Smoothness (1=snap, 10=slow)",
    Range = {1, 10}, Increment = 1, CurrentValue = 3,
    Callback = function(v) S.AimbotSmooth = v end,
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "Torso"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Callback = function(v) S.AimPart = type(v) == "table" and v[1] or tostring(v) end,
})

CombatTab:CreateToggle({
    Name = "Aim Prediction (Lead Targets)", CurrentValue = false,
    Callback = debounced("AimPredict", function(v) S.AimPredict = v; notifyToggle("Aim Prediction", v) end),
})

CombatTab:CreateSlider({
    Name = "Prediction Strength",
    Range = {1, 30}, Increment = 1, CurrentValue = 12,
    Callback = function(v) S.AimPredictStr = v / 100 end,
})

CombatTab:CreateSection("-- Aimlock (FOV Circle) --")

CombatTab:CreateToggle({
    Name = "Show FOV Circle", CurrentValue = false,
    Callback = debounced("FOV_Show", function(v) S.FOV_Show = v; notifyToggle("FOV Circle", v) end),
})

CombatTab:CreateToggle({
    Name = "FOV Lock (Only Aim Inside Circle)", CurrentValue = false,
    Callback = debounced("FOV_Lock", function(v) S.FOV_Lock = v; notifyToggle("FOV Lock", v) end),
})

CombatTab:CreateSlider({
    Name = "FOV Radius (px)",
    Range = {40, 400}, Increment = 10, CurrentValue = 120,
    Callback = function(v) S.FOV_Radius = v end,
})

CombatTab:CreateSection("Silent Aim")

CombatTab:CreateToggle({
    Name = "Silent Aim (1-frame snap)", CurrentValue = false,
    Callback = debounced("SilentAim", function(v) S.SilentAim = v; notifyToggle("Silent Aim", v) end),
})

CombatTab:CreateSection("Auto Fire")

CombatTab:CreateToggle({
    Name = "TriggerBot (Auto Fire on Hit)", CurrentValue = false,
    Callback = debounced("TriggerBot", function(v) S.TriggerBot = v; notifyToggle("TriggerBot", v) end),
})

CombatTab:CreateToggle({
    Name = "Kill Aura (Fire Nearby)", CurrentValue = false,
    Callback = debounced("KillAura", function(v) S.KillAura = v; notifyToggle("Kill Aura", v) end),
})

CombatTab:CreateSlider({
    Name = "Kill Aura Range (m)",
    Range = {10, 80}, Increment = 5, CurrentValue = 25,
    Callback = function(v) S.KillAuraRange = v end,
})

CombatTab:CreateSection("Hitbox")

CombatTab:CreateToggle({
    Name = "Hitbox Expand", CurrentValue = false,
    Callback = debounced("Hitbox", function(v) S.Hitbox = v; applyAllHitboxes(); notifyToggle("Hitbox Expand", v) end),
})

CombatTab:CreateSlider({
    Name = "Hitbox Scale",
    Range = {1, 8}, Increment = 1, CurrentValue = 2,
    Callback = function(v) S.HitboxScale = v; if S.Hitbox then applyAllHitboxes() end end,
})

-- TAB 3: VISUALS --------------------------------------------
local VisualsTab = Window:CreateTab("Visuals", "eye")

VisualsTab:CreateSection("Wallhack")

VisualsTab:CreateToggle({
    Name = "Wallhack (Highlight Through Walls)", CurrentValue = false,
    Callback = debounced("Wallhack", function(v)
        S.Wallhack = v
        for _, esp in pairs(ESPPool) do
            if esp.highlight then esp.highlight.Enabled = v end
        end
        notifyToggle("Wallhack", v)
    end),
})

VisualsTab:CreateSection("-- ESP (Amethyst-Colored Outlines) --")

VisualsTab:CreateToggle({ Name = "Box ESP", CurrentValue = false,
    Callback = function(v) S.ESP_Box = v; notifyToggle("Box ESP", v)
    if not v then for _, e in pairs(ESPPool) do e.box.Visible = false end end end })
VisualsTab:CreateToggle({ Name = "Name Tags", CurrentValue = false,
    Callback = function(v) S.ESP_Name = v; notifyToggle("Name Tags", v)
    if not v then for _, e in pairs(ESPPool) do e.nameLabel.Visible = false end end end })
VisualsTab:CreateToggle({ Name = "Health Bars", CurrentValue = false,
    Callback = function(v) S.ESP_Health = v; notifyToggle("Health Bars", v)
    if not v then for _, e in pairs(ESPPool) do e.healthBg.Visible = false; e.healthBar.Visible = false end end end })
VisualsTab:CreateToggle({ Name = "Skeleton", CurrentValue = false,
    Callback = function(v) S.ESP_Skeleton = v; notifyToggle("Skeleton", v)
    if not v then for _, e in pairs(ESPPool) do for _, b in ipairs(e.bones) do b.Visible = false end end end end })
VisualsTab:CreateToggle({ Name = "Tracers (Amethyst)", CurrentValue = false,
    Callback = function(v) S.ESP_Tracer = v; notifyToggle("Tracers", v)
    if not v then for _, e in pairs(ESPPool) do e.tracer.Visible = false end end end })
VisualsTab:CreateToggle({ Name = "Distance Tags", CurrentValue = false,
    Callback = function(v) S.ESP_Distance = v; notifyToggle("Distance Tags", v)
    if not v then for _, e in pairs(ESPPool) do e.distLabel.Visible = false end end end })
VisualsTab:CreateToggle({ Name = "Visible Check (Hide Behind Walls)", CurrentValue = false,
    Callback = function(v) S.VisCheck = v; notifyToggle("Visible Check", v) end })

VisualsTab:CreateSection("Color")

VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = THEME.ESPColor,
    Callback = function(c)
        S.ESPColor = c
        for _, esp in pairs(ESPPool) do
            esp.box.Color = c
            esp.tracer.Color = Color3.new(c.R*0.85, c.G*0.85, c.B*0.85)
            esp.nameLabel.Color = Color3.new(math.min(c.R+0.15,1), math.min(c.G+0.15,1), math.min(c.B+0.15,1))
            for _, bone in ipairs(esp.bones) do bone.Color = c end
            esp.radarDot.Color = c
            if esp.highlight then _safeCall(function() esp.highlight.FillColor = c end) end
        end
    end,
})

VisualsTab:CreateSection("Crosshair")

VisualsTab:CreateToggle({ Name = "Crosshair", CurrentValue = false,
    Callback = function(v) S.Crosshair = v; notifyToggle("Crosshair", v) end })
VisualsTab:CreateSlider({ Name = "Line Length", Range = {4, 20}, Increment = 1, CurrentValue = 8,
    Callback = function(v) S.XH_Size = v end })
VisualsTab:CreateSlider({ Name = "Gap", Range = {0, 10}, Increment = 1, CurrentValue = 4,
    Callback = function(v) S.XH_Gap = v end })

VisualsTab:CreateSection("Fullbright")

VisualsTab:CreateToggle({
    Name = "Fullbright (No Darkness)", CurrentValue = false,
    Callback = function(v) S.Fullbright = v; applyFullbright(v); notifyToggle("Fullbright", v) end,
})

VisualsTab:CreateSection("Alert")

VisualsTab:CreateToggle({ Name = "Enemy Proximity Alert", CurrentValue = false,
    Callback = function(v) S.EnemyAlert = v; notifyToggle("Enemy Alert", v) end })
VisualsTab:CreateSlider({ Name = "Alert Distance (m)", Range = {15, 80}, Increment = 5, CurrentValue = 40,
    Callback = function(v) S.EnemyAlertDist = v end })

VisualsTab:CreateSection("Radar")

VisualsTab:CreateToggle({ Name = "Radar", CurrentValue = false,
    Callback = function(v) S.Radar = v; notifyToggle("Radar", v) end })
VisualsTab:CreateSlider({ Name = "Radar Range (m)", Range = {40, 300}, Increment = 10, CurrentValue = 120,
    Callback = function(v) S.RadarRange = v end })
VisualsTab:CreateSlider({ Name = "Radar Size (px)", Range = {80, 200}, Increment = 10, CurrentValue = 130,
    Callback = function(v) S.RadarSize = v end })

VisualsTab:CreateSection("HUD")

VisualsTab:CreateToggle({ Name = "Player / Bot Counter", CurrentValue = false,
    Callback = function(v) S.PlayerBotHUD = v; notifyToggle("Player/Bot Counter", v) end })
VisualsTab:CreateToggle({ Name = "Kill / Death Counter", CurrentValue = false,
    Callback = function(v) S.KillCounter = v; notifyToggle("Kill Counter", v) end })

-- TAB 4: GAMEPLAY -------------------------------------------
local GameplayTab = Window:CreateTab("Gameplay", "user")

GameplayTab:CreateSection("Weapon Modifiers")

GameplayTab:CreateToggle({ Name = "No Recoil", CurrentValue = false,
    Callback = function(v) S.NoRecoil = v; notifyToggle("No Recoil", v) end })
GameplayTab:CreateToggle({ Name = "No Spread", CurrentValue = false,
    Callback = function(v) S.NoSpread = v; notifyToggle("No Spread", v) end })
GameplayTab:CreateToggle({ Name = "Fast Reload", CurrentValue = false,
    Callback = function(v) S.FastReload = v; notifyToggle("Fast Reload", v) end })
GameplayTab:CreateToggle({ Name = "Infinite Ammo", CurrentValue = false,
    Callback = function(v) S.InfAmmo = v; notifyToggle("Infinite Ammo", v) end })

GameplayTab:CreateSection("Speed")

GameplayTab:CreateToggle({ Name = "Speed Boost", CurrentValue = false,
    Callback = function(v)
        S.Speed = v
        if not v then
            _safeCall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
        end
        notifyToggle("Speed Boost", v)
    end })
GameplayTab:CreateSlider({
    Name = "Speed Value (WalkSpeed)",
    Range = {16, 200}, Increment = 2, CurrentValue = 16,
    Callback = function(v) S.SpeedVal = v end,
})

GameplayTab:CreateSection("Jump")

GameplayTab:CreateToggle({ Name = "Jump Boost", CurrentValue = false,
    Callback = debounced("Jump", function(v)
        S.Jump = v
        if v then
            -- FIX 6: Apply JumpPower in toggle callback (not per-frame)
            _safeCall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.UseJumpPower = true
                    hum.JumpPower = S.JumpVal
                end
            end)
        else
            _safeCall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.UseJumpPower = true; hum.JumpPower = 50 end
            end)
        end
        notifyToggle("Jump Boost", v)
    end) })
GameplayTab:CreateSlider({ Name = "Jump Power", Range = {50, 250}, Increment = 5, CurrentValue = 50,
    Callback = function(v) S.JumpVal = v end })

GameplayTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false,
    Callback = function(v) S.InfJump = v; notifyToggle("Infinite Jump", v) end,
})

GameplayTab:CreateToggle({ Name = "Auto Strafe", CurrentValue = false,
    Callback = function(v) S.AutoStrafe = v; notifyToggle("Auto Strafe", v) end })

GameplayTab:CreateToggle({
    Name = "No Fall Damage", CurrentValue = false,
    Callback = function(v)
        S.NoFallDmg = v; notifyToggle("No Fall Damage", v)
        if v then
            _safeCall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                end
            end)
        end
    end,
})

GameplayTab:CreateSection("Respawn")

GameplayTab:CreateToggle({
    Name = "Fast Respawn", CurrentValue = false,
    Callback = function(v) S.FastRespawn = v; notifyToggle("Fast Respawn", v) end,
})

GameplayTab:CreateSection("Mobile Tools")

GameplayTab:CreateSlider({
    Name = "Jump Button Scale (1x to 3x)",
    Range = {1, 3}, Increment = 0.5, CurrentValue = 1,
    Callback = function(v)
        S.JumpScale = v; scaleJumpButton(v)
        notify("Jump Scale", v .. "x", 3)
    end,
})

GameplayTab:CreateSection("Fly")

GameplayTab:CreateToggle({
    Name = "Fly", CurrentValue = false,
    Callback = function(v)
        S.Fly = v
        if v then startFly(); notify("Fly ON", "WASD to move, Space=Up, Shift=Down", 3)
        else stopFly(); notify("Fly OFF", "Disabled", 3) end
    end,
})

GameplayTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200}, Increment = 10, CurrentValue = 50,
    Callback = function(v) S.FlySpeed = v end,
})

GameplayTab:CreateSection("Noclip")

GameplayTab:CreateToggle({
    Name = "Noclip (Walk Through Walls)", CurrentValue = false,
    Callback = function(v)
        S.Noclip = v
        if v then enableNoclip() else disableNoclip() end
        notifyToggle("Noclip", v)
    end,
})

GameplayTab:CreateSection("God Mode")

GameplayTab:CreateToggle({
    Name = "God Mode (Client-Side)", CurrentValue = false,
    Callback = function(v)
        S.GodMode = v
        if v then enableGodMode() else disableGodMode() end
        notifyToggle("God Mode", v)
    end,
})

GameplayTab:CreateSection("Teleport")

local _tpTarget = ""
GameplayTab:CreateInput({
    Name = "Player Name",
    PlaceholderText = "Enter player name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(t) _tpTarget = t end,
})

GameplayTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if _tpTarget ~= "" then teleportToPlayer(_tpTarget)
        else notify("Error", "Enter a player name first.", 3) end
    end,
})

GameplayTab:CreateButton({
    Name = "Teleport to Nearest Player",
    Callback = function() teleportToNearest() end,
})

-- TAB 5: PERFORMANCE ----------------------------------------
local PerfTab = Window:CreateTab("Performance", "zap")

PerfTab:CreateSection("-- Omega AntiLag Engine --")
_safeCall(function()
    if PerfTab.CreateLabel then
        PerfTab:CreateLabel("Smart filter protects DamageBrick, Lava, Kill parts.")
    else
        PerfTab:CreateParagraph({Title = "Note", Content = "Smart filter protects DamageBrick, Lava, Kill parts."})
    end
end)

PerfTab:CreateToggle({
    Name = "Omega FPS Boost (SmoothPlastic + No Shadows)", CurrentValue = false,
    Callback = function(v)
        S.FPSBoost = v
        if v then task.spawn(runOmegaFPS); enableFPSListener() else disableFPSListener() end
        notifyToggle("Omega FPS Boost", v)
    end,
})

PerfTab:CreateSection("Lighting")

PerfTab:CreateToggle({
    Name = "Lighting Ultra", CurrentValue = false,
    Callback = function(v)
        S.LightingUltra = v
        if v then applyLightingUltra() else restoreLighting() end
        notifyToggle("Lighting Ultra", v)
    end,
})

PerfTab:CreateSection("Purge")

PerfTab:CreateToggle({
    Name = "Texture Purge", CurrentValue = false,
    Callback = function(v)
        S.TexturePurge = v
        if v then local n = purgeTextures(); enableTexListener(); notify("Textures Purged", n .. " hidden.", 3)
        else disableTexListener(); notify("Texture Purge OFF", "Disabled", 3) end
    end,
})

PerfTab:CreateToggle({
    Name = "Particle Purge", CurrentValue = false,
    Callback = function(v)
        S.ParticlePurge = v
        if v then local n = purgeParticles(); notify("Particles Purged", n .. " disabled.", 3)
        else notify("Particle Purge OFF", "Disabled", 3) end
    end,
})

PerfTab:CreateToggle({
    Name = "Simplify Terrain", CurrentValue = false,
    Callback = function(v)
        S.TerrainSimple = v
        if v then simplifyTerrain(); notify("Terrain Simplified", "Water and decoration disabled", 3) end
    end,
})

PerfTab:CreateSection("Manual Actions")

PerfTab:CreateButton({
    Name = "Destroy All Decals",
    Callback = function()
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            _safeCall(function() if d:IsA("Decal") or d:IsA("Texture") then d:Destroy(); n = n+1 end end)
        end
        notify("Done", n .. " decals destroyed.", 3)
    end,
})

PerfTab:CreateButton({
    Name = "Remove SurfaceAppearances",
    Callback = function()
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            _safeCall(function() if d:IsA("SurfaceAppearance") or d:IsA("SpecialMesh") then d.Parent = nil; n = n+1 end end)
        end
        notify("Done", n .. " removed.", 3)
    end,
})

PerfTab:CreateButton({
    Name = "Set Rendering to Level 1",
    Callback = function()
        _safeCall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        notify("Rendering", "Quality set to minimum.", 3)
    end,
})

-- TAB 6: SERVER ---------------------------------------------
local ServerTab = Window:CreateTab("Server", "globe")

ServerTab:CreateSection("Find Smallest Server")

ServerTab:CreateButton({
    Name = "Find Smallest and Join",
    Callback = function() task.spawn(function() findSmallestAndJoin(game.PlaceId) end) end,
})

ServerTab:CreateButton({
    Name = "Scan Servers (Preview)",
    Callback = function()
        task.spawn(function()
            if serverFetching then notify("Wait", "Scanning...", 2) return end
            notify("Scanning...", "", 2)
            local list = fetchSmallestServers(game.PlaceId)
            if not list or #list == 0 then notify("No Servers", "", 3) return end
            local msg = #list .. " servers\n"
            for i = 1, math.min(#list, 5) do
                msg = msg .. "#" .. i .. ": " .. list[i].playing .. "/" .. list[i].maxPlayers .. "\n"
            end
            notify("Scan Done", msg, 8)
        end)
    end,
})

ServerTab:CreateSection("Custom Game")

local customPID = ""
ServerTab:CreateInput({
    Name = "Place ID",
    PlaceholderText = "e.g. 2753915549",
    RemoveTextAfterFocusLost = false,
    Callback = function(t) customPID = t end,
})

ServerTab:CreateButton({
    Name = "Find Smallest in Custom Game",
    Callback = function()
        local pid = tonumber(customPID)
        if not pid or pid <= 0 then notify("Invalid", "Enter a valid Place ID.", 3) return end
        task.spawn(function() findSmallestAndJoin(pid) end)
    end,
})

ServerTab:CreateSection("Quick Join (from last scan)")

for i = 1, 5 do
    ServerTab:CreateButton({
        Name = "Server #" .. i,
        Callback = function()
            if #S.ServerList < i then notify("Scan First", "Not enough servers.", 3) return end
            local sv = S.ServerList[i]
            notify("Server #" .. i, sv.playing .. "/" .. sv.maxPlayers, 2)
            task.spawn(function() teleportToServer(game.PlaceId, sv.id) end)
        end,
    })
end

ServerTab:CreateSection("Hop / Rejoin")

ServerTab:CreateButton({
    Name = "Server Hop (Smallest)",
    Callback = function() task.spawn(function() findSmallestAndJoin(game.PlaceId) end) end,
})

ServerTab:CreateButton({
    Name = "Rejoin Current Server",
    Callback = function()
        notify("Rejoining...", "", 3)
        task.wait(0.5)
        _safeCall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    end,
})

ServerTab:CreateSection("Auto Hop")

ServerTab:CreateToggle({
    Name = "Auto Hop if Too Many Players", CurrentValue = false,
    Callback = function(v)
        S.AutoHop = v; notifyToggle("Auto Hop", v)
    end,
})

ServerTab:CreateSlider({
    Name = "Auto Hop Threshold",
    Range = {2, 30}, Increment = 1, CurrentValue = 6,
    Callback = function(v) S.AutoHopMax = v end,
})

ServerTab:CreateSection("Utility")

ServerTab:CreateToggle({
    Name = "Anti-AFK", CurrentValue = false,
    Callback = function(v) S.AntiAFK = v; notifyToggle("Anti-AFK", v) end,
})

ServerTab:CreateButton({
    Name = "Copy Job ID",
    Callback = function()
        _safeCall(function()
            if setclipboard then setclipboard(game.JobId); notify("Copied", "Job ID copied", 3)
            elseif toclipboard then toclipboard(game.JobId); notify("Copied", "Job ID copied", 3)
            else notify("Error", "Clipboard not supported.", 3) end
        end)
    end,
})

ServerTab:CreateButton({
    Name = "Show Player List",
    Callback = function()
        local msg = ""
        for i, p in ipairs(Players:GetPlayers()) do
            msg = msg .. i .. ". " .. p.Name .. "\n"
        end
        notify("Players (" .. #Players:GetPlayers() .. ")", msg, 10)
    end,
})

ServerTab:CreateParagraph({
    Title = "Server Info",
    Content = "Place: " .. tostring(game.PlaceId)
        .. "\nJob: " .. string.sub(game.JobId, 1, 20) .. "..."
        .. "\nPlayers: " .. #Players:GetPlayers(),
})

-- TAB 7: CREDITS --------------------------------------------
local CreditsTab = Window:CreateTab("Credits", "heart")

CreditsTab:CreateSection("Amethyst Ultimate V3.0")
CreditsTab:CreateParagraph({
    Title = "About",
    Content = "Professional-Grade Universal Mod Menu\n\n"
        .. "Features:\n"
        .. "- Deep Amethyst Purple Theme\n"
        .. "- TweenService Liquid Animations\n"
        .. "- Omega AntiLag Engine\n"
        .. "- Aimbot + Aimlock (Camera.CFrame)\n"
        .. "- Amethyst Box ESP + Tracers\n"
        .. "- Mobile-First Design\n\n"
        .. "UI Library: Rayfield by Sirius Software\n"
        .. "Theme: Custom Deep Amethyst Purple\n"
        .. "Version: 3.0.0",
})

CreditsTab:CreateSection("Owner")
CreditsTab:CreateParagraph({
    Title = "Lutfie kenape ek",
    Content = "Script owner and creator.\nAll rights reserved.",
})


-- FIX 26: Silent Mode toggle (added to Server tab utility section)
ServerTab:CreateToggle({
    Name = "Silent Mode (No Notifications)", CurrentValue = false,
    Callback = debounced("SilentMode", function(v)
        S.SilentMode = v
    end),
})

-- ============================================================
-- MOBILE: FLOATING TOGGLE BUTTON (custom drag, TweenService)
-- ============================================================
_safeCall(function()
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "AmethystToggleV3"
    toggleGui.ResetOnSpawn = false
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toggleGui.DisplayOrder = 1000
    local _tgOk = _safeCall(function() toggleGui.Parent = CoreGui end)
    if not _tgOk then
        _safeCall(function() toggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
    end

    local btnSize = IS_MOBILE and 54 or 42

    -- Glow frame behind button
    local glowFrame = Instance.new("Frame")
    glowFrame.Size = UDim2.new(0, btnSize + 12, 0, btnSize + 12)
    glowFrame.Position = UDim2.new(0, 4, 0.4, -6)
    glowFrame.BackgroundColor3 = THEME.Accent
    glowFrame.BackgroundTransparency = 0.7
    glowFrame.BorderSizePixel = 0
    glowFrame.ZIndex = 99
    glowFrame.Parent = toggleGui
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0.5, 0)
    glowCorner.Parent = glowFrame

    -- Main button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    toggleBtn.Position = UDim2.new(0, 10, 0.4, 0)
    toggleBtn.BackgroundColor3 = THEME.Main
    toggleBtn.TextColor3 = THEME.Accent

    -- Amethyst gradient overlay on toggle button
    local toggleGrad = Instance.new("UIGradient")
    toggleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 20, 70)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 40, 140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 70)),
    })
    toggleGrad.Rotation = 135
    toggleGrad.Parent = toggleBtn
    toggleBtn.Text = "A"
    toggleBtn.TextSize = IS_MOBILE and 24 or 18
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel = 0
    toggleBtn.ZIndex = 100
    toggleBtn.Parent = toggleGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = toggleBtn

    -- Gradient overlay
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 40, 180)),
    })
    gradient.Rotation = 135
    gradient.Parent = toggleBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.Accent
    stroke.Thickness = 2
    stroke.Parent = toggleBtn

    -- Custom drag system using UserInputService (100% mobile + PC)
    local dragging = false
    local dragStart, startBtnPos, startGlowPos
    local totalDragDist = 0

    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startBtnPos = toggleBtn.Position
            startGlowPos = glowFrame.Position
            totalDragDist = 0
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            totalDragDist = totalDragDist + delta.Magnitude
            toggleBtn.Position = UDim2.new(
                startBtnPos.X.Scale, startBtnPos.X.Offset + delta.X,
                startBtnPos.Y.Scale, startBtnPos.Y.Offset + delta.Y
            )
            glowFrame.Position = UDim2.new(
                startGlowPos.X.Scale, startGlowPos.X.Offset + delta.X,
                startGlowPos.Y.Scale, startGlowPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Click to toggle menu visibility (with TweenService animation)
    local menuVisible = true
    toggleBtn.MouseButton1Click:Connect(function()
        if totalDragDist > 10 then return end -- was a drag, not click
        menuVisible = not menuVisible

        -- Animate button press
        tweenProp(toggleBtn, {Size = UDim2.new(0, btnSize - 6, 0, btnSize - 6)}, TI_FAST)
        task.delay(0.15, function()
            tweenProp(toggleBtn, {Size = UDim2.new(0, btnSize, 0, btnSize)}, TI_BOUNCE)
        end)

        -- Toggle Rayfield UI visibility
        _safeCall(function()
            -- Method 1: Rayfield:ToggleUI()
            local togOk = _safeCall(function() Rayfield:ToggleUI() end)
            if not togOk then
                -- Method 2: Rayfield.Toggle()
                local togOk2 = _safeCall(function() Rayfield:Toggle() end)
                if not togOk2 then
                    -- Method 3: Direct GUI manipulation
                    _safeCall(function()
                        for _, gui in ipairs(CoreGui:GetChildren()) do
                            if gui:IsA("ScreenGui") and (gui.Name:find("Rayfield") or gui.Name:find("rayfield")) then
                                gui.Enabled = menuVisible
                            end
                        end
                    end)
                    _safeCall(function()
                        for _, gui in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
                            if gui:IsA("ScreenGui") and (gui.Name:find("Rayfield") or gui.Name:find("rayfield")) then
                                gui.Enabled = menuVisible
                            end
                        end
                    end)
                end
            end
        end)

        -- Visual feedback
        if menuVisible then
            tweenProp(toggleBtn, {BackgroundColor3 = THEME.Main}, TI_SMOOTH)
            tweenProp(toggleBtn, {TextColor3 = THEME.Accent}, TI_SMOOTH)
            tweenProp(glowFrame, {BackgroundTransparency = 0.7}, TI_SMOOTH)
        else
            tweenProp(toggleBtn, {BackgroundColor3 = Color3.fromRGB(30, 12, 45)}, TI_SMOOTH)
            tweenProp(toggleBtn, {TextColor3 = THEME.AccentDim}, TI_SMOOTH)
            tweenProp(glowFrame, {BackgroundTransparency = 0.95}, TI_SMOOTH)
        end
    end)

    -- Pulse glow animation
    tweenProp(glowFrame, {BackgroundTransparency = 0.85}, TI_PULSE)

    -- FIX 14: Stroke pulse via TweenService (replaces manual while loop)
    stroke.Color = Color3.fromRGB(120, 60, 185)
    TweenService:Create(stroke, TI_PULSE, {Color = Color3.fromRGB(180, 100, 255)}):Play()

    -- Auto-scale mobile jump button
    if IS_MOBILE then
        task.spawn(function()
            task.wait(2)
            scaleJumpButton(1.3)
        end)
    end
end)

-- ============================================================
-- HEARTBEAT MOD LOOP (fights server-side resets every physics frame)
-- Runs on Heartbeat (after physics) for WalkSpeed/JumpPower persistence
-- ============================================================
local _modChangedConns = {}

local function hookCharacterModLoop(char)
    -- Disconnect old Changed listeners
    for _, conn in ipairs(_modChangedConns) do
        _safeCall(function() conn:Disconnect() end)
    end
    _modChangedConns = {}

    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    -- Block game from resetting WalkSpeed
    table.insert(_modChangedConns, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if S.Speed and hum.WalkSpeed ~= S.SpeedVal then
            hum.WalkSpeed = S.SpeedVal
        end
    end))

    -- Block game from resetting JumpPower
    table.insert(_modChangedConns, hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if S.Jump and hum.JumpPower ~= S.JumpVal then
            hum.UseJumpPower = true
            hum.JumpPower = S.JumpVal
        end
    end))

    -- Block game from disabling UseJumpPower
    table.insert(_modChangedConns, hum:GetPropertyChangedSignal("UseJumpPower"):Connect(function()
        if S.Jump and not hum.UseJumpPower then
            hum.UseJumpPower = true
        end
    end))
end

-- Hook current character
task.spawn(function()
    local char = LocalPlayer.Character
    if char then hookCharacterModLoop(char) end
end)

-- Re-hook on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.defer(function()
        hookCharacterModLoop(char)
    end)
end)

-- (WalkSpeed/JumpPower persistence merged into consolidated Heartbeat below)

-- ============================================================
-- CONSOLIDATED HEARTBEAT LOOP (single connection)
-- ============================================================
-- Merges: mod persistence, combat calculations, anti-AFK, auto-hop.
-- One Heartbeat connection reduces engine ↔ script overhead and
-- guarantees deterministic execution order every physics frame.
-- ============================================================
local _antiAFKTimer = 0
local _autoHopTimer = 0

track(RunService.Heartbeat:Connect(function(dt)
    local now = tick()

    -- ── [1] WalkSpeed / JumpPower persistence ────────────────────
    -- Fights server-side resets every physics frame.
    _safeCall(function()
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if S.Speed and hum.WalkSpeed ~= S.SpeedVal then
            hum.WalkSpeed = S.SpeedVal
        end
        if S.Jump then
            if not hum.UseJumpPower then hum.UseJumpPower = true end
            if hum.JumpPower ~= S.JumpVal then hum.JumpPower = S.JumpVal end
        end
    end)

    -- ── [2] Auto Strafe — FIX 3: fixed (no exponential velocity)
    if S.AutoStrafe then _safeCall(function()
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.MoveDirection.Magnitude > 0 then
            local v = root.AssemblyLinearVelocity
            local strafeSpeed = S.SpeedVal * 0.6
            local dir = hum.MoveDirection
            root.AssemblyLinearVelocity = Vector3.new(
                dir.X * strafeSpeed, v.Y, dir.Z * strafeSpeed
            )
        end
    end) end

    -- ── [3] No fall damage
    if S.NoFallDmg then _safeCall(function()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local vel = root.AssemblyLinearVelocity
            if vel.Y < -80 then
                root.AssemblyLinearVelocity = Vector3.new(vel.X, -80, vel.Z)
            end
        end
    end) end

    -- ── [4] TriggerBot (calculation, not drawing)
    if S.TriggerBot then _safeCall(function()
        local vp = Camera.ViewportSize
        local ray = Camera:ScreenPointToRay(vp.X*0.5, vp.Y*0.5)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result and result.Instance then
            local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
            local hitP = hitChar and Players:GetPlayerFromCharacter(hitChar)
            if hitP and hitP ~= LocalPlayer then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then _safeCall(function() tool:Activate() end) end
            end
        end
    end) end

    -- ── [5] Kill Aura (calculation)
    _safeCall(function() updateKillAura(now) end)

    -- ── [6] Weapon Mods (calculation)
    if S.NoRecoil or S.NoSpread or S.FastReload or S.InfAmmo then
        _safeCall(function() applyWeaponMods(now) end)
    end

    -- ── [7] Anti-AFK jump timer ──────────────────────────────────
    _antiAFKTimer = _antiAFKTimer + dt
    if _antiAFKTimer >= _G.Config.AntiAFKInterval then
        _antiAFKTimer = 0
        if S.AntiAFK then
            _safeCall(function()
                local hum = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Jump = true end
            end)
        end
    end

    -- ── [8] Auto Hop timer ───────────────────────────────────────
    _autoHopTimer = _autoHopTimer + dt
    if _autoHopTimer >= _G.Config.AutoHopInterval then
        _autoHopTimer = 0
        if S.AutoHop then
            local count = #Players:GetPlayers()
            if count > S.AutoHopMax then
                notify("Auto Hop", count .. " players (max " .. S.AutoHopMax .. "). Hopping...", 4)
                task.delay(2, function()
                    _safeCall(function() findSmallestAndJoin(game.PlaceId) end)
                end)
            end
        end
    end
end))

-- ============================================================
-- MAIN RENDER LOOP — FIX 4 (delta), 10 (drawing only), 11 (ESP throttle)
-- ============================================================
local _espThrottle = 0
track(RunService.RenderStepped:Connect(function(delta) -- FIX 4: delta param
    local now = tick()

    -- Speed CFrame supplement for values above 100 (visual movement)
    if S.Speed then _safeCall(function()
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = S.SpeedVal
            -- CFrame supplement for values above 100 (physics starts failing)
            if S.SpeedVal > 100 and root and hum.MoveDirection.Magnitude > 0 then
                local extra = (S.SpeedVal - 100) * delta * 0.5  -- FIX 4: delta-corrected
                root.CFrame = root.CFrame + (hum.MoveDirection * extra)
            end
        end
    end) end

    -- FIX 6: JumpPower removed from per-frame render loop
    -- (applied in toggle callback + Heartbeat backup only)

    -- ESP — FIX 11: Throttled to max 60 FPS
    if now - _espThrottle >= _G.Config.ESPThrottle then
        _espThrottle = now
        _safeCall(function() updateESP(now) end)
    end

    -- Aimbot (Camera.CFrame + ClosestPlayer logic)
    if S.Aimbot then
        local target = getClosestEnemy(now)
        if target then
            local pc = PartCache[target]
            if pc then
                local aim = (S.AimPart == "Torso") and pc.torso or pc.head
                if aim then
                    local aimPos = aim.Position
                    if S.AimPredict and pc.root then
                        local vel = pc.root.AssemblyLinearVelocity
                        if vel and vel.Magnitude > _G.Config.AimPredictVelMin then -- FIX 8
                            aimPos = aimPos + vel * S.AimPredictStr
                        end
                    end
                    -- Section 4: Slight aim randomization (humanization)
                    local rand = _G.Config.AimHumanization
                    aimPos = aimPos + Vector3.new(
                        (math.random() - 0.5) * rand,
                        (math.random() - 0.5) * rand,
                        (math.random() - 0.5) * rand
                    )
                    -- Section 4: Smooth interpolation (lerp, not instant snap)
                    Camera.CFrame = Camera.CFrame:Lerp(
                        CFrame.new(Camera.CFrame.Position, aimPos),
                        1 / S.AimbotSmooth
                    )
                end
            end
        end
    elseif S.SilentAim then -- FIX 5: Only call when SilentAim active
        getClosestEnemy(now)
    end

    -- Drawing-only updates (FIX 10: kept in RenderStepped)
    _safeCall(updateCrosshair)
    _safeCall(updateFOV)
    _safeCall(function() updateRadar(now) end)
    _safeCall(function() updateEnemyAlert(now) end)
    _safeCall(function() updateHUDs(now) end)
end))

-- Infinite Jump handler
_safeCall(function()
    track(UserInputService.JumpRequest:Connect(function()
        if S.InfJump then
            _safeCall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end))
end)

-- ============================================================
-- BACKGROUND TASKS (event-driven, no polling loops)
-- ============================================================

-- Anti-AFK (VirtualUser + jump)
_safeCall(function()
    local vu = game:GetService("VirtualUser")
    track(LocalPlayer.Idled:Connect(function()
        if S.AntiAFK then
            _safeCall(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
        end
    end))
end)

-- (Anti-AFK jump timer merged into consolidated Heartbeat below)

-- (Auto Hop timer merged into consolidated Heartbeat below)

-- Teleport failure retry
_safeCall(function()
    track(TeleportService.TeleportInitFailed:Connect(function(player, result, msg)
        if player == LocalPlayer then
            notify("Teleport Failed", tostring(msg) .. "\nRetrying...", 4)
            task.wait(3)
            if #S.ServerList > 0 then
                _safeCall(function() teleportToServer(game.PlaceId, S.ServerList[1].id) end)
            end
        end
    end))
end)

-- ============================================================
-- CLEANUP REGISTRATION — FIX 15
-- ============================================================
_G.__AmethystCleanup = cleanupAll

-- ============================================================
-- LOADED
-- ============================================================
notify(
    "Amethyst Ultimate V3.0 Loaded",
    "Professional-Grade Universal Mod Menu\n"
    .. "7 Tabs | Deep Amethyst Theme | xpcall Error Logging\n"
    .. "Event-Driven ESP | Consolidated Heartbeat\n"
    .. "Premium UIStroke Glow | Modular Loader Ready\n"
    .. "Game: " .. tostring(game.PlaceId),
    6
)
