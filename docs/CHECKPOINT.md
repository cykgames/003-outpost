# 003-outpost — Build Checkpoint (2026-11-15)

## Status: playable prototype v0.1.0 (mobile tower defense)

Single-agent independent production. Fork of Quiver's **Outpost Assault**
(`quiver-dev/tower-defense-godot4`, MIT) adapted to mobile touch + Android arm64.
Local repo only — **not pushed** (push requires user consent).

## What was built

- Fresh local repo `003-outpost` (clean git history, no upstream `.git`, no LFS;
  476 art/audio binaries committed directly, ~21 MB). Both upstream licenses
  kept: `LICENSE.txt` (MIT code, Quiver 2022) + `LICENSE_ASSETS.txt` (CC BY 4.0).
  Upstream README preserved at `docs/UPSTREAM_README.md`; attribution in README.
- Mobile adaptation (the actual production work):
  - `project.godot`: GL Compatibility renderer (desktop + mobile), landscape
    orientation (`window/handheld/orientation=0`), `emulate_mouse_from_touch=true`,
    ETC2/ASTC import, 60 fps physics, 1280x720 canvas_items/expand stretch.
  - `camera2D.gd`: passive smooth-zoom + `pan()`/`zoom_in/out()`/`center_on()`
    helpers (the Map drives input).
  - `map.gd`: single-finger **drag-to-pan** with a tap/drag threshold, mouse-wheel
    zoom, tap-on-empty-ground dismisses turret actions, Android back button
    toggles pause. Centers the battlefield at zoom 0.5 on start.
  - `turret_slot.gd`: **tap-aware** placement (press+release within threshold;
    dragging cancels the pending tap so panning never mis-builds) and marks the
    input handled so the map does not double-process a slot tap.
  - `hud.gd`: on-screen **zoom +/-** (bottom-right) and **pause II** (top-left)
    buttons built in code; `bind_camera()` wiring.
  - `export_presets.cfg`: arm64-v8a only, ETC2, debug-signed, immersive,
    package `com.cykagent.outpost`, no internet permission.
- `tools/regression.tscn` + `regression.gd`: headless autonomous regression.

## Verification evidence

- Headless import: `--import` EXIT 0, 477 assets, **0 errors**.
- Map smoke: `map_template.tscn --quit-after 600`, **0 script errors**.
- Headless regression (`tools/regression.tscn`): **18/18 PASS, outcome=win**,
  reproduced twice (`build_regression.log`, `build_regression2.log`). Covers:
  structure (12 turret slots, objective HP 500, start money 5000, zoom 0.5),
  turret placement via popup button + money deduction (250), tap handler opens
  build popup, combat (4 infantry spawn -> killed via the real FSM `is_hit`
  death path -> win, money rewarded), and the lose wiring (objective HP->0,
  `destroyed` -> HUD game-over handler sets `Global.is_gameover`).
- APK: `--export-debug "Android"` EXIT 0, **49.1 MB**, arm64-v8a, ETC2,
  debug-signed (apksigner), `com.cykagent.outpost`.
- On-device (A54, USB, awake) — visual verification while the app was foreground:
  - Landscape main menu renders (title + START / HOW TO PLAY / QUIT), art correct.
  - Gameplay map renders: tilemap, turret slots, objective, HUD (wave / health /
    money 5000), enemies spawning + moving, and the new zoom/pause buttons.
  - Real-time combat runs; undefended objective destroyed -> **GAME OVER**
    (RETRY / EXIT) — the lose path + game-over UI work on device.
  - logcat: `OpenGL ES 3.2 Compatibility ... Mali-G68`, `OnGodotMainLoopStarted`,
    and `GestureDetector ... TAP` (touch events reach the engine). No crash.
  - Screenshots: `docs/screenshots/menu.png`, `gameplay.png`, `game_over.png`.

## Key decisions / ruled-out alternatives

- **Input model**: kept Godot's default `emulate_mouse_from_touch=true` so the
  upstream mouse-based slot/popup/button code works via tap; only the camera
  (middle-mouse pan / wheel zoom) needed rewriting. Chose drag-pan + on-screen
  zoom buttons over pinch (multi-touch emulation interplay risk); pinch is a
  possible future enhancement.
