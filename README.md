Chameleon / Invisibility Debug Reference
Oblivion Remastered – UE5 Visual Cleanup Research

This folder contains all known assets, headers, and technical details tied to the Chameleon visual bug in Oblivion Remastered (UE5-based). Use this to build plugins, Lua scripts, or mods that remove or suppress lingering Chameleon visuals.

Core FormIDs

CHML  = 0x0008185C    ; Chameleon shader base
INVS  = 0x00080BE5    ; Invisibility shader base
CHML2 = 0x4C6E53FE    ; Additional Chameleon visual effect (confirmed from UE dump)

visual/   
- BP_effectChameleon.uasset / .uexp
- BP_effectInvisibility.uasset / .uexp
- CHML.uasset / .uexp
- INVS.uasset / .uexp

These are the actual visual effects and shaders you may need to remove via Lua or C++ plugin.

SDK Dump/
- VMagicSpellVFX.h
  → Exposes SendVFXEndSignal(AActor*) — call to forcibly clear stuck visuals.
- VOblivionRuntimeSettings.h
  → Shows internal shader binding:
      TSoftClassPtr<UTESEffectShader> EffectChameleon;
      TSoftClassPtr<UTESEffectShader> EffectInvisibility;
- TESForm.h, VPairedCharacter.h, VPairedPawn.h
  → Used to trace actor status/effects with OBSE64 later.

Form Dump/
- Lua-accessible player state logic:
    Actor:IsSneaking()
    Actor:IsInCombat()
    Actor.ActorValuesPairingComponent:GetValue("Chameleon")
    Filtering components by "BP_effectChameleon" works with UE4SS scripting

What I Have Learned So Far
- Chameleon visual bug is a base game engine-level issue, not specific to any mod.
- Stuck visuals occur when multiple Chameleon effects are added/removed quickly (especially mid-sneak).
- `SendVFXEndSignal()` exists in `VMagicSpellVFX` but fails silently via Lua in most cases.
- The Chameleon visual components are tied to Blueprints like `BP_effectChameleon` and shader tags like `CHML`, `CHML2`, `INVS`.
- UE4SS Lua can detect actor values and effect form IDs using `TESSync.DynamicForms` and `ActorValuesPairingComponent:GetValue()`.
- `FindComponentByClass` is not supported in your current UE4SS setup.
- `GetComponents()` + filtering by name like `"BP_effectChameleon"` is a viable method for attempting cleanup.
- Chameleon form IDs confirmed:
    - CHML  = 0x0008185C
    - CHML2 = 0x4C6E53FE
    - INVS  = 0x00080BE5

What Has Worked So Far
 - Tracking Chameleon gameplay effect via: 
    player.ActorValuesPairingComponent:GetValue("Chameleon")
- Tracking Chameleon visual presence via:
    TESSync.DynamicForms and GetFormID() matching CHML/CHML2/INVS
- Executing cleanup logic only once after Chameleon ends (using hadChameleon = true flag).
- Using `LoopAsync()` or `ExecuteWithDelay()` to check player state on a timer.
- Finding and filtering player components by name to locate `BP_effectChameleon`.

What Has Not Worked So Far
- FindComponentByClass → results in a nil / method call error.
- player.dispel 0x0008185C → works for Bound Arrow, not for Chameleon.
- K2_DestroyComponent alone → often fails to clear visuals.
- SendVFXEndSignal() on component or actor → fails silently or returns nullptr.
- player.ActiveMagicEffects in Lua → usually nil or unreliable.
- TESSync.DynamicForms alone → often empty or not yet populated during mod load.
- Any method relying on console prints/debug logs → doesn’t display anything.
- OBSE plugin approach so far has unresolved build and header issues.

My Goal
Create a universal ChameleonFix mod that:
- Detects when the player no longer has an active Chameleon effect (spells, potions, items).
- Immediately removes any lingering Chameleon visual effect via a reliable cleanup method.
- Works without OBSE, Unreal Editor, or external engine hooks.
- Uses UE4SS Lua exclusively for compatibility and ease of distribution.
- Helps all players — not just those using your specific ESP-based sneak system.

 What I'm Still Working On
 - Finding a reliably exposed method in UE4SS or Unreal blueprints to remove the visual effect.
