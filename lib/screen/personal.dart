import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone_project/screen/edit_profile.dart';

class PersonalPage extends StatefulWidget {
  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data() ?? {};
      // Convert types for numeric fields and dob
      data['weight'] = (data['weight'] is num)
          ? data['weight']
          : num.tryParse(data['weight']?.toString() ?? '') ?? 0;
      data['height'] = (data['height'] is num)
          ? data['height']
          : num.tryParse(data['height']?.toString() ?? '') ?? 0;
      data['dob'] = data['dob'] is Timestamp
          ? data['dob']
          : (data['dob'] is String && data['dob'].isNotEmpty
              ? Timestamp.fromDate(DateTime.parse(data['dob']))
              : null);
      setState(() {
        userData = data;
        _loading = false;
      });
      // Update age and BMI in Firestore after loading user data
      if (data.isNotEmpty) {
        await _updateUserDataWithAgeAndBMI();
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        userData = {};
        _loading = false;
      });
    }
  }

  int _calculateAge(Timestamp? dob) {
    if (dob == null) return 0;
    final birthDate = dob.toDate();
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  double _calculateBMI(num weight, num height) {
    if (weight == 0 || height == 0) return 0;
    double heightM = height / 100;
    return weight / (heightM * heightM);
  }

  Future<void> _updateUserDataWithAgeAndBMI() async {
    if (userData == null) return;
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final age = _calculateAge(userData?['dob']);
    final bmiRaw = _calculateBMI(userData?['weight'], userData?['height']);
    final bmi = double.parse(bmiRaw.toStringAsFixed(2));
    await _firestore.collection('users').doc(userId).update({
      'age': age,
      'bmi': bmi,
      'weight': userData?['weight'],
      'height': userData?['height'],
      'dob': userData?['dob'],
    });
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          SizedBox(width: 16),
          Expanded(
            child: Text('$label: $value',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF13cfc7)),
        title: Text('ข้อมูลส่วนตัว',
            style: TextStyle(
                color: Color(0xFF008080), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Color(0xFF13cfc7)),
            onPressed: userData == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          name: userData?['name'] ?? '',
                          email: userData?['email'] ?? '',
                          dob: userData?['dob'] ?? '',
                          gender: userData?['gender'] ?? '',
                          weight: userData?['weight'] ?? '',
                          height: userData?['height'] ?? '',
                        ),
                      ),
                    ).then((_) => _fetchUserData());
                  },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
          ),
        ),
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : userData == null || userData!.isEmpty
                ? Center(child: Text('ยังไม่มีข้อมูลผู้ใช้'))
                : ListView(
                    padding: EdgeInsets.all(20),
                    children: [
                      _infoCard(
                          'ชื่อ', userData?['name'] ?? 'N/A', Icons.person),
                      _infoCard(
                          'อีเมล', userData?['email'] ?? 'N/A', Icons.email),
                      _infoCard(
                          'วันเกิด',
                          userData?['dob'] != null
                              ? (userData?['dob'] as Timestamp)
                                  .toDate()
                                  .toString()
                                  .split(' ')[0]
                              : 'N/A',
                          Icons.calendar_today),
                      _infoCard('อายุ', '${_calculateAge(userData?['dob'])} ปี',
                          Icons.cake),
                      _infoCard('เพศ', userData?['gender'] ?? 'N/A', Icons.wc),
                      _infoCard(
                          'น้ำหนัก',
                          '${userData?['weight'] ?? 'N/A'} กก.',
                          Icons.monitor_weight),
                      _infoCard('ส่วนสูง',
                          '${userData?['height'] ?? 'N/A'} ซม.', Icons.height),
                      _infoCard(
                          'BMI',
                          userData?['weight'] != null &&
                                  userData?['height'] != null &&
                                  userData?['weight'] != 0 &&
                                  userData?['height'] != 0
                              ? _calculateBMI(
                                      userData?['weight'], userData?['height'])
                                  .toStringAsFixed(2)
                              : 'N/A',
                          Icons.fitness_center),
                    ],
                  ),
      ),
    );
  }
}
