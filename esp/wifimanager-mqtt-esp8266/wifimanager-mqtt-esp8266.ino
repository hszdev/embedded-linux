

// Embedded Linux (EMLI)
// University of Southern Denmark

// 2022-03-24, Kjeld Jensen, First version

// Configuration
#define WIFI_SSID       "ESP Friendly"
#define WIFI_PASSWORD   "alleskaldoe"
#include <ArduinoJson.h>          //https://github.com/bblanchon/ArduinoJson

// wifi
#include <WiFiManager.h> // https://github.com/tzapu/WiFiManager
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>
ESP8266WiFiMulti WiFiMulti;
const uint32_t conn_tout_ms = 5000;

// Wifimanager
WiFiManager wm;

// Save config callback
bool shouldSaveConfig = false;

//
char MQTT_SERVER[40]     = "192.168.1.248";
char MQTT_SERVERPORT[40] = "1883";
char MQTT_USERNAME[40]   = "";
char MQTT_PASSWORD[40]   = "";
char MQTT_TOPIC[40]      = "/feeds/count";


// counter
#define GPIO_INTERRUPT_PIN 4
#define DEBOUNCE_TIME 100
#define BTN_PIN 14
volatile unsigned long count_prev_time;
volatile unsigned long count;

// mqtt
#include "Adafruit_MQTT.h"
#include "Adafruit_MQTT_Client.h"
WiFiClient wifi_client;
Adafruit_MQTT_Client mqtt(&wifi_client, MQTT_SERVER, atoi(MQTT_SERVERPORT), MQTT_USERNAME, MQTT_PASSWORD);
Adafruit_MQTT_Publish count_mqtt_publish = Adafruit_MQTT_Publish(&mqtt, MQTT_TOPIC);

// publish
#define PUBLISH_INTERVAL 30000
unsigned long prev_post_time;

// debug
#define DEBUG_INTERVAL 2000
unsigned long prev_debug_time;

ICACHE_RAM_ATTR void count_isr()
{
  if (count_prev_time + DEBOUNCE_TIME < millis() || count_prev_time > millis())
  {
    count_prev_time = millis();
    count++;
  }
}

void debug(const char *s)
{
  Serial.print (millis());
  Serial.print (" ");
  Serial.println(s);
}

void mqtt_connect()
{
  int8_t ret;

  // Stop if already connected.
  if (! mqtt.connected())
  {
    debug("Connecting to MQTT... ");
    while ((ret = mqtt.connect()) != 0)
    { // connect will return 0 for connected
      Serial.println(mqtt.connectErrorString(ret));
      debug("Retrying MQTT connection in 5 seconds...");
      mqtt.disconnect();
      delay(5000);  // wait 5 seconds
    }
    debug("MQTT Connected");
  }
}

void loadConfig() {
  if (SPIFFS.begin()) {
    Serial.println("mounted file system");
    if (SPIFFS.exists("/config.json")) {
      //file exists, reading and loading
      Serial.println("reading config file");
      File configFile = SPIFFS.open("/config.json", "r");
      if (configFile) {
        Serial.println("opened config file");
        size_t size = configFile.size();
        // Allocate a buffer to store contents of the file.
        std::unique_ptr<char[]> buf(new char[size]);

        configFile.readBytes(buf.get(), size);
        DynamicJsonDocument json(1024);
        auto deserializeError = deserializeJson(json, buf.get());
        serializeJson(json, Serial);
        if ( ! deserializeError ) {
          Serial.println("\nparsed json");
          strcpy(MQTT_SERVER, json["mqtt_server"]);
          strcpy(MQTT_SERVERPORT, json["mqtt_port"]);
          strcpy(MQTT_USERNAME, json["mqtt_password"]);
          strcpy(MQTT_PASSWORD, json["mqtt_password"]);
        } else {
          Serial.println("failed to load json config");
        }
        configFile.close();
      }
    }
  } else {
    Serial.println("failed to mount FS");
  }
}

