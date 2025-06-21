import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // นำเข้า Firebase Auth

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _oxygenController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();

  Future<void> _saveDataToFirestore() async {
    try {
      // รับค่า heart rate, oxygen, และ temperature จากผู้ใช้
      double heartRate = double.tryParse(_heartRateController.text) ?? 0;
      double oxygen = double.tryParse(_oxygenController.text) ?? 0;
      double temperature = double.tryParse(_temperatureController.text) ?? 0;

      // สถานะ Normal/Abnormal
      String status = (heartRate >= 60 &&
              heartRate <= 100 &&
              oxygen >= 95 &&
              temperature >= 36.1 &&
              temperature <= 37.2)
          ? 'Normal'
          : 'Abnormal';

      // ดึง userId ของผู้ใช้ที่ล็อกอินจาก Firebase Authentication
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // ใช้ Firebase Firestore สร้าง Document ID แบบสุ่มให้โดยอัตโนมัติในคอลเล็กชัน 'data'
      // โดยที่ 'users' -> 'userId' -> 'data' เป็นโครงสร้าง
      await FirebaseFirestore.instance
          .collection('users') // คอลเล็กชัน 'users'
          .doc(userId) // ใช้ userId เป็น document ของผู้ใช้
          .collection('data') // คอลเล็กชัน 'data' ของผู้ใช้
          .add({
        // ใช้ add() เพื่อให้ Firestore สร้าง documentId ให้เอง
        'Heart Rate': heartRate,
        'O2': oxygen,
        'Temperature': temperature,
        'Status': status,
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Data"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _heartRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Heart Rate (bpm)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _oxygenController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Oxygen Saturation (%)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _temperatureController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Body Temperature (°C)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveDataToFirestore,
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
