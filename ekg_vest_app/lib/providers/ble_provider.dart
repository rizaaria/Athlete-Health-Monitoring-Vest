import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';

class BLEProvider extends ChangeNotifier {
  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  bool isConnected = false;
  List<ScanResult> scanResults = [];

  // Sensor Data
  double ecg = 0;
  double temp = 0;
  double bpm = 0;
  double spo2 = 0;
  double rr = 0;
  
  // Real-time ECG data for waveform
  List<double> ecgHistory = [];

  // Historical data for charts (last 50 points)
  List<double> hrHistory = [];
  List<double> spo2History = [];
  List<double> rrHistory = [];
  List<double> tempHistory = [];

  // All session data for CSV export
  List<List<dynamic>> sessionData = [["Timestamp", "ECG", "Temp", "BPM", "SpO2", "RR"]];
  
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _characteristicSubscription;

  Future<bool> startScan() async {
    // Check if bluetooth is on
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      return false; // Bluetooth is off
    }

    isScanning = true;
    scanResults.clear();
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        scanResults = results;
        notifyListeners();
      });

      Future.delayed(const Duration(seconds: 15), () {
        stopScan();
      });
      return true;
    } catch (e) {
      debugPrint("Scan Error: $e");
      isScanning = false;
      notifyListeners();
      return false;
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  void clearSessionData() {
    sessionData = [["Timestamp", "ECG", "Temp", "BPM", "SpO2", "RR"]];
    ecgHistory.clear();
    hrHistory.clear();
    spo2History.clear();
    rrHistory.clear();
    tempHistory.clear();
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    stopScan();
    clearSessionData();
    try {
      await device.connect();
      connectedDevice = device;
      isConnected = true;
      notifyListeners();

      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          isConnected = false;
          connectedDevice = null;
          notifyListeners();
        }
      });

      discoverServices(device);
    } catch (e) {
      debugPrint("Connect Error: $e");
    }
  }

  void disconnect() {
    connectedDevice?.disconnect();
    isConnected = false;
    connectedDevice = null;
    notifyListeners();
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == serviceUUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristicUUID) {
            subscribeToCharacteristic(characteristic);
          }
        }
      }
    }
  }

  Future<void> subscribeToCharacteristic(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    _characteristicSubscription = characteristic.onValueReceived.listen((value) {
      String data = utf8.decode(value).trim();
      _parseData(data);
    });
  }

  int _packetCounter = 0;

  void _parseData(String data) {
    try {
      List<String> parts = data.split(',');
      if (parts.length >= 5) {
        double rawEcg = double.tryParse(parts[0]) ?? 0;
        
        // Simple Moving Average Filter untuk ECG agar tidak terlalu loncat/tajam
        if (ecgHistory.isNotEmpty) {
          ecg = (ecgHistory.last * 0.6) + (rawEcg * 0.4);
        } else {
          ecg = rawEcg;
        }

        temp = double.tryParse(parts[1]) ?? 0;
        bpm = double.tryParse(parts[2]) ?? 0;
        spo2 = double.tryParse(parts[3]) ?? 0;
        rr = double.tryParse(parts[4]) ?? 0;

        _packetCounter++;
        // Add ECG to realtime history (max 150 points for ~3 seconds at 50Hz)
        ecgHistory.add(ecg);
        if (ecgHistory.length > 150) {
          ecgHistory.removeAt(0);
        }

        // Add to history once every 50 packets (approx 1 second)
        // This ensures the graph shows a 50-second trend instead of a 1-second blur.
        if (_packetCounter >= 50) {
          _packetCounter = 0;
          if (bpm > 0) hrHistory.add(bpm);
          if (spo2 > 0) spo2History.add(spo2);
          if (rr > 0) rrHistory.add(rr);
          if (temp > 0) tempHistory.add(temp);

          if (hrHistory.length > 50) hrHistory.removeAt(0);
          if (spo2History.length > 50) spo2History.removeAt(0);
          if (rrHistory.length > 50) rrHistory.removeAt(0);
          if (tempHistory.length > 50) tempHistory.removeAt(0);
        }
        
        sessionData.add([DateTime.now().toIso8601String(), ecg, temp, bpm, spo2, rr]);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Parse error: $e");
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    super.dispose();
  }

  Future<void> exportCSV() async {
    if (sessionData.length <= 1) return; // No data

    try {
      String csv = sessionData.map((row) => row.join(',')).join('\n');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/AthleteData_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Athlete Health Data Export');
    } catch (e) {
      debugPrint("Error exporting CSV: $e");
    }
  }
}
