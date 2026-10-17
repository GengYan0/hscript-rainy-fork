# Patch 01 — O(1) parent-instance field membership (resolve fast-path)

## Motivation
`Interp` subclasses (engine `CustomInterp`) resolve bare identifiers against a
`parentInstance` object by scanning `_instanceFields: Array<String>` with
`Array.contains(id)` on **every** identifier access. `Array.contains` is O(n); a
`FlxSprite`/character object exposes hundreds of fields, so a per-frame script
that reads `health` / `songPos` / `curStep` / `bf` / `dad` … pays a linear scan
per access. This is the dominant identifier-resolution cost in gameplay scripts.

## Change
- `Interp` gains `parentFieldSet: Map<String, Bool>` (mirrors the existing
  `#if haxe3 Map / #else Hash` branch) and a public
  `buildParentFieldSet(fields: Array<String>): Void` that precomputes the
  membership set once.
- Engine `CustomInterp.set_parentInstance` now calls `buildParentFieldSet(_instanceFields)`.
- Engine `CustomInterp.resolve` replaces
  `parentInstance != null && _instanceFields.contains(id)`
  with
  `parentInstance != null && parentFieldSet != null && parentFieldSet.exists(id)`.

Semantics are identical: same membership test, just O(1) instead of O(n). The
resolved *value* is still fetched fresh via `Reflect.getProperty` each call
(parent-instance fields mutate every frame), so no value-staleness risk.

## Verification
- Engine release build: 3/3 gates pass (flixel→fork / lime build / exe rebuilt).
- Headless neko bench (subclassed `Interp` with engine-style `resolve`):
  - correctness: `health+songPos` = 123.5, normal var `k` = 100, EField `d.x+d.y` = 3 ✓
  - A/B on 300-field list: `Array.contains` 29,685 ns/op → `Map.exists` 321 ns/op = **92.5×**
    (5-field list = 2.29×; scales linearly with field count as expected).

## Rollback
Revert `HScript.hx` (2 lines) + drop `parentFieldSet`/`buildParentFieldSet` from
`Interp.hx`. No API surface or script semantics affected.
