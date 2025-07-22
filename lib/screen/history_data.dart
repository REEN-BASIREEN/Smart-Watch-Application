import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryDataPage extends StatefulWidget {
  @override
  _HistoryDataPageState createState() => _HistoryDataPageState();
}

class _HistoryDataPageState extends State<HistoryDataPage> {
  DateTime selectedDate = DateTime.now();

  bool _isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _calculateStatus(double hr, double o2, double temp) {
    if (hr >= 60 && hr <= 100 && o2 >= 95 && temp >= 36.1 && temp <= 37.2) {
      return 'Normal';
    }
    return 'Abnormal';
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Health History',
            style: TextStyle(
                color: Color(0xFF1D9BF0), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1D9BF0)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF192734), Color(0xFF192734)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                  ElevatedButton(
                    onPressed: _pickDate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1D9BF0),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Select Date',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('data')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('ไม่พบข้อมูล'));
                  }

                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final time = (doc['timestamp'] as Timestamp?)?.toDate();
                    return time != null && _isSameDate(time, selectedDate);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                        child: Text('ไม่มีข้อมูลในวันดังกล่าว'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          filteredDocs[index].data() as Map<String, dynamic>;
                      final time =
                          (data['timestamp'] as Timestamp?)?.toDate() ??
                              DateTime.now();

                      final hr = double.tryParse(
                              data['Heart Rate']?.toString() ?? '0') ??
                          0;
                      final o2 =
                          double.tryParse(data['O2']?.toString() ?? '0') ?? 0;
                      final temp = double.tryParse(
                              data['Temperature']?.toString() ?? '0') ??
                          0;

                      final status = _calculateStatus(hr, o2, temp);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('HH:mm').format(time),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: Colors.grey),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.monitor_heart,
                                          color: Colors.teal),
                                      SizedBox(width: 6),
                                      Text("Heart Rate:"),
                                    ],
                                  ),
                                  Text('${hr.toStringAsFixed(1)} bpm'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.air, color: Colors.teal),
                                      SizedBox(width: 6),
                                      Text("Oxygen:"),
                                    ],
                                  ),
                                  Text('${o2.toStringAsFixed(1)} %'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.thermostat,
                                          color: Colors.teal),
                                      SizedBox(width: 6),
                                      Text("Temperature:"),
                                    ],
                                  ),
                                  Text('${temp.toStringAsFixed(1)} °C'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: status == 'Normal'
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Status: $status',
                                    style: TextStyle(
                                        color: status == 'Normal'
                                            ? Colors.green[800]
                                            : Colors.red[800],
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
