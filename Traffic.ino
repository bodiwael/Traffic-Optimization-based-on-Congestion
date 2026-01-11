#include <Wire.h>
#include <WiFi.h>
#include <FirebaseESP32.h>

// WiFi Credentials
const char* WIFI_SSID = "ITIDA";
const char* WIFI_PASSWORD = "12345678";

// Firebase Credentials
const char* FIREBASE_HOST = "stem-53cdc-default-rtdb.firebaseio.com";
const char* FIREBASE_AUTH = "UlqdAaYSCRjTcqFBRVW0df1Y513SLgoJ2vuZ2lZO";

// Firebase objects
FirebaseData fbData;
FirebaseAuth auth;
FirebaseConfig config;

// Traffic Light 1 Pins (Intersection A)
const int RED_1 = 13;
const int YELLOW_1 = 12;
const int GREEN_1 = 14;

// Traffic Light 2 Pins (Intersection B)
const int RED_2 = 27;
const int YELLOW_2 = 26;
const int GREEN_2 = 25;

// Sensor readings from Firebase
float distance1 = 0;
float distance2 = 0;
float distance3 = 0;

// Detection threshold
const float DETECTION_THRESHOLD = 10.0; // 10 cm

// Timing
unsigned long previousMillis = 0;
const unsigned long READ_INTERVAL = 1000; // Read Firebase every 1 second

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║  SMART TRAFFIC LIGHT SYSTEM            ║");
  Serial.println("║  Firebase-Controlled via Sensors       ║");
  Serial.println("╚════════════════════════════════════════╝\n");
  
  // Initialize traffic light pins
  pinMode(RED_1, OUTPUT);
  pinMode(YELLOW_1, OUTPUT);
  pinMode(GREEN_1, OUTPUT);
  pinMode(RED_2, OUTPUT);
  pinMode(YELLOW_2, OUTPUT);
  pinMode(GREEN_2, OUTPUT);
  
  // Turn off all lights initially
  allLightsOff();
  
  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("→ Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✓ WiFi Connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  
  // Configure Firebase
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  Serial.println("✓ Firebase Connected!");
  
  // Initialize traffic control status in Firebase
  Firebase.setString(fbData, "/traffic/control_mode", "sensor_based");
  Firebase.setInt(fbData, "/traffic/detection_threshold_cm", DETECTION_THRESHOLD);
  
  Serial.println("\n✓ System Ready!");
  Serial.println("Reading sensor data from Firebase...\n");
}

void loop() {
  unsigned long currentMillis = millis();
  
  // Read sensor data from Firebase periodically
  if (currentMillis - previousMillis >= READ_INTERVAL) {
    previousMillis = currentMillis;
    
    // Read ultrasonic distances from Firebase
    if (Firebase.getFloat(fbData, "/sensors/current/ultrasonic1/distance")) {
      distance1 = fbData.floatData();
    }
    if (Firebase.getFloat(fbData, "/sensors/current/ultrasonic2/distance")) {
      distance2 = fbData.floatData();
    }
    if (Firebase.getFloat(fbData, "/sensors/current/ultrasonic3/distance")) {
      distance3 = fbData.floatData();
    }
    
    // Count how many sensors detect objects within threshold
    int detectionsCount = 0;
    
    if (distance1 < DETECTION_THRESHOLD && distance1 != 999) {
      detectionsCount++;
    }
    if (distance2 < DETECTION_THRESHOLD && distance2 != 999) {
      detectionsCount++;
    }
    if (distance3 < DETECTION_THRESHOLD && distance3 != 999) {
      detectionsCount++;
    }
    
    // Apply traffic light logic
    applyTrafficLogic(detectionsCount);
    
    // Display current status
    displayStatus(detectionsCount);
  }
  
  delay(100);
}

