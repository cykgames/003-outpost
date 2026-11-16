# 003 · Outpost Assault (mobile)

- **Catalog**: [cykgames](https://github.com/cykgames) #003
- **Status**: prototype `v0.1.1` (playable, debug-signed)
- **Author / maintainer agent**: **cykbot12** (bot12) — single-agent production
- **Genre**: 2D tile-based tower defense
- **Engine**: Godot 4.7.2, GL Compatibility renderer
- **Platform**: Android arm64-v8a, landscape (`com.cykagent.outpost`)
- **In-game credit**: main menu, bottom-right label (author + upstream attribution)

This file is the handoff entry point for other agents. Read it top to bottom
before touching code; the verification log lives in
[`docs/CHECKPOINT.md`](docs/CHECKPOINT.md).

## Gameplay

Defend the outpost objective (500 HP) against 3 escalating waves of enemies
that pathfind toward it. You start with 5000 money and 12 fixed turret slots.

- **Turrets** (prices in `assets/scripts/global.gd:turret_prices`):
  - Gatling 250 — rapid fire (`fire_rate 0.1`), anti-infantry workhorse
  - Single 400 — single-shot cannon
  - Missile 800 — homing missiles, the reliable answer to helicopters
- **Enemies** (weighted random mix, `scenes/maps/spawner/spawner.gd:enemies`):
  infantry_t1 (45) / infantry_t2 (40) / tank (15) / helicopter (5).
  Tanks and helicopters are `ShootingEnemy`s — they fire back at the objective.
- **Waves**: 3 waves, spawn counts 20 → 40 → 70 with the shipped
  `map_template.tscn` (`enemy_count = 20`, `+current_wave*10` per wave).
  5 s countdown between waves; kills pay money.
- **Win**: all waves finished and every enemy dead (`spawner.enemies_defeated`).
- **Lose**: objective HP → 0 (`objective.destroyed` → HUD game-over).
- Built turrets can be **Repair / Replace / Remove**d via the actions popup.

Balance knobs: `spawner.gd` exports (`wave_count`, `enemy_count`, `spawn_rate`,
`enemies` weights), `map.gd:STARTING_MONEY`, objective HP in
`map_template.tscn`, turret stats in each `entities/turrets/*/*.tscn`.

## Controls

Touch (primary):
- **Tap empty slot** → build popup (Gatling / Single / Missile)
- **Tap built turret** → Repair / Replace / Remove
- **Drag** → pan the battlefield (tap/drag threshold 16 px)
- **+ / −** (bottom-right) → zoom; **II** (top-left) or Android back → pause

Desktop (still works): left click = tap, middle-drag or left-drag = pan,
mouse wheel = zoom, ESC = pause.

## Provenance & license

Mobile adaptation of **Outpost Assault** by [Quiver](https://quiver.dev),
upstream [`quiver-dev/tower-defense-godot4`](https://github.com/quiver-dev/tower-defense-godot4)
(Godot 4.0 template; upstream now superseded by
`quiver-dev/tower-defense-tutorial`, but this fork keeps the older codebase
because it has the hit-state FSM we rely on).

- **Code** — MIT, Copyright (c) 2022 Quiver → [`LICENSE.txt`](LICENSE.txt)
- **Art / audio assets** — CC BY 4.0, attribution Quiver (https://quiver.dev)
  → [`LICENSE_ASSETS.txt`](LICENSE_ASSETS.txt)
- Upstream README preserved at [`docs/UPSTREAM_README.md`](docs/UPSTREAM_README.md).
  Note: upstream ships **no sound effects and no explosions SFX**; silence is
  expected, not a bug.
- This repo has a **clean git history** (no upstream `.git`, no LFS; binaries
  committed directly). Do not re-add LFS pointers.

### Adaptation delta (what cykbot12 changed vs upstream)

- `project.godot` — GL Compatibility (desktop+mobile), landscape
  (`handheld/orientation=0`; enum 0=landscape, 1=portrait),
  `emulate_mouse_from_touch=true`, ETC2/ASTC import, 1280x720 canvas_items/expand.
- `scenes/maps/map.gd` — drag-to-pan with tap threshold, wheel zoom,
  tap-on-empty-ground dismisses popups, Android back toggles pause,
  centers battlefield at zoom 0.5 on start.
- `scenes/maps/camera2D/camera2D.gd` — passive smooth zoom +
  `pan()/zoom_in()/zoom_out()/center_on()` (Map drives input).
- `scenes/maps/turret_slot/turret_slot.gd` — tap-aware placement
  (press+release within threshold; drag cancels pending tap; marks input
  handled so Map doesn't double-process).
- `interfaces/HUD/hud.gd` — code-built on-screen zoom +/− and pause II buttons.
- `interfaces/UI/menu/` — author credit label; HowToPlay swaps to touch
  wording on touch devices (`menu.gd:_ready`).
- `export_presets.cfg` — arm64-v8a only, ETC2, debug-signed, immersive,
  no internet permission.
- `tools/regression.*` — new headless autonomous regression harness.

## Architecture / code map

```
assets/scripts/global.gd   autoload Global: money, turret_prices, is_gameover
assets/scripts/scenes.gd   autoload Scenes: scene paths, change_scene, get_enemy_path
interfaces/UI/menu/        main scene (run/main_scene): START / HOW TO PLAY / QUIT
interfaces/UI/pause/       pause overlay (tree paused)
interfaces/UI/game_over/   RETRY / EXIT overlay
interfaces/UI/turret_popup/    build menu (3 turret buttons)
interfaces/UI/turret_actions/  repair / replace / remove menu
interfaces/HUD/hud.gd      wave/health/money readouts + zoom/pause buttons,
                           bind_camera(), game-over handler
scenes/maps/map.gd         input orchestration + economy start (see below)
scenes/maps/map_template.tscn  the shipped level (12 slots, objective, spawner)
scenes/maps/camera2D/      smooth-zoom camera
scenes/maps/turret_slot/   slot collision + tap handling + turret lifecycle
scenes/maps/spawner/       waves, weighted enemy pick, win signal
scenes/maps/objective/     HP + destroyed signal
entities/turrets/          turret.gd base + gatling/single/missile variants
entities/enemies/          enemy.gd + enemy_fsm.gd + states/ (idle/move/motion/die)
entities/enemies/shooting/ shooting_enemy.gd + tanks/ + helicopters/
entities/shooter.gd        enemy weapon (projectile instanced signal)
entities/projectiles/      turret + enemy projectiles
entities/state_machine.gd  generic FSM base (state.gd)
tools/regression.tscn/.gd  headless 18-check regression (see Testing)
```

### Touch input flow (debug this first for any input bug)

1. `emulate_mouse_from_touch=true` converts touches to mouse events, so all
   upstream mouse-based UI keeps working.
2. Slot taps: `turret_slot.gd:_on_input_event` (physics picking) tracks
   press/release; movement > `TAP_THRESHOLD` (16 px) cancels the tap; a valid
   tap calls `_handle_tap()` (opens build popup or turret actions) and
   `get_viewport().set_input_as_handled()`.
3. Everything unhandled falls to `map.gd:_unhandled_input`: drag = camera pan,
   wheel = zoom, tap on empty ground = dismiss popups, back = pause.
4. HUD buttons are plain `Button`s (code-built in `hud.gd`), consume their own
   input.

If a tap "does nothing", check in this order: slot collision shape/layer
(layer 4 = turret_slot), `set_input_as_handled` ordering, popup visibility
(`Global.turret_actions` ensures only one actions popup visible).

## Build & export

Godot 4.7.2 console binary (local install:
`%USERPROFILE%\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe`,
referred to as `godot` below).

```bash
godot --headless --path . --import                                  # assets, expect 0 errors
godot --headless --path . res://tools/regression.tscn               # expect 18/18 PASS, outcome=win
godot --headless --path . --export-debug "Android" build/003-outpost.apk
adb install -r build/003-outpost.apk
adb shell am start -n com.cykagent.outpost/com.godot.game.GodotAppLauncher
```

- Export preset "Android": arm64-v8a only, ETC2, **debug-signed** (no release
  keystore yet), immersive landscape, package `com.cykagent.outpost`.
- APK ≈ 49 MB. `build/` is gitignored; logs `build_*.log` at repo root are
  historical evidence, safe to delete.

## Testing & verification

Headless regression (`tools/regression.tscn`, run via scene path — a bare
`--script` MainLoop does NOT register autoloads): **18/18 PASS, outcome=win**,
reproduced twice. Covers: structure (12 slots, objective 500 HP, money 5000,
zoom 0.5), tap handler opens build popup, placement via popup button + money
deduction, combat through the real FSM `is_hit` death path (infantry fixture),
kill rewards, win wiring, lose wiring (objective destroyed →
`Global.is_gameover`). The regression node uses `PROCESS_MODE_ALWAYS` to
survive the game-over tree pause.

Known harness limits (do not "fix" these by rewriting the game):
- Headless `push_input` physics picking is inactive in this build → regression
  calls the tap *handler* directly; real touch path is verified on device.
- Combat fixture is deterministic infantry-only; a full 3-wave real-time sim
  was CPU-heavy/non-deterministic and was ruled out (see CHECKPOINT).

On-device evidence (screenshots in `docs/screenshots/`: menu / gameplay /
game_over): landscape menu renders, map + HUD + zoom/pause buttons render,
enemies spawn/move, lose path shows GAME OVER, logcat shows touch TAP events
reaching the engine, no crash. **Full scripted touch playtest (tap→build→pan→
zoom) is still pending** — test phones are shared with other agents; check
foreground app before injecting input, and never fight another agent for the
device.

adb quirks on the rotated Godot window: `input tap` coordinates are
degenerate — use zero-distance `input swipe x y x y` for taps.

## Known issues / open items

- Full touch playtest pending (device contention), see above.
- Difficulty untested by humans; shooting enemies can whittle the objective.
- Debug-signed only; release keystore needed for store-style release.
- No SFX (upstream lacks them); procedural SFX + pinch-zoom are polish ideas.
- HowToPlay mouse diagram art still upstream (text is touch-adapted on device).

## Handoff conventions (other agents read this)

- Entry order: README → `docs/CHECKPOINT.md` → `tools/regression.gd`.
- Always re-run the regression after gameplay/input changes; it is the
  acceptance gate (18/18, win).
- **Privacy**: no LAN IPs, device serials, or user-specific paths in this
  repo (public catalog). Device facts live in the agent's MEMORY.md only.
- Git: commit locally is fine; **push only with explicit user consent**.
  Catalog row / GitHub repo creation goes through `cykgames-org`
  (`scripts/new_game.py`), not ad-hoc.
- License hygiene: keep both LICENSE files and the Quiver attribution in any
  fork or redistribution (CC BY 4.0 requirement).