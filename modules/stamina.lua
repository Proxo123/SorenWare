local Logger = ...

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local mathClamp = math.clamp

local Stamina = {}

local Hook = {
    Active = false,
    OldGetAttribute = nil,
    FakeStamina = 100,
    LastRealStamina = 100,
    CachedChar = nil,
}

local function refreshChar()
    Hook.CachedChar = LocalPlayer.Character
end

function Stamina.enable(settings, state)
    if Hook.Active then return end

    refreshChar()
    local char = Hook.CachedChar
    if not char then return end

    pcall(function()
        Hook.FakeStamina = char:GetAttribute("MaxStamina") or 100
        Hook.LastRealStamina = char:GetAttribute("Stamina") or 100
    end)

    local charConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        Hook.CachedChar = newChar
        task.wait(1)
        pcall(function()
            Hook.FakeStamina = newChar:GetAttribute("MaxStamina") or 100
            Hook.LastRealStamina = newChar:GetAttribute("Stamina") or 100
        end)
    end)
    state.addCoreConnection(charConn)

    local oldGetAttribute
    oldGetAttribute = hookfunction(char.GetAttribute, newcclosure(function(self, attrName, ...)
        local cachedChar = Hook.CachedChar
        if not cachedChar or self ~= cachedChar then
            return oldGetAttribute(self, attrName, ...)
        end

        if settings.InfStamina and attrName == "Stamina" then
            local maxStam = settings.CustomMaxStamina and settings.MaxStaminaValue or (oldGetAttribute(self, "MaxStamina") or 100)
            return maxStam
        end

        if settings.CustomDrain and not settings.InfStamina and attrName == "Stamina" then
            local realStamina = oldGetAttribute(self, attrName, ...)
            local maxStam = settings.CustomMaxStamina and settings.MaxStaminaValue or (oldGetAttribute(self, "MaxStamina") or 100)

            if realStamina ~= Hook.LastRealStamina then
                local serverDrain = Hook.LastRealStamina - realStamina
                if serverDrain > 0 then
                    local ourDrain = serverDrain * (settings.DrainRate / 100)
                    Hook.FakeStamina = mathClamp(Hook.FakeStamina - ourDrain, 0, maxStam)
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

        return oldGetAttribute(self, attrName, ...)
    end))

    Hook.OldGetAttribute = oldGetAttribute
    Hook.Active = true
    Logger.log("Stamina hook enabled")
end

function Stamina.disable()
    if not Hook.Active then return end

    if Hook.OldGetAttribute then
        pcall(function()
            hookfunction(Hook.CachedChar.GetAttribute, Hook.OldGetAttribute)
        end)
    end

    Hook.Active = false
    Hook.OldGetAttribute = nil
    Logger.log("Stamina hook disabled")
end

function Stamina.isActive()
    return Hook.Active
end

return Stamina
