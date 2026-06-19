```markdown
# Athlete Health Monitoring Vest

## Overview

The Athlete Health Monitoring Vest is an IoT-based wearable system designed to monitor physiological parameters of athletes during training and physical activities.

The system utilizes an ESP32-C3 SuperMini microcontroller to acquire Electrocardiography (ECG), blood oxygen saturation (SpO₂), and body temperature data. Sensor data are transmitted wirelessly via Bluetooth Low Energy (BLE) to an Android application for real-time monitoring and visualization.

The project aims to provide a portable and low-power wearable health monitoring solution that supports athlete performance assessment and physiological condition monitoring.

---

## Features

- Real-time ECG monitoring
- Real-time SpO₂ monitoring
- Real-time body temperature monitoring
- Bluetooth Low Energy (BLE) communication
- Android application for data visualization
- Portable battery-powered operation
- Lightweight wearable vest design
- Real-time physiological data transmission

---

## System Architecture

The system consists of three main subsystems:

### Sensor Layer

- Custom ECG Acquisition Module
- MAX30102 SpO₂ Sensor
- MCP9808 Temperature Sensor

### Processing Layer

- ESP32-C3 SuperMini
- Signal acquisition and processing

### Communication Layer

- Bluetooth Low Energy (BLE)
- Flutter-based Android Application

![System Architecture](images/system_architecture.png)

---

## Hardware Components

| Component | Function |
|------------|------------|
| ESP32-C3 SuperMini | Main microcontroller |
| Custom ECG Module | ECG signal acquisition |
| MAX30102 | Blood oxygen saturation monitoring |
| MCP9808 | Body temperature monitoring |
| LiPo Battery 450 mAh | Portable power source |
| TP4056 | Battery charging and protection |
| MT3608 Step-Up Converter | Voltage regulation |

---

## Sensor Configuration

### ECG Monitoring

ECG signals are acquired using a custom-developed ECG acquisition module.

Related Repository:

https://github.com/rizaaria/Biopotential-Signal-Acquisition-ESP32

### SpO₂ Monitoring

Blood oxygen saturation is measured using the MAX30102 optical sensor.

### Temperature Monitoring

Body temperature is measured using the MCP9808 high-accuracy digital temperature sensor.

---

## Sensor Placement

Sensors are positioned to maximize signal quality and user comfort during physical activities.

- ECG electrodes placed on the chest area.
- MAX30102 sensor attached to the ear lobe.
- MCP9808 temperature sensor positioned inside the vest.

![Sensor Placement](images/sensor_placement.png)

---

## Power Management

The wearable device is powered using a rechargeable 450 mAh Lithium Polymer (LiPo) battery.

### Power System Components

- LiPo Battery 450 mAh
- TP4056 Charging Module
- MT3608 Step-Up Converter

The TP4056 module provides charging and battery protection, while the MT3608 boost converter supplies a stable voltage to the system.

![Power Management](images/power_management.png)

---

## Mobile Application

A Flutter-based Android application was developed for real-time monitoring and visualization.

### Features

- ECG waveform visualization
- SpO₂ monitoring
- Temperature monitoring
- Bluetooth connectivity management
- Real-time physiological data updates

![Mobile Application](images/mobile_app.jpg)

---

## Hardware Design

The hardware system was designed to ensure portability, comfort, and stable sensor placement.

### Development Process

- Electronic circuit design
- Sensor integration
- Embedded firmware development
- Mobile application development
- Wearable vest prototyping

![Hardware Assembly](images/hardware_assembly.jpg)

---

## Firmware Development

The firmware was developed using the Arduino Framework for ESP32-C3.

### Main Functions

- Sensor acquisition
- Data processing
- Bluetooth communication
- Power management
- Real-time monitoring

---

## Results

The prototype successfully demonstrated:

- Real-time ECG acquisition
- Real-time SpO₂ monitoring
- Real-time temperature monitoring
- Stable BLE communication
- Portable wearable implementation

### ECG Monitoring Example

![ECG Monitoring](images/ecg_monitoring.jpg)

### Prototype

![Prototype](images/vest_prototype.jpg)

---

## Applications

Potential applications include:

- Athlete health monitoring
- Sports science research
- Fitness tracking
- Rehabilitation monitoring
- Remote physiological monitoring

---

## Technologies Used

### Embedded Systems

- ESP32-C3 SuperMini
- Arduino IDE
- C/C++

### Communication

- Bluetooth Low Energy (BLE)

### Biomedical Instrumentation

- ECG Monitoring
- SpO₂ Monitoring
- Temperature Monitoring

### Mobile Development

- Flutter

---

## Future Development

- Cloud-based data storage
- AI-based fatigue analysis
- Performance analytics dashboard
- Multi-athlete monitoring
- Long-term health tracking

---

## Author

**Riza Aria Komara**

Biomedical Engineering  
Telkom University

GitHub:
https://github.com/rizaaria

LinkedIn:
https://linkedin.com/in/riza-aria-komara

---

## Disclaimer

This project was developed for educational, research, and prototype purposes. It is not intended to replace certified medical devices or professional medical diagnosis.
```
