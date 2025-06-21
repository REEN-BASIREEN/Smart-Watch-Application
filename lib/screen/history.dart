import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('data')
            .snapshots(), // ดึงข้อมูลจาก Firestore
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data available'));
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final data = documents[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text('Day ${index + 1}'), // หรืออาจใช้ timestamp แทน
                  subtitle: Text('Heart Rate: ${data['Heart Rate']} bpm\n'
                      'Oxygen: ${data['O2']}%\n'
                      'Temperature: ${data['Temperature']}°C'), // แสดงข้อมูลจริงจาก Firestore
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.save),
                        onPressed: () {
                          // ฟังก์ชันสำหรับบันทึกข้อมูล (ขึ้นอยู่กับกรณีใช้งาน)
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          // ฟังก์ชันสำหรับลบข้อมูลจาก Firestore
                          await FirebaseFirestore.instance
                              .collection('data')
                              .doc(documents[index]
                                  .id) // ใช้ ID ของเอกสารที่ต้องการลบ
                              .delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
