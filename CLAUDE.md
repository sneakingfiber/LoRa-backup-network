# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ESP32 firmware for a two-node **DX-LR02-433T22D** LoRa link, plus the hardware references and
enclosure models. See [README.md](README.md) for the directory layout.

No build system, no tests, no linter — these are Arduino IDE sketch folders.

## Build / flash

`arduino-cli` lives at `/opt/homebrew/bin/arduino-cli` and is **not on PATH** in non-interactive
shells; call it by absolute path. Always pass a sketch **folder**, never a single `.ino`.

```
arduino-cli compile --fqbn esp32:esp32:esp32 firmware/<sketch>
arduino-cli upload  --fqbn esp32:esp32:esp32 -p /dev/cu.usbserial-110 \
                    --board-options UploadSpeed=115200 firmware/<sketch>
arduino-cli monitor -p /dev/cu.usbserial-110 -c baudrate=9600
```

Only `serial-passtrough` needs libraries: `Adafruit_GFX`, `Adafruit_SSD1306` (plus bundled `Wire`).

### Traps that have already bitten this project

- **Folder name must equal the main `.ino` name.** Otherwise the IDE finds no main sketch, treats a
  sibling file as a standalone sketch, and the link fails with `undefined reference to 'setup'`.
- **The Arduino IDE will silently move a loose `.ino` into its own subfolder**, turning it into a
  separate sketch. Subfolders (except `src/`) are not compiled as part of the parent sketch.
- **Every `.ino` in a folder is concatenated into one translation unit**, main sketch first, the rest
  alphabetically. Arduino auto-generates prototypes for **functions only** — a global defined in
  `beacon.ino` is *not* visible to the main sketch. Expose it through a function instead; this is
  why `printBeaconConfig()` exists in `lora-beacon/beacon.ino`.
- **One process at a time owns the port.** A monitor or `screen` session makes uploads fail with
  `Resource busy`. `/dev/tty.debug-console` is a macOS-internal device, never the board; use
  `/dev/cu.usbserial-*`, not `/dev/tty.*`.
- `arduino-cli` shell working directory resets between calls — use absolute or repo-relative paths,
  and verify the reported sketch size matches the sketch you meant to build.

## Wiring / constants that matter

- LoRa on `Serial1`: GPIO16 = ESP32 RX (from module UART_TX), GPIO17 = ESP32 TX (to module UART_RX).
  Common GND required.
- **9600 baud is a hard ceiling**, not a default: the module's LPUART is clocked at 32.768 kHz.
- M0/M1 are *Reserved* on this module — no hardware mode select, configuration is AT-only. Do not
  copy EBYTE E32 mode-pin patterns here.
- Logic is 3.3 V, absolute max 3.7 V on VDDIO even when VCC is fed 5 V.
- OLED (receiver only) on I2C: SDA GPIO21, SCL GPIO22, address `0x3C` — fall back to `0x3D` if
  `display.begin` fails; `initOledDisplay` prints that hint.

## Firmware architecture

### `firmware/serial-passtrough` — receiver

- `serial-passtrough.ino` — `setup()`/`loop()`. Owns duplicate-line counting (`repeatCount`) and the
  signal-timeout watchdog (`SIGNAL_TIMEOUT_MS` / `SIGNAL_LOST_REPEAT_MS`).
- `radio_to_oled.ino` — OLED primitives, the five display modes, both passthrough pumps.

**The receiver never transmits on its own.** It carries no beacon: the only bytes it puts on the
radio are the ones the operator types over USB. Keep it that way — an autonomous transmitter on the
listening node is what forces the beacon/user UART contention that `lora-beacon` has to work around.

USB and LoRa both run at 9600 here — `Serial.begin(LORA_BAUD)` shares the one constant.

### `firmware/lora-beacon` — transmitter

- `lora-beacon.ino` — `setup()`/`loop()` and both pumps. **Both directions are raw byte-for-byte**;
  unlike the receiver, it does no CR/LF rewriting, so config commands reach the module with their
  original line ending intact.
- `beacon.ino` — `updateBeacon()`, pumped from `loop()`, non-blocking.

### Passthrough contract

`loop()` must call both pumps every iteration; neither blocks.

- `passthroughUsbToLora()` — drains `Serial` into `Serial1`. The receiver drops `\r` and expands
  `\n` to `\r\n`; the beacon node copies bytes untouched.
- `passthroughLoraToUsb()` — on the receiver, echoes every LoRa byte to USB raw *and* accumulates
  into `loraRxLine`, returning a completed trimmed line on `\n`, else `""`. Empty lines are
  swallowed, so `""` means "nothing to display", not "no bytes read". On the beacon node it is a
  plain raw echo returning nothing.

### Beacon / user contention (transmitter only)

On `lora-beacon` the beacon and the operator share one UART to the radio. A beacon injected
mid-command corrupts it, so `passthroughUsbToLora()` calls `noteUsbActivity()` per byte and the
beacon holds off while the user types plus `BEACON_QUIET_MS` (1500 ms) after the last keystroke. A
module that takes longer than that to reply can still be interrupted — disable the beacon for config
work.

