import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone_project/screen/personal.dart';
import 'package:capstone_project/screen/history_data.dart';
import 'package:capstone_project/widgets/line_chart.dart';
import 'package:capstone_project/screen/connect_api.dart';
import 'package:capstone_project/screen/detailed_graphs.dart';

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
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => DetailedGraphsPage()));
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

  void _goToGraph(String metric) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailedGraphsPage(initialMetric: metric),
      ),
    );
  }

  Widget _buildMetricCard(String title, String subtitle, IconData icon,
      Color color, String metric) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _goToGraph(metric),
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
    final double cardRadius = 24;
    final double cardElevation = 10;
    final Color bgGradientStart = Color(0xFFe0c3fc); // purple-pink
    final Color bgGradientEnd = Color(0xFF8ec5fc); // blue
    final Color cardHeart = Color(0xFF1ec96b); // เขียวเข้มขึ้น
    final Color cardO2 = Color(0xFF13cfc7); // ฟ้าอมเขียวเข้มขึ้น
    final Color cardTemp = Color(0xFFe7a6d6); // ชมพูเข้มขึ้น
    final Color navBarColor = Color(0xFFf6f7fb);
    final Color navBarActive = Color(0xFF43cea2);
    final Color navBarInactive = Color(0xFFbdbdbd);
    final Color textTealDark = Color(0xFF008080);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cardO2.withOpacity(0.2),
              child: Icon(Icons.person, color: cardO2, size: 28),
            ),
            SizedBox(width: 12),
            Text(
              _userName ?? 'User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textTealDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: _logout,
            icon: Icon(Icons.logout, color: Colors.red, size: 24),
            label: Text('Logout',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, color: Colors.red, size: 28),
                      SizedBox(width: 8),
                      Text('Health Dashboard',
                          style: TextStyle(
                              color: textTealDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shape: StadiumBorder(),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HistoryDataPage()),
                      );
                    },
                    icon: Icon(Icons.history, size: 20, color: cardO2),
                    label: Text("See History",
                        style: TextStyle(fontSize: 15, color: cardO2)),
                  ),
                ],
              ),
              SizedBox(height: 18),
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
                      double.tryParse(data['Heart Rate']?.toString() ?? '0') ??
                          0;
                  final o2 =
                      double.tryParse(data['O2']?.toString() ?? '0') ?? 0;
                  final temp =
                      double.tryParse(data['Temperature']?.toString() ?? '0') ??
                          0;

                  // Trigger prediction every time there is new sensor data
                  Future.microtask(() {
                    ApiConnector().processAndSavePrediction();
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(cardRadius),
                              onTap: () => _goToGraph('Heart Rate'),
                              child: Card(
                                elevation: cardElevation,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(cardRadius)),
                                color: cardHeart,
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.monitor_heart,
                                              color: Colors.white, size: 32),
                                          SizedBox(width: 8),
                                          Text('Heart Rate',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 15)),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Text('${hr.toStringAsFixed(1)} bpm',
                                          style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(cardRadius),
                              onTap: () => _goToGraph('O2'),
                              child: Card(
                                elevation: cardElevation,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(cardRadius)),
                                color: cardO2,
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.water_drop,
                                              color: Colors.white, size: 32),
                                          SizedBox(width: 8),
                                          Text('SpO2',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 15)),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Text('${o2.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(cardRadius),
                              onTap: () => _goToGraph('Temperature'),
                              child: Card(
                                elevation: cardElevation,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(cardRadius)),
                                color: cardTemp,
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.thermostat,
                                              color: Colors.white, size: 32),
                                          SizedBox(width: 8),
                                          Text('Body Temp',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 15)),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Text('${temp.toStringAsFixed(1)}°C',
                                          style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('predictions')
                            .orderBy('timestamp', descending: true)
                            .limit(1)
                            .snapshots(),
                        builder: (context, predSnapshot) {
                          if (!predSnapshot.hasData ||
                              predSnapshot.data!.docs.isEmpty) {
                            return _buildStatusCard(
                                'No Prediction', 'ยังไม่มีผลการทำนาย');
                          }
                          final pred = predSnapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final risk = pred['risk'] ?? 'Unknown';
                          String status;
                          String advice;
                          if (risk == 'High Risk') {
                            status = 'Abnormal';
                            advice = 'โปรดพักผ่อนให้เพียงพอ และวัดซ้ำอีกครั้ง';
                          } else if (risk == 'Low Risk') {
                            status = 'Normal';
                            advice = 'สุขภาพดี! รักษาระดับนี้ต่อไป';
                          } else {
                            status = 'Unknown';
                            advice = '';
                          }
                          return _buildStatusCard(status, advice);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: navBarActive,
        unselectedItemColor: navBarInactive,
        backgroundColor: navBarColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Graphs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
