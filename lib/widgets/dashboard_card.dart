// ==========================
// dashboard_card.dart
// ==========================
import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title; // จะใช้เวลาเป็น title
  final String heartRate;
  final String oxygenSaturation;
  final String temperature;
  final String status;
  final DateTime? timestamp;

  DashboardCard({
    Key? key,
    required this.title,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.temperature,
    required this.status,
    this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.redAccent, size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 20, thickness: 1),
            _buildInfoRow(Icons.monitor_heart, 'Heart Rate', heartRate, 'bpm'),
            _buildInfoRow(Icons.air, 'Oxygen', oxygenSaturation, '%'),
            _buildInfoRow(Icons.thermostat, 'Temperature', temperature, '°C'),
            SizedBox(height: 12),
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${value.isNotEmpty ? value : 'N/A'} $unit',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isNormal = status == 'Normal';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isNormal ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Status: $status',
        style: TextStyle(
          color: isNormal ? Colors.green.shade800 : Colors.red.shade800,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
