#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define OLED_ADDR 0x3C
#define OLED_SDA_PIN 21
#define OLED_SCL_PIN 22

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
// WIFI setup code

// ---- decoration helpers ----

void drawFrame()
{
    display.drawRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, SSD1306_WHITE);
}

void drawCornerBrackets(bool skipTop = false)
{
    if (!skipTop)
    {
        // top-left
        display.drawLine(0, 0, 6, 0, SSD1306_WHITE);
        display.drawLine(0, 0, 0, 6, SSD1306_WHITE);
        // top-right
        display.drawLine(SCREEN_WIDTH - 7, 0, SCREEN_WIDTH - 1, 0, SSD1306_WHITE);
        display.drawLine(SCREEN_WIDTH - 1, 0, SCREEN_WIDTH - 1, 6, SSD1306_WHITE);
    }
    // bottom-left
    display.drawLine(0, SCREEN_HEIGHT - 1, 6, SCREEN_HEIGHT - 1, SSD1306_WHITE);
    display.drawLine(0, SCREEN_HEIGHT - 7, 0, SCREEN_HEIGHT - 1, SSD1306_WHITE);
    // bottom-right
    display.drawLine(SCREEN_WIDTH - 7, SCREEN_HEIGHT - 1, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1, SSD1306_WHITE);
    display.drawLine(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 7, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1, SSD1306_WHITE);
}

void drawTitleBar(const String &title)
{
    display.fillRect(0, 0, SCREEN_WIDTH, 12, SSD1306_WHITE);
    display.setTextColor(SSD1306_BLACK);
    display.setTextSize(1);
    display.setCursor(4, 2);
    display.print(title);
    display.setTextColor(SSD1306_WHITE);
}

int textWidthPx(const String &text, uint8_t textSize)
{
    int16_t x1, y1;
    uint16_t w, h;
    display.setTextWrap(false);
    display.setTextSize(textSize);
    display.getTextBounds(text, 0, 0, &x1, &y1, &w, &h);
    return w;
}

// ---- display modes ----

// plain text, top-left, no decoration
void displayPlain(const String &text)
{
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println(text);
    display.display();
}

// framed box with corner brackets, body text wrapped
void displayBoxed(const String &text)
{
    display.clearDisplay();
    drawFrame();
    drawCornerBrackets();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(6, 6);
    display.setTextWrap(true);
    display.print(text);
    display.display();
}

// title bar + separator + body text
void displayTitled(const String &title, const String &text)
{
    display.clearDisplay();
    drawTitleBar(title);
    display.drawLine(0, 13, SCREEN_WIDTH - 1, 13, SSD1306_WHITE);
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(4, 18);
    display.setTextWrap(true);
    display.print(text);
    drawCornerBrackets(true); // top brackets would draw white-on-white over the title bar
    display.display();
}

// large centered text, single short line/word
void displayCentered(const String &text)
{
    display.clearDisplay();
    drawFrame();
    int w = textWidthPx(text, 2);
    int x = (SCREEN_WIDTH - w) / 2;
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(x, (SCREEN_HEIGHT - 16) / 2);
    display.print(text);
    display.display();
}

// inverted alert box, blinking border feel via fillRect background
void displayAlert(const String &text)
{
    display.clearDisplay();
    display.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, SSD1306_WHITE);
    display.drawRect(1, 1, SCREEN_WIDTH - 2, SCREEN_HEIGHT - 2, SSD1306_BLACK);

    display.setTextColor(SSD1306_BLACK);
    display.setTextSize(1);
    display.setCursor(6, 4);
    display.print("! ALERT !");
    display.drawLine(0, 14, SCREEN_WIDTH - 1, 14, SSD1306_BLACK);
    display.setCursor(6, 20);
    display.setTextWrap(true);
    display.print(text);
    display.display();
}

