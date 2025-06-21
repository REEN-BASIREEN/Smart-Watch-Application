import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:capstone_project/screen/input_data.dart';
import 'package:capstone_project/screen/personal.dart';
import 'package:capstone_project/screen/history_data.dart';
import 'package:capstone_project/widgets/line_chart.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _userName = doc.data()?['name'] ?? 'User';
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => GraphPage()));
    } else if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => PersonalPage()));
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to logout: $e')));
    }
  }

  String _calculateStatus(double hr, double o2, double temp) {
    if (hr >= 60 && hr <= 100 && o2 >= 95 && temp >= 36.1 && temp <= 37.2) {
      return 'Normal';
    }
    return 'Abnormal';
  }

  String _generateAdvice(String status) {
    return status == 'Normal'
        ? 'สุขภาพดี! รักษาระดับนี้ต่อไป'
        : 'โปรดพักผ่อนให้เพียงพอ และวัดซ้ำอีกครั้ง';
  }

  Widget _buildMetricCard(
      String title, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 140,
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, String advice) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(top: 28, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety,
              color: status == 'Normal' ? Colors.green : Colors.red, size: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $status',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 6),
                Text(advice, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Color(0xFFF6F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(''),
        actions: [
          IconButton(
              icon: Icon(Icons.logout, color: Colors.teal), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello,',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text(_userName ?? 'User',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 24),
                    SizedBox(width: 6),
                    Text('Health Dashboard',
                        style: TextStyle(
                            color: Colors.teal,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HistoryDataPage()),
                    );
                  },
                  icon: Icon(Icons.history, size: 20, color: Colors.black),
                  label: Text("See History",
                      style: TextStyle(fontSize: 14, color: Colors.black)),
                ),
              ],
            ),
            SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('data')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No data available'));
                }

                final data =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final hr =
                    double.tryParse(data['Heart Rate']?.toString() ?? '0') ?? 0;
                final o2 = double.tryParse(data['O2']?.toString() ?? '0') ?? 0;
                final temp =
                    double.tryParse(data['Temperature']?.toString() ?? '0') ??
                        0;
                final status = _calculateStatus(hr, o2, temp);
                final advice = _generateAdvice(status);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildMetricCard(
                            '${hr.toStringAsFixed(1)} bpm',
                            'Heart Rate',
                            Icons.monitor_heart,
                            const Color.fromARGB(255, 4, 216, 195)),
                        _buildMetricCard(
                            '${o2.toStringAsFixed(1)}%',
                            'SpO2',
                            Icons.bloodtype,
                            const Color.fromARGB(227, 112, 186, 247)),
                        _buildMetricCard(
                            '${temp.toStringAsFixed(1)}°C',
                            'Body Temperature',
                            Icons.thermostat,
                            const Color.fromARGB(255, 240, 170, 78)),
                      ],
                    ),
                    _buildStatusCard(status, advice),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => InputPage()));
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'กราฟ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'ข้อมูลส่วนตัว'),
        ],
      ),
    );
  }
}