void saveConfigCallback() {
  if (SPIFFS.begin()) {
    Serial.println("mounted file system");
    if (SPIFFS.exists("/config.json")) {
      //file exists, reading and loading
      Serial.println("reading config file");
      File configFile = SPIFFS.open("/config.json", "r");
      if (configFile) {
        Serial.println("saving config");
        DynamicJsonDocument json(1024);
        json["mqtt_server"] = MQTT_SERVER;
        json["mqtt_port"] = MQTT_SERVERPORT;
        json["mqtt_password"] = MQTT_USERNAME;
        json["mqtt_password"] = MQTT_PASSWORD;
        File configFile = SPIFFS.open("/config.json", "w");
        if (!configFile) {
          Serial.println("failed to open config file for writing");
        }

        serializeJson(json, Serial);
        serializeJson(json, configFile);
        configFile.close();
        //end save
      }
    }
  }
}

void print_wifi_status()
{
  Serial.print (millis());
  Serial.print(" WiFi connected: ");
  Serial.print(WiFi.SSID());
  Serial.print(" ");
  Serial.print(WiFi.localIP());
  Serial.print(" RSSI: ");
  Serial.print(WiFi.RSSI());
  Serial.println(" dBm");
}

void setup()
{
  loadConfig(); // load the save config if it exists
  // Wifimanager
  WiFi.mode(WIFI_STA);
  // Add custom parameters
  WiFiManagerParameter custom_mqtt_server("server", "MQTT server", MQTT_SERVER, 40);
  WiFiManagerParameter custom_mqtt_port("port", "MQTT port", MQTT_SERVERPORT, 6);
  WiFiManagerParameter custom_mqtt_user("user", "MQTT username", MQTT_USERNAME, 20);
  WiFiManagerParameter custom_mqtt_pass("pass", "MQTT password", MQTT_PASSWORD, 20);
  WiFiManagerParameter custom_mqtt_topic("topic", "MQTT topic:", MQTT_TOPIC, 20);

  wm.addParameter(&custom_mqtt_server);
  wm.addParameter(&custom_mqtt_port);
  wm.addParameter(&custom_mqtt_user);
  wm.addParameter(&custom_mqtt_pass);
  wm.addParameter(&custom_mqtt_topic);

  // Setup saving of custom parameters
  wm.setSaveConfigCallback(saveConfigCallback);
  // Create frontend menu
  std::vector<const char *> menu = {"wifi", "info", "param", "sep", "restart", "exit"};
  wm.setMenu(menu);
  wm.setClass("invert"); // Dark mode



  // Try and connect to wifi, if fail then go into AP setup mode
  bool res = wm.autoConnect("AutoConnectAP", "password"); // password protected ap

  if (!res) {
    Serial.println("Failed to connect or hit timeout");
    // ESP.restart();
  }
  else {
    //if you get here you have connected to the WiFi
    Serial.println("connected...yeey :)");
  }

  // count
  count_prev_time = millis();
  count = 0;
  pinMode(GPIO_INTERRUPT_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(GPIO_INTERRUPT_PIN), count_isr, RISING);

  pinMode(BTN_PIN, INPUT_PULLUP);

  // serial
  Serial.begin(115200);
  delay(10);
  debug("Boot");

  // wifi
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFiMulti.addAP(WIFI_SSID, WIFI_PASSWORD);
  if (WiFiMulti.run(conn_tout_ms) == WL_CONNECTED)
  {
    print_wifi_status();
  }
  else
  {
    debug("Unable to connect");
  }
}

void publish_data()
{

  Serial.print(millis());
  Serial.println(" Connecting...");
  if ((WiFiMulti.run(conn_tout_ms) == WL_CONNECTED))
  {
    print_wifi_status();

    mqtt_connect();
    if (! count_mqtt_publish.publish("Stepped"))
    {
      debug("MQTT failed");
    }
    else
    {
      debug("MQTT ok");
    }
  }
}

void setupMode() {
  wm.resetSettings();
  ESP.restart();
}

void loop()
{
  if (digitalRead(BTN_PIN) == LOW) {
    // publish_data();
    setupMode();

    delay(50);
  }
}