// horizontal marquee scroll for long single-line text, non-blocking:
// call displayScroll() once to start, then updateScroll() every loop() to advance it
String scrollText = "";
int scrollX = 0;
int scrollTextWidth = 0;
bool scrollActive = false;
unsigned long lastScrollFrame = 0;
uint16_t scrollFrameIntervalMs = 40;

void displayScroll(const String &text, uint16_t frameDelayMs = 40)
{
    scrollText = text;
    scrollTextWidth = textWidthPx(text, 1);
    scrollX = SCREEN_WIDTH;
    scrollFrameIntervalMs = frameDelayMs;
    lastScrollFrame = millis();
    scrollActive = true;
}

void updateScroll()
{
    if (!scrollActive)
    {
        return;
    }
    if (millis() - lastScrollFrame < scrollFrameIntervalMs)
    {
        return;
    }
    lastScrollFrame = millis();

    display.clearDisplay();
    drawFrame();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(scrollX, (SCREEN_HEIGHT / 2) - 4);
    display.print(scrollText);
    display.display();

    scrollX -= 2;
    if (scrollX <= -scrollTextWidth)
    {
        scrollActive = false;
    }
}

// ---- example receiver hooks ----
// wire these into whatever passes text over serial/radio

void onPlainTextReceived(const String &text)
{
    displayPlain(text);
}

void onBoxedTextReceived(const String &text)
{
    displayBoxed(text);
}

void onTitledTextReceived(const String &title, const String &text)
{
    displayTitled(title, text);
}

void onCenteredTextReceived(const String &text)
{
    displayCentered(text);
}

void onAlertTextReceived(const String &text)
{
    displayAlert(text);
}

void onScrollTextReceived(const String &text)
{
    displayScroll(text);
}

void initOledDisplay()
{
    Wire.begin(OLED_SDA_PIN, OLED_SCL_PIN);
    if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR))
    {
        Serial.println(F("OLED init failed at 0x3C, try OLED_ADDR 0x3D"));
        return;
    }
    display.clearDisplay();
    displayTitled("RADIO LINK", "Waiting for data...");
}

void passthroughUsbToLora()
{
    while (Serial.available())
    {
        char c = (char)Serial.read();
        if (c == '\r') // drop CR, avoids \r\r\n when Monitor sends "Both NL & CR"
        {
            continue;
        }
        if (c == '\n') // '\n' -> '\r\n' so Enter sends 0D 0A
        {
            Serial1.write('\r');
            Serial1.write('\n');
        }
        else
        {
            Serial1.write(c);
        }
    }
}

String loraRxLine = "";

// returns a completed line once '\n' is seen, "" otherwise (call every loop)
String passthroughLoraToUsb()
{
    while (Serial1.available())
    {
        char c = (char)Serial1.read();
        Serial.write(c);

        if (c == '\n')
        {
            loraRxLine.trim();
            String completedLine = loraRxLine;
            loraRxLine = "";
            if (completedLine.length() > 0)
            {
                return completedLine;
            }
        }
        else if (c != '\r')
        {
            loraRxLine += c;
        }
    }
    return "";
}

void callRandomReceiver()
{
    switch (random(6))
    {
    case 0:
        onPlainTextReceived("Plain text mode");
        break;
    case 1:
        onBoxedTextReceived("Boxed text mode with wrapped content");
        break;
    case 2:
        onTitledTextReceived("STATUS", "Titled mode body text");
        break;
    case 3:
        onCenteredTextReceived("OK");
        break;
    case 4:
        onAlertTextReceived("Signal lost");
        break;
    case 5:
        onScrollTextReceived("Scrolling marquee text demo");
        break;
    }
}

unsigned long lastDemoUpdate = 0;
const unsigned long demoIntervalMs = 2000;

void updateOledDemo()
{
    if (millis() - lastDemoUpdate >= demoIntervalMs)
    {
        lastDemoUpdate = millis();
        callRandomReceiver();
    }
}
