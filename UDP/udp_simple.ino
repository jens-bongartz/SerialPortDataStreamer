#include <ESP8266WiFi.h>
#include <WiFiUdp.h>

const char* ssid = "Raspi-Wifi-2.4";                       // Darf bis zu 32 Zeichen haben.
const char* password = "raspi01-wifi";            // Mindestens 8 Zeichen jedoch nicht länger als 64 Zeichen.
unsigned long previousMillis = 0;

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
}

void loop() {
  if (millis() - previousMillis >= 10) {
    previousMillis = millis();
    sendUdp(25);                  
  }
}

void sendUdp(int adc_value) {
  Udp.beginPacket(unicastIP, PORT);
  Udp.printf("EKG:%i,t:10\r\n", adc_value);
  Udp.endPacket();
  //Serial.println("Package sent!");
}
