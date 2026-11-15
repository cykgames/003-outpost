# 003 · Outpost Assault

Status: prototype
Genre: tower-defense
Engine: Godot 4.7.2 (GL Compatibility)
Platform: Android (arm64-v8a)

A 2D tile-based tower defense: build gatling, single-shot and missile turrets
on fixed slots, then survive 3 escalating waves of infantry, tanks and
helicopters that pathfind toward your objective. Earn money, repair/replace
turrets, and keep the objective alive. Part of the
[cykgames](https://github.com/cykgames) catalog.

## Controls (touch)

- **Tap an empty slot** → build popup (Gatling 250 / Single 400 / Missile 800).
- **Tap a built turret** → actions: Repair / Replace / Remove.
- **Drag** anywhere → pan the battlefield.
- **+ / −** buttons (bottom-right) → zoom. Mouse wheel also works on desktop.
- **II** button (top-left) or Android back → pause.

Starting money 5000, objective health 500. Win by clearing all waves; lose if
the objective is destroyed.

## Provenance & license

This game is a mobile adaptation of **Outpost Assault** by
[Quiver](https://quiver.dev), originally
[`quiver-dev/tower-defense-godot4`](https://github.com/quiver-dev/tower-defense-godot4).

- **Code** — MIT License, Copyright (c) 2022 Quiver. See [`LICENSE.txt`](LICENSE.txt).
- **Art / music / sound assets** — Creative Commons Attribution 4.0
  International (CC BY 4.0). See [`LICENSE_ASSETS.txt`](LICENSE_ASSETS.txt).
  Attribution: Quiver (https://quiver.dev).
- Upstream README preserved at [`docs/UPSTREAM_README.md`](docs/UPSTREAM_README.md).

Adaptation changes (this repo): touch input (tap-to-build with drag-to-pan
disambiguation), mobile camera (drag pan + on-screen zoom), landscape
orientation, GL Compatibility renderer, on-screen pause/zoom buttons, Android
back-button pause, and an arm64 export preset (`com.cykagent.outpost`).

## Build

```bash
godot --headless --path . --import
godot --headless --path . --export-debug "Android" build/003-outpost.apk
```

Debug-signed (no release keystore). arm64-v8a only, ETC2 textures. See
`docs/CHECKPOINT.md` for the full verification log.
