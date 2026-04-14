import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HealthHistoryScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const HealthHistoryScreen({Key? key, required this.petId, required this.petName}) : super(key: key);

  @override
  _HealthHistoryScreenState createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.getHealthHistory(widget.petId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.petName}'s Health History"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: Could not load health history."));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No health records found for this pet."));
          }

          final records = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final date = DateTime.parse(record['timestamp']);
              final formattedDate = DateFormat.yMd().add_jm().format(date); // Format date and time

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatChip(Icons.favorite, "${record['heartRate'] ?? 'N/A'} bpm", Colors.red),
                          _buildStatChip(Icons.thermostat, "${(record['temperature'] as num?)?.toStringAsFixed(1) ?? 'N/A'} °C", Colors.orange),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           _buildStatChip(Icons.run_circle, "${record['activityLevel'] ?? 'N/A'}", Colors.green),
                           _buildStatChip(Icons.local_fire_department, "${record['caloriesBurned'] ?? 'N/A'} kcal", Colors.deepOrange),
                        ],
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

  // Helper widget for the small stat chips
  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}