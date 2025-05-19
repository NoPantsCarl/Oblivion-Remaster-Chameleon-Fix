-- ChameleonFix/scripts/main.lua

local DELAY_MS = 200
local hasHadChameleon = false

-- crude delay function using busy loop (confirmed working)
local function crude_delay()
    for i = 1, 2000000 do end
end

-- wait for TESSync and DynamicForms
while true do
    local syncModel = StaticFindObject("/Script/Oblivion.TESSync")
    if syncModel and syncModel:IsValid() then
        local dynamicForms = syncModel.DynamicForms
        if dynamicForms and dynamicForms:IsValid() then
            print("[ChameleonFix] TESSync and DynamicForms are valid!")
            break
        end
    end
    print("[ChameleonFix] Waiting for TESSync...")
    crude_delay()
end

-- Begin chameleon monitor loop
while true do
    local player = StaticFindObject("/Game/OblivionPlayerCharacterBP.OblivionPlayerCharacterBP_C")
    if player and player:IsValid() then
        local effects = player:GetActiveMagicEffects()
        local hasChameleonNow = false

        for i = 0, effects:Num() - 1 do
            local effect = effects:Get(i)
            if effect and effect:IsValid() then
                local name = effect:GetName():ToString()
                if name:find("Chameleon") then
                    hasChameleonNow = true
                    break
                end
            end
        end

        if hasHadChameleon and not hasChameleonNow then
            local fx = StaticFindObject("/Game/Forms/miscellaneous/effectshader/particularcases/BP_effectChameleon.Default__BP_effectChameleon_C")
            if fx and fx:IsValid() then
                fx:EndEffect()
                print("[ChameleonFix] Ended lingering Chameleon effect.")
            end
            hasHadChameleon = false
        elseif hasChameleonNow then
            hasHadChameleon = true
        end
    end

    crude_delay()
end
