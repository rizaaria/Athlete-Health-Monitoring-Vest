#include <Wire.h>
#include "MAX30105.h"
#include "Adafruit_MCP9808.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
/* =========================================================
   ESP32-C3 SuperMini
   FreeRTOS ECG + MAX30102 + MCP9808
   ========================================================= */

/* ================= ECG ================= */
#define ECG_PIN 0
#define SAMPLE_RATE 125

/* ================= SERIAL ================= */
#define BAUD_RATE 115200

/* ================= I2C ================= */
#define SDA_PIN 8
#define SCL_PIN 9

/* ================= MCP9808 ================= */
Adafruit_MCP9808 tempsensor = Adafruit_MCP9808();

/* ================= MAX30102 ================= */
MAX30105 particleSensor;

/* =========================================================
   GLOBAL DATA
   ========================================================= */

volatile float ecgSignal = 0;

float bpmAvg = 0;
float spo2Filtered = 0;
float tempC = 0;
float rrAvg = 0; // Respiration Rate

// BLE Variables
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      BLEDevice::startAdvertising();
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};
long irRaw = 0;
long redRaw = 0;

/* ================= FILTER ================= */

float irDC = 0, redDC = 0;
const float alphaDC = 0.95;

float irACrms = 0, redACrms = 0;
const float alphaRMS = 0.9;

/* =========================================================
   ECG TASK (HIGH PRIORITY)
   ========================================================= */

void ECGTask(void *pvParameters)
{
  TickType_t xLastWakeTime = xTaskGetTickCount();

  const TickType_t xFrequency =
    pdMS_TO_TICKS(1000 / SAMPLE_RATE);

  while (1)
  {
    float raw = analogRead(ECG_PIN);

    ecgSignal = ECGFilter(raw);

    vTaskDelayUntil(&xLastWakeTime, xFrequency);
  }
}

/* =========================================================
   MAX30102 TASK
   ========================================================= */

void MAXTask(void *pvParameters)
{
  while (1)
  {
    irRaw = particleSensor.getIR();
    redRaw = particleSensor.getRed();

    /* ===== SIMPLE BPM ===== */
    static float prevIR = 0;
    static unsigned long lastBeat = 0;

    float irAC = irRaw - prevIR;
    prevIR = irRaw;

    if (irAC > 1000)
    {
      unsigned long now = millis();

      unsigned long period = now - lastBeat;

      if (period > 300 && period < 2000)
      {
        bpmAvg = 60000.0 / period;
      }

      lastBeat = now;
    }

    /* ===== SIMPLE SpO2 ===== */
    if (irRaw > 1000 && redRaw > 1000)
    {
      float R = ((float)redRaw) / ((float)irRaw);

      spo2Filtered = constrain(110.0 - 25.0 * R, 85, 100);
    }

    vTaskDelay(pdMS_TO_TICKS(20));
  }
}

/* =========================================================
   TEMPERATURE TASK
   ========================================================= */

void TempTask(void *pvParameters)
{
  while (1)
  {
    float t = tempsensor.readTempC();
    if (!isnan(t) && t > 10.0 && t < 50.0) {
      tempC = t;
    }

    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}

/* =========================================================
   RESPIRATION RATE (Simple Estimation)
   ========================================================= */
void calcRR() {
  if (bpmAvg > 40) {
    float rawRR = 12.0 + ((bpmAvg - 60.0) * 0.15); 
    if (rawRR < 10) rawRR = 10;
    if (rawRR > 35) rawRR = 35;

    // Moving average filter to smooth RR
    if (rrAvg == 0) {
      rrAvg = rawRR;
    } else {
      rrAvg = (rrAvg * 0.9) + (rawRR * 0.1);
    }
  } else {
    rrAvg = 0;
  }
}

/* =========================================================
   DATA TRANSMISSION TASK (BLE & Serial)
   ========================================================= */

void DataTxTask(void *pvParameters)
{
  while (1)
  {
    calcRR(); // Update RR estimation

    // Create CSV string: ecg,temp,bpm,spo2,rr,ir,red
    char txString[128];
    snprintf(txString, sizeof(txString), "%.2f,%.2f,%.1f,%.1f,%.1f,%ld,%ld",
             ecgSignal, tempC, bpmAvg, spo2Filtered, rrAvg, irRaw, redRaw);

    Serial.println(txString);

    if (deviceConnected && pCharacteristic != NULL) {
      pCharacteristic->setValue(txString);
      pCharacteristic->notify();
    }

    // Handle disconnecting
    if (!deviceConnected && oldDeviceConnected) {
        vTaskDelay(500 / portTICK_PERIOD_MS); // give the bluetooth stack the chance to get things ready
        pServer->startAdvertising(); // restart advertising
        oldDeviceConnected = deviceConnected;
    }
    // Handle connecting
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }

    vTaskDelay(pdMS_TO_TICKS(20)); // ~50Hz update rate
  }
}

/* ========================================================= */

void setup()
{
  Serial.begin(BAUD_RATE);

  Wire.begin(SDA_PIN, SCL_PIN);

  /* ================= MCP9808 ================= */

  tempsensor.begin(0x18);

  /* ================= MAX30102 ================= */

  particleSensor.begin(Wire, I2C_SPEED_FAST);

  particleSensor.setup(
    0x3F,
    4,
    2,
    100,
    411,
    4096
  );

  particleSensor.setPulseAmplitudeRed(0x3F);
  particleSensor.setPulseAmplitudeIR(0x3F);

  /* ================= BLE SETUP ================= */
  
  BLEDevice::init("Athlete Health Monitor");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );
  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();

  /* =====================================================
     CREATE TASKS
     ===================================================== */

  xTaskCreatePinnedToCore(
    ECGTask,
    "ECG Task",
    4096,
    NULL,
    3,
    NULL,
    0
  );

  xTaskCreatePinnedToCore(
    MAXTask,
    "MAX30102 Task",
    4096,
    NULL,
    2,
    NULL,
    0
  );

  xTaskCreatePinnedToCore(
    TempTask,
    "Temp Task",
    2048,
    NULL,
    1,
    NULL,
    0
  );

  xTaskCreatePinnedToCore(
    DataTxTask,
    "Data Tx Task",
    4096,
    NULL,
    1,
    NULL,
    0
  );
}

/* ========================================================= */

void loop()
{
  // Empty
}

/* =========================================================
   ECG FILTER
   ========================================================= */

float ECGFilter(float input)
{
  float output = input;

  {
    static float z1, z2;

    float x = output - 0.70682283*z1 - 0.15621030*z2;

    output =
      0.28064917*x +
      0.56129834*z1 +
      0.28064917*z2;

    z2 = z1;
    z1 = x;
  }

  {
    static float z1, z2;

    float x = output - 0.95028224*z1 - 0.54073140*z2;

    output =
      1.00000000*x +
      2.00000000*z1 +
      1.00000000*z2;

    z2 = z1;
    z1 = x;
  }

  {
    static float z1, z2;

    float x = output - -1.95360385*z1 - 0.95423412*z2;

    output =
      1.00000000*x +
      -2.00000000*z1 +
      1.00000000*z2;

    z2 = z1;
    z1 = x;
  }

  {
    static float z1, z2;

    float x = output - -1.98048558*z1 - 0.98111344*z2;

    output =
      1.00000000*x +
      -2.00000000*z1 +
      1.00000000*z2;

    z2 = z1;
    z1 = x;
  }

  return output;
}