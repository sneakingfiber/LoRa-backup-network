# esp32_projects

ESP32 experiments around the **DX-LR02-433T22D** LoRa module: a two-node radio link, plus the
hardware references and enclosure models that go with it.

## Layout

```
firmware/     Arduino sketches, one folder per board
docs/         written reference for the LoRa module
hardware/     datasheets, KiCad symbol, pin diagrams
cad/          OpenSCAD enclosure models
tools/        vendor utilities
```

## Firmware

Each folder is a self-contained Arduino sketch. The folder name must match the main `.ino`
inside it — renaming one without the other breaks the build.

| Sketch | Role |
|---|---|
| [firmware/serial-passtrough](firmware/serial-passtrough) | **Receiver.** USB↔LoRa bridge that mirrors received lines onto an SSD1306 OLED |
| [firmware/lora-beacon](firmware/lora-beacon) | **Transmitter.** Sends a fixed payload every 3 s; raw byte-for-byte USB passthrough |
| [firmware/lora-char-sender](firmware/lora-char-sender) | Minimal test: one character every 2 s |

Build and flash (adjust the port):

```
arduino-cli compile --fqbn esp32:esp32:esp32 firmware/lora-beacon
arduino-cli upload  --fqbn esp32:esp32:esp32 -p /dev/cu.usbserial-110 \
                    --board-options UploadSpeed=115200 firmware/lora-beacon
arduino-cli monitor -p /dev/cu.usbserial-110 -c baudrate=9600
```

Only `serial-passtrough` needs libraries: `Adafruit_GFX` and `Adafruit_SSD1306`.

## Wiring, common to every sketch

LoRa module on `Serial1`, cross-wired, 9600 8N1:

| Module pin | ESP32 |
|---|---|
| UART_RX | GPIO17 |
| UART_TX | GPIO16 |
| VCC | 3V3 |
| GND | GND (must be common) |

M0 and M1 are *Reserved* on this module and stay unconnected — unlike EBYTE-style radios, there is
no hardware mode select. Configuration is AT commands over the same UART.

The OLED on the receiver is I2C: SDA GPIO21, SCL GPIO22, address `0x3C`.

> The module's UART is an **LPUART clocked at 32.768 kHz and capped at 9600 baud** — that ceiling is
> a property of the peripheral, not a default you can raise. Logic levels are 3.3 V with an absolute
> maximum of 3.7 V on VDDIO, so a 5 V MCU needs a level shifter. See
> [docs/DX-LR02-433T22D.md](docs/DX-LR02-433T22D.md) §8.

## Documentation

[docs/DX-LR02-433T22D.md](docs/DX-LR02-433T22D.md) — operating guide in Italian, covering pinout,
AT command set, the three transmission modes, power profiles, and electrical limits. Sources are
marked per section (📘 datasheet, ✅ manufacturer guide, ⚙️ inference), and contradictions between
the datasheet and the user guide are flagged where they occur.

## Hardware

- `hardware/datasheets/` — module specification v1.1, plus the TP4056 charger datasheet
- `hardware/kicad/carrier-rx/` — receiver carrier board (KiCad project + local symbols)
- `hardware/diagrams/` — pin diagrams (SVG) and the rendered symbol (PNG)

## CAD

`cad/caseLora/` holds the current enclosure work (`.scad` sources and exported `.3mf`).
`cad/case_Lora_3D.scad` and `cad/case_Lora_3D_2.scad` are earlier top-level revisions.

> `cad/case_Lora_3D_2.scad` and `cad/caseLora/case_Lora_3D_2.scad` share a name but are **not**
> identical — they differ in one cylinder offset (`69-22` vs `69-2`). Check which one you mean
> before editing.

## Tools

`tools/UartAssist.exe` — Windows serial terminal referenced by the manufacturer's guide. On macOS
use `arduino-cli monitor` instead.
