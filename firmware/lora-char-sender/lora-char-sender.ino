// ESP32 -> DX-LR02-433T22D LoRa module
// Sends one character every 2s in Transparent Mode (AT+MODE 0, default)
// Wiring: ESP32 GPIO16 (RX) <- LoRa TX, GPIO17 (TX) -> LoRa RX
// LoRa UART is LPUART, max 9600 baud (see datasheet ยง4)

constexpr int LORA_RX_TO_ESP32 = 16;   // ESP32 RX2 <- LoRa TX
constexpr int LORA_TX_FROM_ESP32 = 17; // ESP32 TX2 -> LoRa RX

constexpr unsigned long LORA_BAUD = 9600;
constexpr unsigned long SEND_INTERVAL_MS = 2000;

unsigned long lastSendTime = 0;
char nextChar = 'A';

void setup() {
  Serial.begin(115200);
  while (!Serial) { delay(10); }

  Serial1.begin(LORA_BAUD, SERIAL_8N1, LORA_RX_TO_ESP32, LORA_TX_FROM_ESP32);

  Serial.println();
  Serial.println(F("=== LoRa char sender ready ==="));
  Serial.print(F("Sending one char every "));
  Serial.print(SEND_INTERVAL_MS);
  Serial.println(F(" ms"));
}

void loop() {
  unsigned long now = millis();

  if (now - lastSendTime >= SEND_INTERVAL_MS) {
    lastSendTime = now;

    Serial1.write(nextChar);

    Serial.print(F("Sent: "));
    Serial.println(nextChar);

    nextChar++;
    if (nextChar > 'Z') nextChar = 'A';
  }

  // print anything the LoRa module echoes back
  while (Serial1.available()) {
    Serial.write(Serial1.read());
  }
}
