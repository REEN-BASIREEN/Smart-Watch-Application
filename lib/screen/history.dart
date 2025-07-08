import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('History',
            style: TextStyle(
                color: Color(0xFF008080), fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Color(0xFF13cfc7)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('data').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text('No data available',
                      style: TextStyle(color: Color(0xFF008080))));
            }

            final documents = snapshot.data!.docs;

            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final data = documents[index].data() as Map<String, dynamic>;

                return Card(
                  color: Colors.white.withOpacity(0.9),
                  child: ListTile(
                    title: Text('Day ${index + 1}',
                        style: TextStyle(
                            color: Color(0xFF008080),
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Heart Rate: ${data['Heart Rate']} bpm\n'
                        'Oxygen: ${data['O2']}%\n'
                        'Temperature: ${data['Temperature']}°C',
                        style: TextStyle(color: Color(0xFF13cfc7))),
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
      ),
    );
  }
}
