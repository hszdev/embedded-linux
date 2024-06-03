/**
 * WiFiManager advanced demo, contains advanced configurartion options
 * Implements TRIGGEN_PIN button press, press for ondemand configportal, hold for 3 seconds for reset settings.
 */
#include <WiFiManager.h> // https://github.com/tzapu/WiFiManager
#include <EEPROM.h>
#include <PubSubClient.h>
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>

#define TRIGGER_PIN 0

WiFiClient espClient;
PubSubClient client(espClient);
bool wm_nonblocking = false;

WiFiManager wm;

char DEVICE_NAME[40] = "PRESSURE SENSOR";

char MQTT_SERVER[40]     = "192.168.1.248";
char MQTT_SERVERPORT[40] = "1883";
char MQTT_USERNAME[40]   = "";
char MQTT_PASSWORD[40]   = "";
char MQTT_TOPIC[40]      = "feeds/count";

WiFiManagerParameter *custom_mqtt_url;
WiFiManagerParameter *custom_mqtt_port;
WiFiManagerParameter *custom_mqtt_username;
WiFiManagerParameter *custom_mqtt_password;


void eeprom_read()
{
  EEPROM.begin(512);
  EEPROM.get(0, MQTT_SERVER);
  EEPROM.get(50, MQTT_SERVERPORT);
  EEPROM.get(100, MQTT_USERNAME);
  EEPROM.get(150, MQTT_PASSWORD);
  EEPROM.end();
}


void eeprom_saveconfig()
{
  EEPROM.begin(512);
  strcpy(MQTT_SERVER, custom_mqtt_url->getValue());
  strcpy(MQTT_SERVERPORT, custom_mqtt_port->getValue());
  strcpy(MQTT_USERNAME, custom_mqtt_username->getValue());
  strcpy(MQTT_PASSWORD, custom_mqtt_password->getValue());
  EEPROM.put(0, MQTT_SERVER);
  EEPROM.put(50, MQTT_SERVERPORT);
  EEPROM.put(100, MQTT_USERNAME);
  EEPROM.put(150, MQTT_PASSWORD);
  EEPROM.commit();
  EEPROM.end();
}

// wifi
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>
ESP8266WiFiMulti WiFiMulti;
const uint32_t conn_tout_ms = 5000;

// counter
#define GPIO_INTERRUPT_PIN 4
#define DEBOUNCE_TIME 100 
#define BTN_PIN 14
volatile unsigned long count_prev_time;
volatile unsigned long count;

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
  if (! client.connected())
  {
    debug("Connecting to MQTT... ");
    while ((ret = client.connect(DEVICE_NAME, MQTT_USERNAME, MQTT_PASSWORD)) != 0)
    { // connect will return 0 for connected
         debug("Retrying MQTT connection in 5 seconds...");
         client.disconnect();
         delay(5000);  // wait 5 seconds
    }
    debug("MQTT Connected");
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

void setup() {
  WiFi.mode(WIFI_STA); 
  Serial.begin(115200);
  Serial.setDebugOutput(true);  
  delay(3000);
  Serial.println("\n Starting");

  pinMode(GPIO_INTERRUPT_PIN, INPUT_PULLUP);
  pinMode(BTN_PIN, INPUT_PULLUP);


  eeprom_read();
  
  pinMode(TRIGGER_PIN, INPUT);

  custom_mqtt_url = new WiFiManagerParameter("mqtt_server", "MQTT Sever url", MQTT_SERVER, 40);
  custom_mqtt_port = new WiFiManagerParameter("mqtt_port", "MQTT Server port", MQTT_SERVERPORT, 40);
  custom_mqtt_username = new WiFiManagerParameter("mqtt_username", "MQTT Server name", MQTT_USERNAME, 40);
  custom_mqtt_password = new WiFiManagerParameter("mqtt_password", "MQTT password", MQTT_PASSWORD, 40);

  
  wm.addParameter(custom_mqtt_url);
  wm.addParameter(custom_mqtt_port);
  wm.addParameter(custom_mqtt_username);
  wm.addParameter(custom_mqtt_password);
  
  // wm.resetSettings(); // wipe settings

  if(wm_nonblocking) wm.setConfigPortalBlocking(false);

  wm.setSaveParamsCallback(saveParamCallback);

  std::vector<const char *> menu = {"wifi","info","param","sep","restart","exit"};
  wm.setMenu(menu);

  // set dark theme
  wm.setClass("invert");

  wm.setConfigPortalTimeout(30); // auto close configportal after n seconds
  // wm.setCaptivePortalEnable(false); // disable captive portal redirection
  // wm.setAPClientCheck(true); // avoid timeout if client connected to softap

  bool res;
  res = wm.autoConnect("AutoConnectAP","password"); // password protected ap

  if(!res) {
    Serial.println("Failed to connect or hit timeout");
    // ESP.restart();
  } 
  else {
    //if you get here you have connected to the WiFi    
    Serial.println("connected...yeey :)");
  }

  int port = atoi(MQTT_SERVERPORT);
  client.setServer(MQTT_SERVER, port);
  if (client.connect(DEVICE_NAME, MQTT_USERNAME, MQTT_PASSWORD) == false) {
    wm.resetSettings();
  }
}

void saveParamCallback(){
  eeprom_saveconfig();
  Serial.println("Saving parameters");
  
}

void publish_data()
{
  
  Serial.print(millis());
  Serial.println(" Connecting...");
  if((WiFiMulti.run(conn_tout_ms) == WL_CONNECTED))
  {
    mqtt_connect();
    Serial.println("Publishing");
    if (client.publish(MQTT_TOPIC,"Stepped")) {
      Serial.println("Published");
    } else {
      Serial.println("Failed!");
    }
  }
}

void loop() {
  if (digitalRead(BTN_PIN) == LOW) {
    Serial.println("Button pressed");
    publish_data();
    delay(1000);
  }
}
