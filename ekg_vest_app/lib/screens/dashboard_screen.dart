import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bleProvider = context.watch<BLEProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Athlete Health Monitor',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.75,
                  children: [
                    _buildMetricCard(
                      title: 'HR',
                      value: '${bleProvider.bpm.toInt()}',
                      unit: 'bpm',
                      icon: Icons.favorite,
                      color: const Color(0xFFF05454),
                    ),
                    _buildMetricCard(
                      title: 'SpO2',
                      value: '${bleProvider.spo2.toInt()}',
                      unit: '%',
                      icon: Icons.water_drop,
                      color: const Color(0xFF00B4D8),
                    ),
                    _buildMetricCard(
                      title: 'RR',
                      value: '${bleProvider.rr.toInt()}',
                      unit: 'brpm',
                      icon: Icons.air,
                      color: const Color(0xFF2ECC71),
                    ),
                    _buildMetricCard(
                      title: 'Temp',
                      value: bleProvider.temp.toStringAsFixed(1),
                      unit: '°C',
                      icon: Icons.thermostat,
                      color: const Color(0xFFF39C12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 15),
            Text(
              value,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
