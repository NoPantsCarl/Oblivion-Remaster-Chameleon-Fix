local DELAY_MS = 2000
local hadChameleon = false

local function CleanupChameleonVisuals()
    local player = FindFirstOf("BP_OblivionPlayerCharacter_C")
    if not player or not player:IsValid() then return end

    local components = player:GetComponentsByClass(StaticFindObject("/Script/Engine.ActorComponent"))
    if not components then return end

    for _, comp in ipairs(components) do
        if comp and comp:IsValid() then
            local name = comp:GetFullName()
            if name:find("BP_effectChameleon") then
                if comp.SendVFXEndSignal then comp:SendVFXEndSignal() end
                comp:K2_DestroyComponent()
            end
        end
    end
end

LoopAsync(DELAY_MS, function()
    local player = FindFirstOf("BP_OblivionPlayerCharacter_C")
    if not player or not player:IsValid() then return end

    local activeEffects = player.ActiveMagicEffects
    if not activeEffects then
        if hadChameleon then
            CleanupChameleonVisuals()
            hadChameleon = false
        end
        return
    end

    local hasChameleon = false
    for _, effect in ipairs(activeEffects) do
        if effect and effect:IsValid() then
            local effectName = effect:GetFullName()
            if effectName:find("Chameleon") then
                hasChameleon = true
                break
            end
        end
    end

    -- If Chameleon just ended, trigger visual cleanup
    if hadChameleon and not hasChameleon then
        CleanupChameleonVisuals()
        hadChameleon = false
    elseif hasChameleon then
        hadChameleon = true
    end
end)
