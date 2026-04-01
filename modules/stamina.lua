local Logger = ...

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local mathClamp = math.clamp

local Stamina = {}

local Hook = {
    Active = false,
    OldNamecall = nil,
    WriteLoopConn = nil,
    CharConn = nil,
    FakeStamina = 100,
    LastRealStamina = 100,
    CachedChar = nil,
    Bypass = false,
}

local function getRealAttribute(inst, attr)
    Hook.Bypass = true
    local ok, val = pcall(function()
        return inst:GetAttribute(attr)
    end)
    Hook.Bypass = false
    return ok and val or nil
end

local function refreshChar()
    Hook.CachedChar = LocalPlayer.Character
    if Hook.CachedChar then
        Hook.FakeStamina = getRealAttribute(Hook.CachedChar, "MaxStamina") or 100
        Hook.LastRealStamina = getRealAttribute(Hook.CachedChar, "Stamina") or 100
    end
end

function Stamina.enable(settings, state)
    if Hook.Active then return end

    refreshChar()
    if not Hook.CachedChar then return end

    Hook.CharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        Hook.CachedChar = newChar
        task.wait(1)
        Hook.FakeStamina = getRealAttribute(newChar, "MaxStamina") or 100
        Hook.LastRealStamina = getRealAttribute(newChar, "Stamina") or 100
    end)
    state.addCoreConnection(Hook.CharConn)

    -- Primary: hook __namecall to intercept char:GetAttribute("Stamina")
    -- This is the path Roblox uses for method calls (: syntax)
    local hookOk = pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if Hook.Bypass then
                return old(self, ...)
            end

            local method = getnamecallmethod()
            if method ~= "GetAttribute" then
                return old(self, ...)
            end

            local cachedChar = Hook.CachedChar
            if not cachedChar or self ~= cachedChar then
                return old(self, ...)
            end

            local attrName = ...

            if settings.InfStamina and attrName == "Stamina" then
                if settings.CustomMaxStamina then
                    return settings.MaxStaminaValue
                end
                return old(self, "MaxStamina") or 100
            end

            if settings.CustomDrain and not settings.InfStamina and attrName == "Stamina" then
                local realStamina = old(self, ...)
                local maxStam = settings.CustomMaxStamina and settings.MaxStaminaValue or (old(self, "MaxStamina") or 100)

                if realStamina ~= Hook.LastRealStamina then
                    local serverDrain = Hook.LastRealStamina - realStamina
                    if serverDrain > 0 then
                        Hook.FakeStamina = mathClamp(Hook.FakeStamina - serverDrain * (settings.DrainRate / 100), 0, maxStam)
                    else
                        Hook.FakeStamina = mathClamp(Hook.FakeStamina - serverDrain, 0, maxStam)
                    end
                    Hook.LastRealStamina = realStamina
                end
                return Hook.FakeStamina
            end

            if settings.CustomMaxStamina and attrName == "MaxStamina" then
                return settings.MaxStaminaValue
            end

            return old(self, ...)
        end))
        Hook.OldNamecall = old
    end)

    if hookOk then
        Logger.log("Stamina namecall hook enabled")
    else
        Logger.log("hookmetamethod not available, using SetAttribute fallback only")
    end

    -- Secondary: write-back loop that continuously forces stamina attribute
    -- Covers edge cases where game reads attribute via signals or cached values
    Hook.WriteLoopConn = RunService.Heartbeat:Connect(function()
        local char = Hook.CachedChar
        if not char then return end

        pcall(function()
            if settings.InfStamina then
                local maxStam = settings.CustomMaxStamina and settings.MaxStaminaValue or (getRealAttribute(char, "MaxStamina") or 100)
                char:SetAttribute("Stamina", maxStam)
            end
            if settings.CustomMaxStamina then
                char:SetAttribute("MaxStamina", settings.MaxStaminaValue)
            end
        end)
    end)
    state.addCoreConnection(Hook.WriteLoopConn)

    Hook.Active = true
    Logger.log("Stamina system enabled")
end

function Stamina.disable()
    if not Hook.Active then return end

    if Hook.OldNamecall then
        pcall(function()
            hookmetamethod(game, "__namecall", Hook.OldNamecall)
        end)
        Hook.OldNamecall = nil
    end

    if Hook.WriteLoopConn then
        Hook.WriteLoopConn:Disconnect()
        Hook.WriteLoopConn = nil
    end

    if Hook.CharConn then
        Hook.CharConn:Disconnect()
        Hook.CharConn = nil
    end

    Hook.Active = false
    Hook.Bypass = false
    Logger.log("Stamina system disabled")
end

function Stamina.isActive()
    return Hook.Active
end

return Stamina
