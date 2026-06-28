import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({Key? key}) : super(key: key);

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  int _selectedMode = 0; // 0: HR, 1: SpO2, 2: RR, 3: Temp

  @override
  Widget build(BuildContext context) {
    final bleProvider = context.watch<BLEProvider>();

    List<double> trendData = bleProvider.hrHistory;

    if (_selectedMode == 1) {
      trendData = bleProvider.spo2History;
    } else if (_selectedMode == 2) {
      trendData = bleProvider.rrHistory;
    } else if (_selectedMode == 3) {
      trendData = bleProvider.tempHistory;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Real-time ECG",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ECG Waveform Graph
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2228),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildEcgChart(bleProvider.ecgHistory),
                ),
              ),
              const SizedBox(height: 24),
              // Digital Values Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDigitalValue("BPM", "${bleProvider.bpm.toInt()}", Colors.redAccent),
                  _buildDigitalValue("SpO2", "${bleProvider.spo2.toInt()}%", Colors.lightBlueAccent),
                  _buildDigitalValue("RR", "${bleProvider.rr.toInt()}", Colors.orangeAccent),
                  _buildDigitalValue("Temp", "${bleProvider.temp.toStringAsFixed(1)}°", Colors.greenAccent),
                ],
              ),
              const SizedBox(height: 24),
              // Trend Section
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2E35),
                  borderRadius: BorderRadius.circular(22.5),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton("HR", 0),
                    _buildSegmentButton("SpO2", 1),
                    _buildSegmentButton("RR", 2),
                    _buildSegmentButton("Temp", 3),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Trend Chart
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.only(right: 16, top: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2228),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildTrendChart(trendData),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00B4D8),
        onPressed: () => bleProvider.exportCSV(),
        child: const Icon(Icons.save, color: Colors.white),
      ),
    );
  }

  Widget _buildDigitalValue(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(String title, int index) {
    final isSelected = _selectedMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMode = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00B4D8) : Colors.transparent,
            borderRadius: BorderRadius.circular(22.5),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEcgChart(List<double> data) {
    if (data.isEmpty) {
      return const Center(child: Text("Waiting for ECG Data...", style: TextStyle(color: Colors.grey)));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(), 
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.greenAccent.withValues(alpha: 0.1), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.greenAccent.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2))),
        minX: 0,
        maxX: 150, 
        minY: -150, // Fix Y-axis agar grafik tidak lompat-lompat (auto-scaling)
        maxY: 150,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false, // Biarkan false agar QRS tajam dan tidak aneh/berdenyut
            color: Colors.greenAccent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<double> data) {
    if (data.isEmpty) {
      return const Center(child: Text("Waiting for Trend Data...", style: TextStyle(color: Colors.grey)));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    double maxDataVal = data.isEmpty ? 120 : data.reduce((curr, next) => curr > next ? curr : next);
    double minDataVal = data.isEmpty ? 0 : data.reduce((curr, next) => curr < next ? curr : next);
    
    double dynamicMaxY = maxDataVal + (maxDataVal * 0.2); 
    double dynamicMinY = minDataVal - (minDataVal * 0.2); 
    if (dynamicMinY < 0) dynamicMinY = 0;
    
    if (_selectedMode == 3) { // Temp
      dynamicMaxY = maxDataVal + 2; 
      dynamicMinY = (minDataVal - 2) > 0 ? (minDataVal - 2) : 0;
      if (dynamicMaxY < 40) dynamicMaxY = 40;
    } else {
      if (dynamicMaxY < 50) dynamicMaxY = 50;
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  _selectedMode == 3 ? barSpot.y.toStringAsFixed(1) : barSpot.y.toInt().toString(),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.1), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}s', style: const TextStyle(color: Colors.grey, fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _selectedMode == 3 ? 1 : 20,
              getTitlesWidget: (value, meta) {
                return Text(
                    _selectedMode == 3 ? value.toStringAsFixed(1) : value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 10));
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        minX: 0,
        maxX: 50,
        minY: dynamicMinY,
        maxY: dynamicMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF00B4D8),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
