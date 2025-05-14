local DELAY_MS = 2000
local CHML_FORMID = 0x0008185C
local CHML2_FORMID = 0x4C6E53FE
local INVS_FORMID = 0x00080BE5

local hadChameleon = false

local function GetPlayer()
    return FindFirstOf("BP_OblivionPlayerCharacter_C")
end

-- Safely check if any form in TESSync.DynamicForms is a Chameleon effect
local function HasChameleonActive()
    local forms = TESSync and TESSync.DynamicForms
    if not forms then return false end

    for _, form in pairs(forms) do
        if form and form.GetFormID and type(form.GetFormID) == "function" then
            local id = form:GetFormID()
            if id == CHML_FORMID or id == CHML2_FORMID or id == INVS_FORMID then
                return true
            end
        end
    end
    return false
end

-- Removes stuck Chameleon visuals
local function RemoveChameleonVisuals(player)
    if not player then return end

    if player.SendVFXEndSignal then
        player:SendVFXEndSignal("CHML") -- Try tag cleanup
        player:SendVFXEndSignal("BP_effectChameleon") -- Backup name match
    end

    -- Clean up lingering visual components
    local comps = player:GetComponents()
    for _, comp in ipairs(comps or {}) do
        if comp and comp:IsValid() then
            local name = comp:GetFullName()
            if name:find("Chameleon") or name:find("BP_effectChameleon") then
                if comp.SendVFXEndSignal then comp:SendVFXEndSignal() end
                comp:K2_DestroyComponent()
            end
        end
    end
end

-- Main loop
LoopAsync(DELAY_MS, function()
    local player = GetPlayer()
    if not player then return end

    if HasChameleonActive() then
        hadChameleon = true
    elseif hadChameleon then
        RemoveChameleonVisuals(player)
        hadChameleon = false
    end
end)
