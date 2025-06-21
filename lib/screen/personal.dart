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
      setState(() {
        userData = doc.data() ?? {};
        _loading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        userData = {};
        _loading = false;
      });
    }
  }

  int _calculateAge(String dob) {
    try {
      final birthDate = DateTime.tryParse(dob);
      if (birthDate == null) return 0;
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
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
      backgroundColor: Color(0xFFF6F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal),
        title: Text('ข้อมูลส่วนตัว',
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.teal),
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
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : userData == null || userData!.isEmpty
              ? Center(child: Text('ยังไม่มีข้อมูลผู้ใช้'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoCard(
                          'ชื่อ', userData?['name'] ?? 'N/A', Icons.person),
                      _infoCard(
                          'อีเมล', userData?['email'] ?? 'N/A', Icons.email),
                      _infoCard('วันเกิด', userData?['dob'] ?? 'N/A',
                          Icons.calendar_today),
                      _infoCard(
                          'อายุ',
                          '${_calculateAge(userData?['dob'] ?? '')} ปี',
                          Icons.cake),
                      _infoCard('เพศ', userData?['gender'] ?? 'N/A', Icons.wc),
                      _infoCard(
                          'น้ำหนัก',
                          '${userData?['weight'] ?? 'N/A'} กก.',
                          Icons.monitor_weight),
                      _infoCard('ส่วนสูง',
                          '${userData?['height'] ?? 'N/A'} ซม.', Icons.height),
                    ],
                  ),
                ),
    );
  }
}
