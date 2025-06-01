local key = "Nine"
local keyPressed = false

local function DestroyChameleonVisuals()
    print("[ChameleonFix] Searching for BPCI_StatusEffect_Chameleon_C actors...")

    local count = 0
    local actors = FindAllOf("BPCI_StatusEffect_Chameleon_C")

    for _, actor in ipairs(actors or {}) do
        if actor and actor:IsValid() then
            local name = actor:GetFullName()
            print("[ChameleonFix] Processing: " .. name)

            -- Access NiagaraComponent
            local niagara = actor["StatusEffect VFX"]
            if niagara and niagara:IsValid() then
                print("[ChameleonFix] Found NiagaraComponent 'StatusEffect VFX' — resetting system.")
                niagara:SetVisibility(false, true)
                niagara:Deactivate()
                niagara:ResetSystem()
            else
                print("[ChameleonFix] NiagaraComponent 'StatusEffect VFX' not found or invalid.")
            end

            -- Call known working methods with nil guards
            if actor.VStatusEffectTarget_OnTextureEffectStop then
                print("[ChameleonFix] Calling VStatusEffectTarget_OnTextureEffectStop...")
                pcall(function() actor:VStatusEffectTarget_OnTextureEffectStop() end)
            end
            if actor.Pawn_OnTextureEffectStop then
                print("[ChameleonFix] Calling Pawn_OnTextureEffectStop...")
                pcall(function() actor:Pawn_OnTextureEffectStop() end)
            end
            if actor.OnStatusEffectEnd then
                print("[ChameleonFix] Calling OnStatusEffectEnd...")
                pcall(function() actor:OnStatusEffectEnd() end)
            end
            if actor.RemoveStatusEffect then
                print("[ChameleonFix] Calling RemoveStatusEffect...")
                pcall(function() actor:RemoveStatusEffect() end)
            end

            actor:K2_DestroyActor()
            count = count + 1
        end
    end

    print("[ChameleonFix] Total actors destroyed: " .. tostring(count))

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