void applyTrafficLogic(int detectionsCount) {
  String status = "";
  
  if (detectionsCount >= 2) {
    // 2 or 3 sensors detect: Light 1 RED, Light 2 GREEN
    setLight1(RED_1);
    setLight2(GREEN_2);
    status = "HIGH_TRAFFIC";
    
    // Update Firebase
    Firebase.setString(fbData, "/traffic/light1", "red");
    Firebase.setString(fbData, "/traffic/light2", "green");
    Firebase.setString(fbData, "/traffic/status", status);
    Firebase.setInt(fbData, "/traffic/detections", detectionsCount);
    
    Serial.println("→ HIGH TRAFFIC: Light1=RED | Light2=GREEN");
    
  } else if (detectionsCount == 1) {
    // 1 sensor detects: Both lights YELLOW
    setLight1(YELLOW_1);
    setLight2(YELLOW_2);
    status = "MEDIUM_TRAFFIC";
    
    // Update Firebase
    Firebase.setString(fbData, "/traffic/light1", "yellow");
    Firebase.setString(fbData, "/traffic/light2", "yellow");
    Firebase.setString(fbData, "/traffic/status", status);
    Firebase.setInt(fbData, "/traffic/detections", detectionsCount);
    
    Serial.println("→ MEDIUM TRAFFIC: Light1=YELLOW | Light2=YELLOW");
    
  } else {
    // No detections: Light 1 GREEN, Light 2 RED (default flow)
    setLight1(GREEN_1);
    setLight2(RED_2);
    status = "LOW_TRAFFIC";
    
    // Update Firebase
    Firebase.setString(fbData, "/traffic/light1", "green");
    Firebase.setString(fbData, "/traffic/light2", "red");
    Firebase.setString(fbData, "/traffic/status", status);
    Firebase.setInt(fbData, "/traffic/detections", detectionsCount);
    
    Serial.println("→ LOW TRAFFIC: Light1=GREEN | Light2=RED");
  }
}

void setLight1(int activePin) {
  digitalWrite(RED_1, activePin == RED_1 ? HIGH : LOW);
  digitalWrite(YELLOW_1, activePin == YELLOW_1 ? HIGH : LOW);
  digitalWrite(GREEN_1, activePin == GREEN_1 ? HIGH : LOW);
}

void setLight2(int activePin) {
  digitalWrite(RED_2, activePin == RED_2 ? HIGH : LOW);
  digitalWrite(YELLOW_2, activePin == YELLOW_2 ? HIGH : LOW);
  digitalWrite(GREEN_2, activePin == GREEN_2 ? HIGH : LOW);
}

void allLightsOff() {
  digitalWrite(RED_1, LOW);
  digitalWrite(YELLOW_1, LOW);
  digitalWrite(GREEN_1, LOW);
  digitalWrite(RED_2, LOW);
  digitalWrite(YELLOW_2, LOW);
  digitalWrite(GREEN_2, LOW);
}

void displayStatus(int detectionsCount) {
  Serial.println("╔════════════════════════════════════════╗");
  Serial.println("║     TRAFFIC CONTROL STATUS             ║");
  Serial.println("╠════════════════════════════════════════╣");
  
  Serial.print("║ Zone 1 Distance:  ");
  Serial.print(distance1, 1);
  Serial.print(" cm");
  printSpaces(String(distance1, 1).length() + 3, 23);
  Serial.println("║");
  
  Serial.print("║ Zone 2 Distance:  ");
  Serial.print(distance2, 1);
  Serial.print(" cm");
  printSpaces(String(distance2, 1).length() + 3, 23);
  Serial.println("║");
  
  Serial.print("║ Zone 3 Distance:  ");
  Serial.print(distance3, 1);
  Serial.print(" cm");
  printSpaces(String(distance3, 1).length() + 3, 23);
  Serial.println("║");
  
  Serial.println("╠════════════════════════════════════════╣");
  
  Serial.print("║ Detections (<10cm): ");
  Serial.print(detectionsCount);
  printSpaces(String(detectionsCount).length(), 18);
  Serial.println("║");
  
  Serial.print("║ Traffic Light 1:   ");
  if (digitalRead(RED_1)) Serial.print("RED    ");
  else if (digitalRead(YELLOW_1)) Serial.print("YELLOW ");
  else if (digitalRead(GREEN_1)) Serial.print("GREEN  ");
  printSpaces(7, 13);
  Serial.println("║");
  
  Serial.print("║ Traffic Light 2:   ");
  if (digitalRead(RED_2)) Serial.print("RED    ");
  else if (digitalRead(YELLOW_2)) Serial.print("YELLOW ");
  else if (digitalRead(GREEN_2)) Serial.print("GREEN  ");
  printSpaces(7, 13);
  Serial.println("║");
  
  Serial.println("╚════════════════════════════════════════╝\n");
}

void printSpaces(int used, int total) {
  for(int i = used; i < total; i++) {
    Serial.print(" ");
  }
}
