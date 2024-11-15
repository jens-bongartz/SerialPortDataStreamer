#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include "ESP8266TimerInterrupt.h"                 //https://github.com/khoih-prog/ESP8266TimerInterrupt

#define faADC 120
#define packetSize 10

// Select a Timer Clock
#define USING_TIM_DIV1                true           // for shortest and most accurate timer
#define USING_TIM_DIV16               false           // for medium time and medium accurate timer
#define USING_TIM_DIV256              false            // for longest timer but least accurate. Default
// Init ESP8266 only and only Timer 1
ESP8266Timer ITimer;

const char* ssid = "Raspi-Wifi-2.4";                       // Darf bis zu 32 Zeichen haben.
const char* password = "raspi01-wifi";            // Mindestens 8 Zeichen jedoch nicht länger als 64 Zeichen.
unsigned long previousMillis = 0;
int packetCounter = 0;
char packetBuffer[25 * packetSize];

WiFiUDP Udp;
IPAddress unicastIP(192, 168, 1, 4);                  // Adresse des Esp, welcher als Empfänger der Nachricht dient, eintragen.
constexpr uint16_t PORT = 8266;                          // UDP Port an welchen gesendet wird.

void setup() {
  Serial.begin(115200);
  delay(100);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nVerbunden mit: " + WiFi.SSID());
  ITimer.attachInterruptInterval(1000000/faADC, readADC);
}

void loop() {
}

void readADC() {
  int adcValue = analogRead(0);
  char mString[25];
  sprintf(mString,"EKG:%i,t:%lu\r\n", adcValue,millis());
  strcat(packetBuffer,mString);
  packetCounter++;
  if (packetCounter > packetSize-1) {
     Udp.beginPacket(unicastIP, PORT);
     Udp.write(packetBuffer);
     Udp.endPacket();
     packetCounter = 0;
     packetBuffer[0] = '\0';
  }
}