- Validating whether `SendVFXEndSignal()` can be routed through a different object like VMagicSpellVFX.
- Confirming when/if TESSync.DynamicForms is populated at runtime (e.g. during sneak/spell use).
- Verifying if the Chameleon effect visual is bound to a particular BP component that isn’t caught by GetComponents().
- Logging or debugging output to verify presence of visual effect components in real-time.

 What I Need to Know to Fine-Tune

 - Is there any exposed function or component (like VMagicSpellVFX) that successfully clears visuals?
- Are multiple BP_effectChameleon instances being generated per source (e.g. potion + armor)?
- Can we determine the moment TESSync becomes populated in runtime, or force-rescan it?
- Can we hook into BP component lifecycle (OnAttach/OnRemove) via UE4SS?
- Would a C++ plugin for OBSE64 have better access to ActiveEffectsPairingComponent or visual state?

What Could Possibly Work (Ideas / Leads / Experiments)
- Use `ActorValuesPairingComponent:GetValue("Chameleon")` and remove visuals once value = 0.
- Hook the `SendVFXEndSignal()` function from `VMagicSpellVFX` directly using RegisterHook or C++.
- Scan `GetComponents()` for “Chameleon” or “BP_effectChameleon” on delay loop and destroy them manually.
- Try calling `SendVFXEndSignal("CHML")` and `SendVFXEndSignal("BP_effectChameleon")` explicitly.
- Use UE4SS Blueprint hot-patching to override Chameleon BP logic and insert removal signals.
- Build a fallback `.pak` mod that runs a visual effect cleaner from Blueprints if Lua fails.

What Works or Looks Promising
- ActorValuesPairingComponent:GetValue("Chameleon") in Lua
- Filtering GetComponents() for "BP_effectChameleon"
- CS-based script workaround using fTotalChameleon
- Lua checking sneak/combat/detection: stable
- Plugin scaffolding for OBSE64 (future-proof)

Debug Summary / Modder Context

Tried fixing stuck Chameleon visuals from using more than one source of Chameleon. Used GetComponentsByClass with BP_effectChameleon and SendVFXEndSignal/K2_DestroyComponent, TESSync, among many other things. ActiveMagicEffects seems to read fine, but no exposed method clears the shaders. Looking for any working cleanup or visual reset after Chameleon ends.

Attaching my latest code in case anyone else has ideas — been at this for days. I dumped UE4SS Lua and searched Unreal Engine structures, tried a lot with no luck. To reproduce bug: equip items 00027110, 00049393, and 00091ab2 (all with Chameleon buffs) back to back. Visual glitch appears and doesn't go away. I'm trying to force remove it when Chameleon ends by taking off the items etc.

Trying to use UE4SS to detect when Chameleon ends — found the effect ID (1280133187) but can't find much else exposed in Unreal. Tried a few approaches but nothing's worked. My mod revolves around a custom Chameleon system that works, but the visuals bug out and even bSuppressEffect doesn't always fix it. Just wondering if anyone’s ever found more Chameleon-related data in the engine or if it’s hardcoded and inaccessible?

From testing, it appears Chameleon triggers two separate visual shaders.
One may be legacy/low-res, the other HD/post-process. Only one cleans up sometimes.

Also: already tried checking paired component – no result.

**Credits**  
* **Kein Altar SDK Dump**  
↳ [github.com/Kein/Altar](https://github.com/Kein/Altar)  
* **Silvist Form Dump**  
↳ [Oblivion Remastered Modding Discord](https://cdn.discordapp.com/attachments/1364374629128339466/1370188992414355466/OblivionRemasteredForms.zip?ex=6825d7b0&is=68248630&hm=d21050da69c00f72d9af9381fe0df1ae626ff8e2f3262fae0977369e081b86b4&))  
