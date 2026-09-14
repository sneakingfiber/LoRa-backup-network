// Periodic beacon: pushes the same message to the LoRa module on Serial1 every
// BEACON_INTERVAL_MS. The radio is assumed to be already configured, so this
// just writes the payload as a plain CRLF-terminated line.
//
// Non-blocking: updateBeacon() is pumped from loop(), it never delays.
//
// Coexistence with the USB passthrough: the beacon and the user share one UART
// to the radio. Injecting a beacon in the middle of a half-typed config command
// would corrupt it, so the beacon holds off while the user is typing and for
// BEACON_QUIET_MS after the last byte from USB. passthroughUsbToLora() reports
// that activity via noteUsbActivity().

constexpr unsigned long BEACON_INTERVAL_MS = 3000; // period between transmits
constexpr unsigned long BEACON_QUIET_MS = 1500;    // hold-off after USB input

// payload sent every period, CRLF appended by sendBeaconNow()
const char BEACON_MESSAGE[] = "BEACON";

bool beaconEnabled = true;
unsigned long lastBeaconSend = 0;
unsigned long lastUsbActivity = 0;
unsigned long beaconCount = 0;

// setup() lives in the main sketch, which the Arduino preprocessor compiles
// before this file — it can call our functions but cannot see our variables,
// so the banner is printed from here.
void printBeaconConfig()
{
    Serial.print(F("Beacon   : \""));
    Serial.print(BEACON_MESSAGE);
    Serial.print(F("\" every "));
    Serial.print(BEACON_INTERVAL_MS);
    Serial.println(F(" ms"));
}

// called by passthroughUsbToLora() whenever a byte arrives from the computer
void noteUsbActivity()
{
    lastUsbActivity = millis();
}

void sendBeaconNow()
{
    Serial1.print(BEACON_MESSAGE);
    Serial1.print("\r\n");
    beaconCount++;

    // local echo so the Serial Monitor shows what the beacon injected,
    // otherwise beacon traffic is invisible next to the radio's replies
    Serial.print(F("[beacon #"));
    Serial.print(beaconCount);
    Serial.print(F("] "));
    Serial.println(BEACON_MESSAGE);
}

void updateBeacon()
{
    if (!beaconEnabled)
    {
        return;
    }

    unsigned long now = millis();

    // user is mid-command: don't interleave bytes into their line
    if (now - lastUsbActivity < BEACON_QUIET_MS)
    {
        return;
    }

    if (now - lastBeaconSend < BEACON_INTERVAL_MS)
    {
        return;
    }

    lastBeaconSend = now;
    sendBeaconNow();
}
