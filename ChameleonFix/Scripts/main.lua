local key = "Nine"
local keyPressed = false

local function DestroyChameleonVisuals()
    print("[ChameleonFix] Searching for BPCI_StatusEffect_Chameleon_C actors...")

    local count = 0
    local actors = FindAllOf("BPCI_StatusEffect_Chameleon_C")

    for _, actor in ipairs(actors or {}) do
        if actor and actor:IsValid() then
            local name = actor:GetFullName()
            print("[ChameleonFix] Destroying: " .. name)
            actor:K2_DestroyActor()
            count = count + 1
        end
    end

    print("[ChameleonFix] Total actors destroyed: " .. tostring(count))

    -- Attempt to refresh appearance via CharacterAppearancePairingComponent
    local player = FindFirstOf("BP_OblivionPlayerCharacter_C")
    if player and player:IsValid() then
        local comp = player.CharacterAppearancePairingComponent
        if comp and comp:IsValid() then
            print("[ChameleonFix] Calling RefreshCharacterAppearance...")
            comp:RefreshCharacterAppearance()
        else
            print("[ChameleonFix] CharacterAppearancePairingComponent not found or invalid.")
        end
    else
        print("[ChameleonFix] Player not found or invalid.")
    end
end

RegisterHook("/Script/Altar.VMainMenuViewModel:LoadInstanceOfLevels", function()
    RegisterHook("/Game/Dev/Controllers/BP_AltarPlayerController.BP_AltarPlayerController_C:InpActEvt_AnyKey_K2Node_InputKeyEvent_1", function(_, Key)
        if Key:get().KeyName:ToString() ~= key then return end
        if not keyPressed then
            DestroyChameleonVisuals()
        end
        keyPressed = not keyPressed
    end)
end)
