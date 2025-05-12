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

Methods Tried (Unsuccessful)
- GetComponentsByClass(): no crash, but doesn’t clear visuals
- K2_DestroyComponent(): no effect
- SendVFXEndSignal() in Lua: returns nullptr
- player.dispel 0x0008185C: works for Bound Arrow but not Chameleon
- ActiveMagicEffects in Lua: often nil
- TESSync.DynamicForms: not exposed
- LoopAsync: works, but needs valid logic
- OBSE64 plugin: can't build (missing headers)
- Cheat Engine tracing: inconsistent
- Reapplying Spectre Ring: clears encumbrance bug only
- PairedComponent and all known Unreal-linked effect trees: no working cleanup found

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
