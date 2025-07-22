import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone_project/screen/personal.dart';
import 'package:capstone_project/screen/history_data.dart';
import 'package:capstone_project/widgets/line_chart.dart';
import 'package:capstone_project/screen/connect_api.dart';
import 'package:capstone_project/screen/detailed_graphs.dart';
import 'package:capstone_project/theme.dart';

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

  Map<String, dynamic> _analyzeVitalSigns(double hr, double o2, double temp) {
    List<String> alerts = [];
    List<String> advice = [];
    String status = 'Normal';

    // Heart Rate Analysis
    if (hr < 60) {
      status = 'Abnormal';
      alerts.add('Unusual Heartbeat Detected (Bradycardia)');
      advice.add(
          'หากคุณไม่ได้ออกกำลังกาย หรือเป็นนักกีฬา ควรพักทันที และหากรู้สึกเวียนหัว เหนื่อย หรือเจ็บหน้าอก ควรพบแพทย์');
    } else if (hr > 120) {
      status = 'Abnormal';
      alerts.add('Unusual Heartbeat Detected (Tachycardia)');
      advice.add(
          'อัตราการเต้นของหัวใจสูงผิดปกติ หากคุณไม่ได้ออกแรง อาจเป็นสัญญาณของความเครียด ความดัน หรือโรคหัวใจ — พัก และปรึกษาแพทย์หากอาการไม่ดีขึ้น');
    }

    // SpO2 Analysis
    if (o2 < 95) {
      status = 'Abnormal';
      alerts.add('Low Oxygen Saturation');
      advice.add(
          'หากคุณไม่ได้อยู่ในที่สูง หรือมีโรคประจำตัว ให้พัก สูดลมหายใจลึก ๆ และเฝ้าดูอาการ หากต่ำกว่า 92% หรือมีอาการแน่นหน้าอก หายใจลำบาก ควรพบแพทย์ทันที');
    }

    // Temperature Analysis
    if (temp < 36.1) {
      status = 'Abnormal';
      alerts.add('Abnormal Body Temperature (Hypothermia)');
      advice.add(
          'อุณหภูมิร่างกายต่ำกว่าปกติ อาจเกิดจากความเย็น เหนื่อยล้า หรือระบบเผาผลาญต่ำ ควรห่มผ้า ดื่มน้ำอุ่น และตรวจซ้ำอีกครั้ง');
    } else if (temp > 37.5) {
      status = 'Abnormal';
      alerts.add('Abnormal Body Temperature (Fever)');
      advice.add(
          'คุณอาจเริ่มมีไข้ ซึ่งอาจบ่งชี้ถึงการติดเชื้อ หากเกิน 38°C หรือมีอาการปวดหัว หนาวสั่น ปรึกษาแพทย์ทันที');
    }

    return {
      'status': status,
      'alerts': alerts,
      'advice': advice.isEmpty ? ['สุขภาพดี! รักษาระดับนี้ต่อไป'] : advice,
    };
  }

  String _calculateStatus(double hr, double o2, double temp) {
    return _analyzeVitalSigns(hr, o2, temp)['status'];
  }

  String _generateAdvice(String status) {
    if (status == 'Normal') {
      return 'สุขภาพดี! รักษาระดับนี้ต่อไป';
    }
    return 'โปรดพักผ่อนให้เพียงพอ และวัดซ้ำอีกครั้ง';
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

  Widget _buildStatusCard(Map<String, dynamic> healthData) {
    final bool isNormal = healthData['status'] == 'Normal';
    final Color statusColor = isNormal ? Colors.green : Colors.red;
    final List<String> alerts = healthData['alerts'] as List<String>;
    final List<String> advice = healthData['advice'] as List<String>;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(top: 28, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: statusColor, size: 36),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Health Status: ${healthData['status']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (!isNormal) ...[
            SizedBox(height: 16),
            ...alerts.map((alert) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          SizedBox(height: 16),
          ...advice.map((tip) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates,
                        color: Colors.blue[700], size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final double cardRadius = 24;
    final double cardElevation = 10;
    // Card colors
    final Color cardHeart = Color.fromARGB(255, 223, 56, 56);
    final Color cardO2 = Color(0xFF13cfc7);
    final Color cardTemp = Color.fromARGB(255, 241, 188, 42);
    // Theme colors
    final Color textColor = Color(0xFFE1E8ED);
    final Color navBarBg = Color(0xFF192734);
    final Color navBarSelected = Color(0xFF1D9BF0);
    final Color navBarUnselected = Color(0xFF8899A6);

    // Dark theme background color
    final Color backgroundColor = Color(0xFF15202B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF1D9BF0).withOpacity(0.2),
              child: Icon(Icons.person, color: Color(0xFF1D9BF0), size: 28),
            ),
            SizedBox(width: 12),
            Text(
              _userName ?? 'User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
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
          color: AppColors.background,
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
                              color: textColor,
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
                    icon:
                        Icon(Icons.history, size: 20, color: Color(0xFF1D9BF0)),
                    label: Text("See History",
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF1D9BF0))),
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
                            .collection('data')
                            .orderBy('timestamp', descending: true)
                            .limit(1)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildStatusCard({
                              'status': 'No Data',
                              'alerts': ['No health data available'],
                              'advice': ['Please measure your vital signs']
                            });
                          }

                          final data = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final hr = double.tryParse(
                                  data['Heart Rate']?.toString() ?? '0') ??
                              0;
                          final o2 =
                              double.tryParse(data['O2']?.toString() ?? '0') ??
                                  0;
                          final temp = double.tryParse(
                                  data['Temperature']?.toString() ?? '0') ??
                              0;

                          return _buildStatusCard(
                              _analyzeVitalSigns(hr, o2, temp));
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
        selectedItemColor: navBarSelected,
        unselectedItemColor: navBarUnselected,
        backgroundColor: navBarBg,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Graphs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