### Display modes (receiver)

`displayPlain`, `displayBoxed`, `displayTitled`, `displayCentered`, `displayAlert` render
immediately and are self-contained (each does its own `clearDisplay()` … `display()`).

`displayScroll` is the exception: it only arms module-level scroll state, and `updateScroll()` must
be pumped from `loop()` to advance frames (2 px per `scrollFrameIntervalMs`, default 40 ms). It
self-disarms when the text leaves the screen. Any other display mode drawn while a scroll is active
will fight it for the framebuffer.

`drawCornerBrackets(skipTop)` takes `true` in `displayTitled` because the title bar is a filled
white rect — top brackets would be white-on-white.

The `on*TextReceived` hooks and `callRandomReceiver` / `updateOledDemo` are demo scaffolding; the
live path is `loop()` calling `displayTitled` and `displayBoxed` directly.

### `firmware/lora-char-sender` — minimal test

Single `.ino`, no beacon logic: writes one letter `A`–`Z` to `Serial1` every 2 s and echoes
anything the module sends back. **Its USB console is 115200, not 9600** — the only sketch where the
two baud rates differ, so use `-c baudrate=115200` when monitoring it. Reach for it when you need
to prove the radio link works without the OLED, the beacon, or the passthrough rewriting bytes.

## Talking to the module (AT)

Full reference: [docs/DX-LR02-433T22D.md](docs/DX-LR02-433T22D.md) (Italian; each claim tagged
📘 datasheet / ✅ manufacturer guide / ⚙️ inference, with datasheet contradictions flagged in place).
The parts that decide whether a session works at all:

- `+++` toggles between transparent mode and AT mode. **Leaving AT mode reboots the module** — that
  reboot is when changed parameters take effect, so a parameter changed and tested without exiting
  first is still running the old config.
- **Every AT command must end with CR LF (`0D0A`)**; without it the module ignores the line
  silently. This is why the receiver's `passthroughUsbToLora()` expands `\n` to `\r\n`, and why the
  beacon node's raw passthrough is the safer place to do config work.
- Commands: `AT+HELP`, `AT+MODE X` (0 transparent / 1 fixed-point / 2 broadcast),
  `AT+CHANNEL XX` (default `00`), `AT+MAC XX XX` (default `FF FF`), `AT+LEVEL X` (0–7).
- **Both ends must share the same `LEVEL`.** It sets spreading factor / bandwidth; mismatched levels
  are deaf to each other even on the same channel and address. Low level = slower, longer range.
- Modes 1 and 2 prepend a header of **raw hex bytes**, not ASCII: `ADDR_H ADDR_L CH` for fixed-point,
  `CH` for broadcast. `Serial1.write(0x00)`, never `Serial1.print("00")`.
- The AT command set is *not* in the datasheet (hardware spec only); it comes from the
  manufacturer's guide, and §11 of the doc lists what is still unverified.

Before any AT session on the transmitter: set `beaconEnabled = false`, and make sure no monitor
holds the port. The receiver is silent by default, so it needs neither.

## CAD (`cad/`)

OpenSCAD sources for the two-part enclosure. The app is not on PATH:

```
"/Users/fyder9/Desktop/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD" \
  -o prev.png --preview --imgsize=900,700 --camera=37.5,35,7,62,0,215,150 \
  cad/caseLora/case_Lora_3D_4.scad
```

`-o out.csg` instead of a PNG is the quick way to check a model still compiles.

- `cad/caseLora/case_Lora_3D_3.scad` — **case bottom** (75 × 70 × 20), exterior styling pass over
  the internals of `case_Lora_3D_2.scad`.
- `cad/caseLora/case_Lora_3D_4.scad` — **lid** (75 × 70 × 15). Mates rim-to-rim with `_3`, flipped
  180°; its `screw_pos` must stay aligned with the bottom's turrets. Holds the 128×32 OLED island.
- `.3mf` files are exports, not sources.
- `cad/case_Lora_3D.scad` and `cad/case_Lora_3D_2.scad` are earlier top-level revisions.
  `cad/case_Lora_3D_2.scad` and `cad/caseLora/case_Lora_3D_2.scad` **share a name but differ** (one
  cylinder offset, `69-22` vs `69-2`) — confirm which file you are editing.
- Both `_3` and `_4` build the shell as `envelope()` intersected with the body, so bosses drawn past
  an outer face come out trimmed flush rather than protruding.
- `case_Lora_3D_4.scad` pulls `assets/Inter-ExtraBold.ttf` via `use <>` and the Meshtastic SVG —
  paths are relative to the `.scad`, so render from `cad/caseLora/`.
- The `.scad` comments record why a dimension is what it is (e.g. `oled_post_d = 4.4` because 4.0
  made posts exactly tangent to the pocket wall, which is non-manifold). Keep that habit when
  changing numbers.
