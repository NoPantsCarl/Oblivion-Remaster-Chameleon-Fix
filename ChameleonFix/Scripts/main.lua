local key = "Nine"
local keyPressed = false

local function DestroyChameleonVisuals()
    print("[ChameleonFix] Searching for BPCI_StatusEffect_Chameleon_C actors...")

    local count = 0
    local actors = FindAllOf("BPCI_StatusEffect_Chameleon_C")

    local player = FindFirstOf("BP_OblivionPlayerCharacter_C")
    if player and player:IsValid() then
        local statusComp = player.StatusEffectComponent or player.BPC_StatusEffect or player.BPC_Status
        if statusComp and statusComp:IsValid() then
            if statusComp.FinishedMinimumLifetime then
                print("[ChameleonFix] Calling FinishedMinimumLifetime on player’s UBPC_StatusEffect_C...")
                pcall(function() statusComp:FinishedMinimumLifetime() end)
            end

            print("[ChameleonFix] Calling RestoreOriginalMaterials...")
            pcall(function() statusComp:RestoreOriginalMaterials() end)

            print("[ChameleonFix] Calling Set_Fade_Value_On_All_Material_Switch_MIDs(0.0)...")
            pcall(function() statusComp:Set_Fade_Value_On_All_Material_Switch_MIDs(0.0) end)

        else
            print("[ChameleonFix] UBPC_StatusEffect_C not found or invalid.")
        end
    else
        print("[ChameleonFix] Player not found.")
    end

    for _, actor in ipairs(actors or {}) do
        if actor and actor:IsValid() then
            local name = actor:GetFullName()
            print("[ChameleonFix] Processing: " .. name)

            actor.PrimaryActorTick.bCanEverTick = false
            actor:SetActorTickEnabled(false)

            local niagara = actor["StatusEffect VFX"]
            if niagara and niagara:IsValid() then
                print("[ChameleonFix] Found NiagaraComponent 'StatusEffect VFX' — resetting system.")
                niagara:SetVisibility(false, true)
                niagara:Deactivate()
                niagara:ResetSystem()
            else
                print("[ChameleonFix] NiagaraComponent 'StatusEffect VFX' not found or invalid.")
            end

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

    if player and player:IsValid() then
        local comp = player.CharacterAppearancePairingComponent
        if comp and comp:IsValid() then
            print("[ChameleonFix] Calling RefreshCharacterAppearance...")
            comp:RefreshCharacterAppearance()
        else
            print("[ChameleonFix] CharacterAppearancePairingComponent not found or invalid.")
        end
    end
end

RegisterHook("/Script/Altar.VMainMenuViewModel:LoadInstanceOfLevels", function()
    RegisterHook("/Script/Engine.Actor:ReceiveBeginPlay", function(self)
        if not self or not self:IsValid() then return true end
        local name = self:GetFullName()
        if name:find("BPCI_StatusEffect_Chameleon_C") then
            print("[ChameleonFix] Auto-destroying BPCI_StatusEffect_Chameleon_C via Actor.ReceiveBeginPlay")

            self.PrimaryActorTick.bCanEverTick = false
            self:SetActorTickEnabled(false)

            local vfx = self["StatusEffect VFX"]
            if vfx and vfx:IsValid() then
                vfx:SetVisibility(false, true)
                vfx:Deactivate()
                vfx:ResetSystem()
            end

            pcall(function() self:K2_DestroyActor() end)
            return false
        end
        return true
    end)

    RegisterHook("/Game/Dev/Controllers/BP_AltarPlayerController.BP_AltarPlayerController_C:InpActEvt_AnyKey_K2Node_InputKeyEvent_1", function(_, Key)
        if Key:get().KeyName:ToString() ~= key then return end
        if not keyPressed then
            DestroyChameleonVisuals()
        end
        keyPressed = not keyPressed
    end)
end)
