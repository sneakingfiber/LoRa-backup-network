// ESP32 LoRa BEACON node — transmitter side.
//
// Companion to the receiver sketch in ../serial-passtrough/. That one owns the
// OLED and the display logic; this one is deliberately bare: a UART bridge plus
// a periodic beacon, nothing else.
//
// USB side : Serial  @ USB_BAUD   (Serial Monitor)
// LoRa side: Serial1 @ LORA_BAUD  on GPIO16 (RX) / GPIO17 (TX)
//
// Both directions are raw byte-for-byte: whatever the terminal sends reaches
// the radio unmodified (payload or config command, line endings included), and
// whatever the radio emits is echoed straight back to USB.
//
// The radio is assumed to be already configured (address / channel / air rate).

constexpr int LORA_RX_TO_ESP32 = 16;   // ESP32 RX <- LoRa TX
constexpr int LORA_TX_FROM_ESP32 = 17; // ESP32 TX -> LoRa RX

constexpr unsigned long USB_BAUD = 9600;  // matches the receiver sketch
constexpr unsigned long LORA_BAUD = 9600; // module uses LPUART, capped at 9600

// USB -> radio, raw byte for byte. No CR/LF rewriting: whatever the terminal
// puts on the wire is exactly what the radio sees, so config commands reach the
// module with their original line ending intact.
void passthroughUsbToLora()
{
  while (Serial.available())
  {
    Serial1.write((char)Serial.read());
    noteUsbActivity(); // holds the beacon off so it can't split this line
  }
}

// radio -> USB, raw byte for byte
void passthroughLoraToUsb()
{
  while (Serial1.available())
  {
    Serial.write((char)Serial1.read());
  }
}

void setup()
{
  Serial.begin(USB_BAUD);
  Serial1.begin(LORA_BAUD, SERIAL_8N1, LORA_RX_TO_ESP32, LORA_TX_FROM_ESP32);

  Serial.println();
  Serial.println(F("=== ESP32 LoRa beacon node ==="));
  Serial.print(F("USB baud : "));
  Serial.println(USB_BAUD);
  Serial.print(F("LoRa baud: "));
  Serial.println(LORA_BAUD);
  printBeaconConfig();
  Serial.println(F("Type to send to the radio (payload or config command)."));
}

void loop()
{
  passthroughUsbToLora();
  passthroughLoraToUsb();
  updateBeacon();
}
