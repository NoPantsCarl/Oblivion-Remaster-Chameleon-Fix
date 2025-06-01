# ChameleonFix – Oblivion Remastered

This mod and diagnostic reference focuses on identifying and cleaning up stuck Chameleon visual effects in Oblivion Remastered.


## Summary

The Chameleon visual effect in Oblivion Remastered can become permanently stuck when multiple instances overlap or are removed improperly. This is a rendering-level bug caused when the engine fails to call `OnTextureEffectStop`, leaving the Chameleon material applied permanently to the player.


## Confirmed Behavior

- The effect is applied using `BP_effectChameleon`, which spawns as `BPCI_StatusEffect_Chameleon_C`.
- The shader comes from `MIC_StatusEffect_Chameleon` and its variants.
- When the engine fails to clean up the shader, it remains visually baked into the player.
- `SendVFXEndSignal()` has no effect because no `AVMagicSpellVFX` instance is spawned.
- Destroying `BPCI_StatusEffect_Chameleon_C` will stop the effect's source actor but does not revert the shader.
- The only reliable way to track Chameleon gameplay state is via `ActorValuesPairingComponent:GetValue("Chameleon")`.
- `StatusEffectComponent` contains methods such as:
  - `RestoreOriginalMaterials()`
  - `Set_Fade_Value_On_All_Material_Switch_MIDs(0.0)`
  - `SetDitherScaleOnAllComponents()`
  - `Update_Color_Values_Of_MID()`
- `CharacterAppearancePairingComponent:RefreshCharacterAppearance()` may help visually reset the player's mesh.
- Lua access to mesh ignore lists (`Mesh_Ignore_List`) requires validation before looping.
- Spawning/cleaning up Chameleon blueprints mid-sneak state appears to be the leading cause of this bug.


## Working Cleanup Script

This removes the spawned Chameleon visual actor, though the baked shader may still remain:

