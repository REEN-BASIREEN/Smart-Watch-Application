import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class DetailedGraphsPage extends StatefulWidget {
  final String? initialMetric;
  DetailedGraphsPage({this.initialMetric});

  @override
  _DetailedGraphsPageState createState() => _DetailedGraphsPageState();
}

class _DetailedGraphsPageState extends State<DetailedGraphsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialMetric == 'Heart Rate')
      initialIndex = 0;
    else if (widget.initialMetric == 'O2')
      initialIndex = 1;
    else if (widget.initialMetric == 'Temperature') initialIndex = 2;
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildGraph(String metric, Color color) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('data')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: false)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
              child: Text('ไม่มีข้อมูล', style: TextStyle(fontSize: 18)));
        }

        // เตรียมข้อมูลเฉพาะชั่วโมงที่มีข้อมูลจริง
        List<FlSpot> spots = [];
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          DateTime dt;
          if (data['timestamp'] is Timestamp) {
            dt = (data['timestamp'] as Timestamp).toDate();
          } else if (data['timestamp'] is String) {
            try {
              dt = DateTime.parse(data['timestamp']);
            } catch (_) {
              continue;
            }
          } else {
            continue;
          }
          final hour = dt.hour;
          double value = 0;
          switch (metric) {
            case 'Heart Rate':
              value = double.tryParse(data['Heart Rate'].toString()) ?? 0;
              break;
            case 'O2':
              value = double.tryParse(data['O2'].toString()) ?? 0;
              break;
            case 'Temperature':
              value = double.tryParse(data['Temperature'].toString()) ?? 0;
              break;
          }
          spots.add(FlSpot(hour.toDouble(), value));
        }
        if (spots.isEmpty) {
          return Center(
              child: Text('ไม่มีข้อมูล', style: TextStyle(fontSize: 18)));
        }
        // กำหนดแกน X ให้แสดง 0-23 เสมอ
        final minX = 0.0;
        final maxX = 23.0;
        // กำหนด minY/maxY และ interval ตาม metric
        double minY = 0, maxY = 100, intervalY = 10;
        switch (metric) {
          case 'Heart Rate':
            minY = 40;
            maxY = 180;
            intervalY = 20;
            break;
          case 'O2':
            minY = 80;
            maxY = 100;
            intervalY = 2;
            break;
          case 'Temperature':
            minY = 30;
            maxY = 45;
            intervalY = 2.5;
            break;
        }
        return Padding(
          padding: const EdgeInsets.all(8.0), // ลด padding รอบกราฟ
          child: AspectRatio(
            aspectRatio: 2.2, // ย่อกราฟให้กว้างขึ้น
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    verticalInterval: 1,
                    horizontalInterval: intervalY),
                titlesData: FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 != 0 || value < minX || value > maxX)
                          return SizedBox.shrink();
                        return SizedBox(
                          width: 32, // เพิ่มความกว้าง
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                                fontSize: 10, height: 1), // ลดขนาดตัวอักษร
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        interval: intervalY,
                        reservedSize: 36),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 5,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Detailed Graphs',
            style: TextStyle(
                color: Color(0xFF008080), fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Color(0xFF13cfc7)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Heart Rate'),
            Tab(text: 'SpO2'),
            Tab(text: 'Temperature'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGraph('Heart Rate', Colors.red),
            _buildGraph('O2', Color(0xFF13cfc7)),
            _buildGraph('Temperature', Color(0xFFe7a6d6)),
          ],
        ),
      ),
    );
  }
}
