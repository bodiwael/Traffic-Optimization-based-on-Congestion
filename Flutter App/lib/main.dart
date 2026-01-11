import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SmartTrafficApp());
}

class SmartTrafficApp extends StatelessWidget {
  const SmartTrafficApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Traffic Control',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          elevation: 4,
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),
      home: const TrafficDashboard(),
    );
  }
}

class TrafficDashboard extends StatefulWidget {
  const TrafficDashboard({Key? key}) : super(key: key);

  @override
  State<TrafficDashboard> createState() => _TrafficDashboardState();
}

class _TrafficDashboardState extends State<TrafficDashboard> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Sensor data
  double distance1 = 0;
  double distance2 = 0;
  double distance3 = 0;
  String zone1Status = "CLEAR";
  String zone2Status = "CLEAR";
  String zone3Status = "CLEAR";

  // Air quality
  int mq135Raw = 0;
  String airQuality = "GOOD";

  // Traffic control
  String light1Status = "green";
  String light2Status = "red";
  String trafficStatus = "LOW_TRAFFIC";
  int detectionsCount = 0;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to ultrasonic sensors
    _database.child('sensors/current/ultrasonic1').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          distance1 = (data['distance'] ?? 0).toDouble();
          zone1Status = data['status'] ?? "CLEAR";
        });
      }
    });

    _database.child('sensors/current/ultrasonic2').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          distance2 = (data['distance'] ?? 0).toDouble();
          zone2Status = data['status'] ?? "CLEAR";
        });
      }
    });

    _database.child('sensors/current/ultrasonic3').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          distance3 = (data['distance'] ?? 0).toDouble();
          zone3Status = data['status'] ?? "CLEAR";
        });
      }
    });

    // Listen to MQ-135
    _database.child('sensors/current/mq135').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          mq135Raw = data['raw'] ?? 0;
          airQuality = data['air_quality'] ?? "GOOD";
        });
      }
    });

    // Listen to traffic control
    _database.child('traffic').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          light1Status = data['light1'] ?? "green";
          light2Status = data['light2'] ?? "red";
          trafficStatus = data['status'] ?? "LOW_TRAFFIC";
          detectionsCount = data['detections'] ?? 0;
        });
      }
    });
  }

  Color _getLightColor(String status) {
    switch (status.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getTrafficStatusColor() {
    switch (trafficStatus) {
      case 'HIGH_TRAFFIC':
        return Colors.red;
      case 'MEDIUM_TRAFFIC':
        return Colors.orange;
      case 'LOW_TRAFFIC':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrafficIcon() {
    switch (trafficStatus) {
      case 'HIGH_TRAFFIC':
        return Icons.traffic;
      case 'MEDIUM_TRAFFIC':
        return Icons.warning;
      case 'LOW_TRAFFIC':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getTrafficDescription() {
    switch (trafficStatus) {
      case 'HIGH_TRAFFIC':
        return '2-3 sensors detected objects (<10cm)';
      case 'MEDIUM_TRAFFIC':
        return '1 sensor detected object (<10cm)';
      case 'LOW_TRAFFIC':
        return 'No objects detected (<10cm)';
      default:
        return 'Unknown traffic status';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🚦 Smart Traffic Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Traffic Status Header
            _buildTrafficStatusCard(),
            const SizedBox(height: 20),

            // Traffic Lights Display
            Row(
              children: [
                Expanded(
                  child: _buildTrafficLight(
                    'Traffic Light 1',
                    light1Status,
                    'Intersection A',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTrafficLight(
                    'Traffic Light 2',
                    light2Status,
                    'Intersection B',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Traffic Control Logic Explanation
            _buildLogicCard(),
            const SizedBox(height: 20),

            // Distance Sensors Chart
            _buildSensorChart(),
            const SizedBox(height: 20),

            // Zone Details
            _buildZoneCard('Zone 1 (Left)', distance1, zone1Status, Colors.blue),
            const SizedBox(height: 12),
            _buildZoneCard('Zone 2 (Center)', distance2, zone2Status, Colors.purple),
            const SizedBox(height: 12),
            _buildZoneCard('Zone 3 (Right)', distance3, zone3Status, Colors.orange),
            const SizedBox(height: 20),

            // Air Quality
            _buildAirQualityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficStatusCard() {
    return Card(
      color: _getTrafficStatusColor().withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _getTrafficIcon(),
              size: 64,
              color: _getTrafficStatusColor(),
            ),
            const SizedBox(height: 12),
            Text(
              trafficStatus.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _getTrafficStatusColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getTrafficDescription(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _getTrafficStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getTrafficStatusColor()),
              ),
              child: Text(
                '$detectionsCount Detections',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getTrafficStatusColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficLight(String title, String status, String location) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              location,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            // Traffic light display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildLightBulb(Colors.red, status == 'red'),
                  const SizedBox(height: 8),
                  _buildLightBulb(Colors.yellow, status == 'yellow'),
                  const SizedBox(height: 8),
                  _buildLightBulb(Colors.green, status == 'green'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getLightColor(status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightBulb(Color color, bool isActive) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? color : Colors.grey[800],
        boxShadow: isActive
            ? [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ]
            : null,
      ),
    );
  }

  Widget _buildLogicCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[300]),
                const SizedBox(width: 8),
                const Text(
                  'Traffic Control Logic',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLogicRow(
              '🔴 HIGH TRAFFIC',
              '2-3 sensors detect (<10cm)',
              'Light 1: RED 🔴 | Light 2: GREEN 🟢',
              Colors.red,
              trafficStatus == 'HIGH_TRAFFIC',
            ),
            const Divider(height: 24),
            _buildLogicRow(
              '🟡 MEDIUM TRAFFIC',
              '1 sensor detects (<10cm)',
              'Light 1: YELLOW 🟡 | Light 2: YELLOW 🟡',
              Colors.orange,
              trafficStatus == 'MEDIUM_TRAFFIC',
            ),
            const Divider(height: 24),
            _buildLogicRow(
              '🟢 LOW TRAFFIC',
              '0 sensors detect (<10cm)',
              'Light 1: GREEN 🟢 | Light 2: RED 🔴',
              Colors.green,
              trafficStatus == 'LOW_TRAFFIC',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogicRow(String title, String condition, String action, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : Colors.grey[700]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.grey[300],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            condition,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action,
            style: TextStyle(
              fontSize: 13,
              color: isActive ? color : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distance Sensors (cm)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: distance1 == 999 ? 0 : distance1,
                          color: distance1 < 10 ? Colors.red : Colors.blue,
                          width: 40,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: distance2 == 999 ? 0 : distance2,
                          color: distance2 < 10 ? Colors.red : Colors.purple,
                          width: 40,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: distance3 == 999 ? 0 : distance3,
                          color: distance3 < 10 ? Colors.red : Colors.orange,
                          width: 40,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Zone 1');
                            case 1:
                              return const Text('Zone 2');
                            case 2:
                              return const Text('Zone 3');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      if (value == 10) {
                        return FlLine(
                          color: Colors.red,
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        );
                      }
                      return FlLine(
                        color: Colors.grey[800],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 3,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  '10cm Detection Threshold',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(String title, double distance, String status, Color color) {
    bool isDetecting = distance < 10 && distance != 999;
    return Card(
      color: isDetecting ? Colors.red.withOpacity(0.1) : const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDetecting ? Icons.sensors : Icons.sensors_off,
                color: isDetecting ? Colors.red : color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distance == 999 ? 'OUT OF RANGE' : '${distance.toStringAsFixed(1)} cm',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDetecting ? Colors.red.withOpacity(0.2) : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDetecting ? Colors.red : color),
              ),
              child: Text(
                isDetecting ? 'DETECTING' : status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDetecting ? Colors.red : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirQualityCard() {
    Color aqColor = airQuality == 'GOOD'
        ? Colors.green
        : airQuality == 'MODERATE'
        ? Colors.orange
        : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.air, color: aqColor, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Air Quality (MQ-135)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      airQuality,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: aqColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Raw Value',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mq135Raw.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}