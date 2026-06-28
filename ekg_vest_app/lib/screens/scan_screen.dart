import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleProvider = context.watch<BLEProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Hubungkan Perangkat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              // Radar Animation Placeholder
              SizedBox(
                height: 250,
                width: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 1; i <= 4; i++)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Container(
                            width: 60.0 * i + (_controller.value * 20),
                            height: 60.0 * i + (_controller.value * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00B4D8)
                                    .withValues(alpha: 1.0 - (i * 0.2)),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00B4D8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Device List
              Expanded(
                child: bleProvider.isConnected
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bluetooth_connected, size: 60, color: Colors.green),
                            const SizedBox(height: 16),
                            Text(
                              "Terhubung ke ${bleProvider.connectedDevice?.platformName ?? 'Perangkat'}",
                              style: const TextStyle(
                                color: Colors.green, 
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: 200,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  bleProvider.disconnect();
                                },
                                icon: const Icon(Icons.bluetooth_disabled),
                                label: const Text(
                                  'Disconnect',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: bleProvider.scanResults.length,
                        itemBuilder: (context, index) {
                          final result = bleProvider.scanResults[index];
                          final deviceName = result.device.platformName.isNotEmpty
                              ? result.device.platformName
                              : 'Unknown Device';

                          // Optional: filter for "EKGVest_BLE" to make it cleaner
                          if (deviceName == 'Unknown Device') {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2E35),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth,
                                  color: Color(0xFF00B4D8)),
                              title: Text(deviceName),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00B4D8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  bleProvider.connectToDevice(result.device);
                                },
                                child: const Text('Connect'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              // Scan Button (Only show if not connected)
              if (!bleProvider.isConnected)
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4D8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: bleProvider.isScanning
                        ? null
                        : () async {
                            bool success = await bleProvider.startScan();
                            if (!success) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Harap nyalakan Bluetooth terlebih dahulu!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: Text(
                        bleProvider.isScanning ? 'Mencari...' : 'Scan Ulang',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