- **Orientation**: Godot enum is `0=landscape, 1=portrait`. First build copied
  `1` from 001/002 and rendered portrait; corrected to `0` (wide battlefield).
- **Regression combat**: a full real-time 3-wave sim with 12 homing-missile
  turrets was CPU-heavy and non-deterministic (random enemy mix left lingering
  helicopters; headless timeouts). Replaced with a deterministic infantry-only
  fixture driven through the real `is_hit` death path (the same path turret
  projectile damage uses) — fast, repeatable, authentic. Tank/helicopter
  shooting behavior was observed in earlier real-time runs and on device.
- **Regression harness**: a bare `--script` SceneTree MainLoop does NOT register
  autoloads (`Global`/`Scenes`); switched to a scene (`regression.tscn`) run via
  the scene path. The regression node uses `PROCESS_MODE_ALWAYS` so it survives
  the game-over tree pause and can report + quit.
- **Headless tap**: `push_input` physics picking is inactive in this headless
  build, so the regression verifies the tap *handler* directly; the real touch
  path is exercised on device (touch TAP events confirmed in logcat).

## 2026-11-15 late — author credit + handoff README (cykbot12)

- In-game author credit: `interfaces/UI/menu/menu.tscn` new `AuthorCredit`
  Label, bottom-right: "cykgames 003 · author: cykbot12 · fork of Outpost
  Assault by Quiver (MIT / CC BY 4.0)". `project.godot` gains
  `config/version="0.1.0"` and author in `config/description`.
- `menu.gd:_ready` swaps HowToPlay desktop mouse wording for touch wording on
  touch devices (hides MouseImg); desktop keeps upstream text.
- `README.md` rewritten as the handoff entry point: gameplay numbers, balance
  knobs, code map, touch input flow, build/export, regression coverage +
  limits, on-device evidence, adb quirks, known issues, repo conventions
  (privacy: no device facts; push only with user consent).
- Re-verified after changes: regression **18/18 PASS outcome=win**; menu scene
  headless smoke 0 errors; `--export-debug "Android"` signed OK,
  `build/003-outpost.apk` = 51,700,235 bytes; `install -r` on A57
  (<LAN_IP>:5555) **Success** — NOT launched (device still shared with
  other agents; visual check of the credit label pending a free device).
- Correction: shipped wave counts are 20/40/70 = **130** enemies total
  (`enemy_count=20` + `current_wave*10` per wave), earlier "100" note was wrong.

## Open items / next steps

- Full scripted touch playtest (tap slot -> build popup -> place turret -> pan /
  zoom) deferred: device contention. A54 earlier taken by fruitmerge /
  marble-runner; on 2026-11-15 ~20:53 user suggested A57, but A57 was also
  contested: fruitmerge foreground with live injected touches 20:53:24-27,
  then com.cykagent.shooter installed+launched 20:54:07; A54 meanwhile shows
  com.cykagent.match3 foreground. APK IS installed on A57 (install -r Success,
  <LAN_IP>:5555) and launches (pid 10492) but gets pushed to background.
  adb `input tap` coordinates are degenerate on the rotated Godot window
  (`input swipe` works) — use zero-distance swipe for taps.
  Re-run when a device is free; the build-popup logic is already verified
  headless and touch events confirmed reaching the engine.
- Difficulty tuning from human play (default balance: 3 waves, 130 enemies total;
  shooting enemies can whittle the objective). Release keystore for signed
  release builds (currently debug-signed). Possible pinch-zoom + procedural SFX
  (upstream lacks sound) as polish.
- Catalog row + GitHub repo creation + push pending user consent.

## Reproduce

```
godot --headless --path . --import
godot --headless --path . res://tools/regression.tscn        # 18/18 PASS, win
godot --headless --path . --export-debug "Android" build/003-outpost.apk
adb install -r build/003-outpost.apk
adb shell am start -n com.cykagent.outpost/com.godot.game.GodotAppLauncher
```

`godot` = `%USERPROFILE%\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe`.
