import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ApiConnector {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ดึงข้อมูล personal data (age, bmi, gender) จาก users/{userId}/data (doc เดียว)
  Future<Map<String, dynamic>?> getPersonalData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    final dataCol = await _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .orderBy('timestamp',
            descending: true) // เรียงลำดับตาม timestamp เพื่อให้ได้ข้อมูลล่าสุด
        .limit(1) // จำกัดให้ดึงแค่ข้อมูลล่าสุด
        .get();
    if (dataCol.docs.isEmpty) return null;
    final data = dataCol.docs.first.data();
    return {
      'age': data['age'],
      'bmi': data['bmi'],
      'gender': data['gender'],
    };
  }

  // ดึง sensor data ล่าสุด (Heart Rate, O2, Temperature, timestamp)
  Future<Map<String, dynamic>?> getLatestSensorData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    final dataCol = await _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .orderBy('timestamp', descending: true)
        .limit(1) // ดึงข้อมูลล่าสุด
        .get();
    if (dataCol.docs.isEmpty) return null;
    final data = dataCol.docs.first.data();
    return {
      'heart_rate': data['Heart Rate'],
      'o2': data['O2'],
      'temperature': data['Temperature'],
      'timestamp': data['timestamp'],
    };
  }

  // ส่งข้อมูลไป Flask API และรับผลลัพธ์
  Future<int?> predictRisk(Map<String, dynamic> x) async {
    final url =
        Uri.parse('http://localhost:5000/predict'); // ใช้ URL Flask ที่ระบุ
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(x),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['result']; // Flask ส่งผลลัพธ์กลับมาเป็น 'result'
      }
      return null;
    } catch (e) {
      // ถ้าเชื่อมต่อไม่ได้หรือเกิดข้อผิดพลาดอื่น ๆ
      print('Error connecting to Flask API: $e');
      return null;
    }
  }

  // ฟังก์ชันหลัก: ดึงข้อมูล, ส่งไป Flask, เก็บผลลัพธ์
  Future<String> processAndSavePrediction() async {
    final personal = await getPersonalData();
    final sensor = await getLatestSensorData();
    if (personal == null || sensor == null) {
      print('Personal or sensor data missing');
      return 'no_data';
    }
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 'no_user';

    // ดึง prediction ล่าสุด
    final predSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('predictions')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    Timestamp? lastPredTimestamp;
    if (predSnap.docs.isNotEmpty) {
      final lastInput =
          predSnap.docs.first.data()['input'] as Map<String, dynamic>?;
      if (lastInput != null && lastInput['timestamp'] != null) {
        lastPredTimestamp =
            lastInput['timestamp'] is Timestamp ? lastInput['timestamp'] : null;
      }
    }
    // เช็ค timestamp sensor กับ prediction ล่าสุด ถ้าเหมือนเดิม ไม่ต้องส่งไป Flask ใหม่
    String? lastPredTimestampStr;
    if (lastPredTimestamp != null) {
      // แปลง timestamp ล่าสุดเป็น 24 ชม. yyyy-MM-dd HH:mm:ss เช่นเดียวกับ sensor
      lastPredTimestampStr =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(lastPredTimestamp.toDate());
    }
    final sensorTimestamp = sensor['timestamp'];
    String? sensorTimestampStr;
    if (sensorTimestamp is Timestamp) {
      // แปลง timestamp เป็น 24 ชม. yyyy-MM-dd HH:mm:ss
      sensorTimestampStr =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(sensorTimestamp.toDate());
    } else if (sensorTimestamp is String) {
      // พยายาม parse string เป็น DateTime แล้วแปลงใหม่
      try {
        final dt = DateTime.parse(sensorTimestamp);
        sensorTimestampStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
      } catch (_) {
        sensorTimestampStr = sensorTimestamp; // fallback
      }
    }
    if (lastPredTimestampStr != null &&
        sensorTimestampStr != null &&
        sensorTimestampStr == lastPredTimestampStr) {
      print('No new sensor data, skip prediction');
      return 'no_new_sensor';
    }

    final x = {
      'age': personal['age'],
      'bmi': personal['bmi'],
      'gender': personal['gender'],
      'heart_rate': sensor['heart_rate'],
      'o2': sensor['o2'],
      'temperature': sensor['temperature'],
      'timestamp': sensorTimestampStr, // ส่ง timestamp 24 ชม.
    };
    print('Sending to Flask: $x');
    final risk = await predictRisk(x);
    if (risk == null) {
      print('Flask API error or no response');
      return 'flask_error';
    }
    final riskLabel = risk == 0 ? 'High Risk' : 'Low Risk';
    final now = Timestamp.now();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('predictions')
        .add({
      'risk': riskLabel,
      'timestamp': now,
      'input': x,
    });
    print('Prediction saved: $riskLabel');
    return 'success';
  }

  // ดึง sensor data 24 ชั่วโมงล่าสุด (hourly) สำหรับกราฟ 24 ชม.
  Future<List<Map<String, dynamic>>> getHourlySensorData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final dataCol = await _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
    // เตรียม List 24 ช่อง (0-23)
    List<Map<String, dynamic>> hourly = List.generate(
        24,
        (i) => {
              'hour': i,
              'heart_rate': null,
              'o2': null,
              'temperature': null,
              'timestamp': null,
            });
    for (var doc in dataCol.docs) {
      final data = doc.data();
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
      hourly[hour] = {
        'hour': hour,
        'heart_rate': data['Heart Rate'],
        'o2': data['O2'],
        'temperature': data['Temperature'],
        'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(dt),
      };
    }
    return hourly;
  }
}
