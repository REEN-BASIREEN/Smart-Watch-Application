import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GraphPage extends StatefulWidget {
  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  DateTime selectedDate =
      DateTime.now(); // วันที่ที่เลือก (ค่าเริ่มต้นเป็นวันนี้)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Graph (Select a Date)'),
      ),
      body: Column(
        children: [
          // ส่วนเลือกวันที่
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now()
                          .subtract(Duration(days: 7)), // ย้อนหลัง 7 วัน
                      lastDate: DateTime.now(), // วันนี้
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate; // อัปเดตวันที่ที่เลือก
                      });
                    }
                  },
                  child: Text('Select Date'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users') // คอลเล็กชัน 'users'
                  .doc(FirebaseAuth.instance.currentUser!
                      .uid) // ใช้ userId จาก Firebase Authentication
                  .collection('data') // คอลเล็กชัน 'data' ของผู้ใช้
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final List<QueryDocumentSnapshot> documents =
                    snapshot.data!.docs;

                List<FlSpot> hrSpots = [];
                List<FlSpot> o2Spots = [];
                List<FlSpot> tempSpots = [];
                List<String> timeLabels = []; // เก็บเวลาที่แสดงในกราฟ

                for (var doc in documents) {
                  var data = doc.data() as Map<String, dynamic>;
                  double heartRate = (data['Heart Rate'] ?? 0).toDouble();
                  double oxygen = (data['O2'] ?? 0).toDouble();
                  double temperature = (data['Temperature'] ?? 0).toDouble();
                  Timestamp timestamp = data['timestamp'] as Timestamp;

                  final DateTime time = timestamp.toDate();
                  final double timeInHours = time.hour + time.minute / 60;

                  // ตรวจสอบว่า timestamp ตรงกับวันที่ที่เลือก
                  if (time.year == selectedDate.year &&
                      time.month == selectedDate.month &&
                      time.day == selectedDate.day) {
                    hrSpots.add(FlSpot(timeInHours, heartRate));
                    o2Spots.add(FlSpot(timeInHours, oxygen));
                    tempSpots.add(FlSpot(timeInHours, temperature));

                    String formattedTime =
                        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                    timeLabels.add(formattedTime);
                  }
                }

                if (hrSpots.isEmpty && o2Spots.isEmpty && tempSpots.isEmpty) {
                  return Center(
                      child: Text('No data available for selected date.'));
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      // แสดงชื่อกราฟ Heart Rate
                      Text(
                        'Heart Rate',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 300, // ความสูงคงเดิม
                        width: MediaQuery.of(context).size.width *
                            0.5, // ความกว้างเหลือครึ่งหนึ่งของหน้าจอ
                        child: _buildLineChart(
                            hrSpots, timeLabels, Colors.red, 240, 20, 0),
                      ),
                      SizedBox(height: 16),
                      // แสดงชื่อกราฟ Oxygen Saturation
                      Text(
                        'Oxygen Saturation',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 300, // ความสูงคงเดิม
                        width: MediaQuery.of(context).size.width *
                            0.5, // ความกว้างเหลือครึ่งหนึ่งของหน้าจอ
                        child: _buildLineChart(
                            o2Spots, timeLabels, Colors.blue, 100, 10, 0),
                      ),
                      SizedBox(height: 16),
                      // แสดงชื่อกราฟ Body Temperature
                      Text(
                        'Body Temperature',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 300, // ความสูงคงเดิม
                        width: MediaQuery.of(context).size.width *
                            0.5, // ความกว้างเหลือครึ่งหนึ่งของหน้าจอ
                        child: _buildLineChart(
                            tempSpots, timeLabels, Colors.green, 45, 3, 30),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots, List<String> timeLabels,
      Color color, double maxValue, double step, double minValue) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (value, meta) {
                int hour = value.toInt();
                int minute = ((value - hour) * 60).toInt();
                return Text(
                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: step,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)), // ซ่อนตัวเลขด้านบน
          rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)), // ซ่อนตัวเลขด้านขวา
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black12, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: color,
            barWidth: 4,
            spots: spots.isNotEmpty
                ? spots
                : [FlSpot(0, 0)], // ถ้าไม่มีข้อมูลให้แสดงจุด (0, 0)
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minX: 0,
        maxX: 23.59,
        minY: minValue,
        maxY: maxValue,
      ),
    );
  }
}