```lua
for _, actor in ipairs(FindAllOf("BPCI_StatusEffect_Chameleon_C") or {}) do
    if actor and actor:IsValid() then
        actor:K2_DestroyActor()
    end
end
```
![ChameleonFix Cleanup Proof](https://i.postimg.cc/Y2zrdYP9/Capture.png)


## What I Have Learned So Far

- Chameleon visual bug is a base game engine-level issue, not specific to any mod.
- Stuck visuals occur when multiple Chameleon effects are added/removed quickly (especially mid-sneak).
- `SendVFXEndSignal()` exists in `VMagicSpellVFX` but fails silently via Lua in most cases.
- The Chameleon visual components are tied to Blueprints like `BP_effectChameleon` and shader tags like `CHML`, `CHML2`, `INVS`.
- UE4SS Lua can detect actor values and effect form IDs using `TESSync.DynamicForms` and `ActorValuesPairingComponent:GetValue()`.
- `FindComponentByClass` is not supported in the current UE4SS setup.
- `GetComponents()` + filtering by name like `"BP_effectChameleon"` is a viable method for attempting cleanup.
- Chameleon form IDs confirmed:
  - CHML  = 0x0008185C
  - CHML2 = 0x4C6E53FE
- UE4SS key input handling using `InpActEvt_AnyKey` works but is limited by game input bindings.
- `RegisterKeyBind()` requires integer key codes, not string names (e.g., use `57` for `Nine` key).
- Some components like `Mesh_Ignore_List` may appear valid in Blueprint but return `nil` or invalid in Lua.
- Attempting to call cleanup methods (`RestoreOriginalMaterials`, `Set_Fade_Value_On_All_Material_Switch_MIDs`) on invalid or incomplete effect states results in silent failure.
- Chameleon Blueprint visuals often need both actor destruction **and** material resets for full cleanup.


## What Has Worked So Far

- Tracking Chameleon gameplay effect via:
  `player.ActorValuesPairingComponent:GetValue("Chameleon")`
- Tracking Chameleon visual presence via:
  `TESSync.DynamicForms` and `GetFormID()` matching CHML/CHML2/INVS
- Executing cleanup logic only once after Chameleon ends (using `hadChameleon = true` flag).
- Using `LoopAsync()` or `ExecuteWithDelay()` to check player state on a timer.
- Finding and filtering player components by name to locate `BP_effectChameleon`.
- Calling `RestoreOriginalMaterials()`, `Set_Fade_Value_On_All_Material_Switch_MIDs(0.0)`, and `SetDitherScaleOnAllComponents()` on the player’s `StatusEffectComponent` after effect ends.
- Iterating and removing invalid mesh entries from `Mesh_Ignore_List` to avoid nil errors.
- Hooking `ReceiveBeginPlay` on `BPCI_StatusEffect_Chameleon_C` to clean up VFX and call `K2_DestroyActor()` early.
- Using `actor:K2_DestroyActor()` successfully removes active visual actors.


## What Has Not Worked So Far

- `FindComponentByClass` → results in a nil or method call error.
- `player.dispel 0x0008185C` → works for Bound Arrow, not for Chameleon.
- `K2_DestroyComponent()` alone → often fails to clear visuals.
- `SendVFXEndSignal()` on component or actor → fails silently or returns nullptr.
- `player.ActiveMagicEffects` in Lua → usually nil or unreliable.
- `TESSync.DynamicForms` alone → often empty or not yet populated during mod load.
- Any method relying on console prints/debug logs → doesn’t display anything.
- OBSE plugin approach so far has unresolved build and header issues.
- `RegisterKeyBind()` in Lua fails due to incorrect overload use.
- `StatusEffectComponent.Mesh_Ignore_List` is sometimes not a valid table (causes crashes if not checked).
- Trying to call functions like `Remove_Status_Effect_on_Component()` on nil mesh entries can crash the game.
- Attempting to clean visuals after they're already "baked" into the mesh still leaves ghost shaders active.


## Reproduction Steps

To reproduce the stuck Chameleon shader:
1. Equip multiple Chameleon-enchanted items (examples: `00027110`, `00049393`, `00091ab2`) back to back.
2. Remove them quickly or toggle sneak.
3. The Chameleon visual becomes permanently stuck.


## Visual Confirmation

This screenshot shows the condition when the shader remains on the player without any active effect actor:

![Bugged Shader Remains](https://i.postimg.cc/nVRv6by6/it-does-NOT-trigger-when-you-get-the-bug.png)


## Next Steps

- Investigate Blueprint-based fallback that can reset the material on `OnEffectRemoved`.
- Confirm if UE4SS can manipulate the player mesh’s materials directly (requires further exploration).
- Optional: build a lightweight C++ plugin to refresh or replace the mesh material when the visual bug is detected.
- Create a Lua-side toggle or hotkey using reliable hook logic instead of `RegisterKeyBind()`.
- Add validation for any mesh list or array before iterating to avoid crashes (`type(...) == "table"` checks).
- Explore setting player mesh material parameters directly using `SetScalarParameterValueOnMaterials`.
- Investigate use of `Update_Color_Values_Of_MID()` and `SetDitherScaleOnAllComponents()` as visual reset options.
- Confirm if `StatusEffectComponent:RestoreOriginalMaterials()` can be forced via `FinishedMinimumLifetime()`.
- Identify if `CharacterAppearancePairingComponent:RefreshCharacterAppearance()` helps reset visuals mid-gameplay.
- Consider a blueprint-based component wrapper to clear visuals in native space rather than relying on Lua.
- Build a lightweight C++ plugin as last resort if Lua/blueprint cleanup consistently fails.
- Defer OBME integration until OBSE64 plugin support matures or alternate toolchains (e.g., memory patching) are confirmed viable.


## **Credits**  
* **Kein Altar SDK Dump**  
↳ [github.com/Kein/Altar](https://github.com/Kein/Altar)  
* **Silvist Form Dump**  
↳ [Oblivion Remastered Modding Discord](https://cdn.discordapp.com/attachments/1364374629128339466/1370188992414355466/OblivionRemasteredForms.zip?ex=6825d7b0&is=68248630&hm=d21050da69c00f72d9af9381fe0df1ae626ff8e2f3262fae0977369e081b86b4&))  
