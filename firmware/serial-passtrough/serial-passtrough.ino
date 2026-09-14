// ESP32 USB <-> LoRa UART bridge
// USB side: Serial baud 9600, Serial1 baud 9600
// LoRa side: Serial1 su GPIO16 (RX) e GPIO17 (TX)
constexpr int LORA_RX_TO_ESP32 = 16;   // ESP32 RX2  <- LoRa TX
constexpr int LORA_TX_FROM_ESP32 = 17; // ESP32 TX2 -> LoRa RX

// modulo LoRa usa LPUART, limitato a 9600 baud
constexpr unsigned long LORA_BAUD = 9600;

String lastReceivedLine = "";
unsigned int repeatCount = 0;

unsigned long lastMessageTime = 0;
unsigned long lastSignalLostDisplay = 0;
constexpr unsigned long SIGNAL_TIMEOUT_MS = 10000;
constexpr unsigned long SIGNAL_LOST_REPEAT_MS = 3000;

void setup()
{
  Serial.begin(LORA_BAUD);
  while (!Serial)
  {
    delay(10);
  }

  randomSeed(esp_random());

  Serial1.begin(LORA_BAUD, SERIAL_8N1, LORA_RX_TO_ESP32, LORA_TX_FROM_ESP32);

  Serial.println();
  Serial.println(F("=== ESP32 UART Bridge ready ==="));
  Serial.println(F("USB <-> LoRa start"));
  Serial.print(F("LoRa baud: "));
  Serial.println(LORA_BAUD);
  Serial.println(F("Suggerimento: imposta 'Both NL & CR' nel Monitor Seriale."));

  initOledDisplay();
  displayTitled("LORA RADIO LINK", "Waiting for data...");

  lastMessageTime = millis();
}

void loop()
{
  passthroughUsbToLora();

  String receivedLine = passthroughLoraToUsb();
  if (receivedLine.length() > 0)
  {
    lastMessageTime = millis();

    repeatCount = (receivedLine == lastReceivedLine) ? repeatCount + 1 : 1;
    lastReceivedLine = receivedLine;

    String title = "LORA RX (x" + String(repeatCount) + ")";
    displayTitled(title, receivedLine);
  }
  else if (millis() - lastMessageTime >= SIGNAL_TIMEOUT_MS &&
           millis() - lastSignalLostDisplay >= SIGNAL_LOST_REPEAT_MS)
  {
    lastSignalLostDisplay = millis();
    displayBoxed("SIGNAL LOST");
  }

  updateScroll();
}