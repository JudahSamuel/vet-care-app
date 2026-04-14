import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class VetDashboardPage extends StatefulWidget {
  final String vetId;
  const VetDashboardPage({Key? key, required this.vetId}) : super(key: key);

  @override
  _VetDashboardPageState createState() => _VetDashboardPageState();
}

class _VetDashboardPageState extends State<VetDashboardPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _apiService.getVetDashboardData(widget.vetId);
  }

  void _refreshSchedule() {
    setState(() {
      _dashboardDataFuture = _apiService.getVetDashboardData(widget.vetId);
    });
  }

  // --- NEW FUNCTION TO SHOW UPDATE DIALOG ---
  void _showUpdateStatusDialog(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Status"),
          content: Text("Choose a new status for this appointment."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Mark Completed"),
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(appointment['_id'], 'Completed');
              },
            ),
            TextButton(
              child: Text("Mark Cancelled", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(appointment['_id'], 'Cancelled');
              },
            ),
          ],
        );
      },
    );
  }

  // --- NEW FUNCTION TO CALL THE API ---
  void _updateStatus(String appointmentId, String status) async {
    final result = await _apiService.updateAppointmentStatus(appointmentId, status);
    if (!mounted) return;

    if (result['statusCode'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated!")));
      _refreshSchedule(); // Refresh the list to show the change
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result['body']['msg']}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Schedule"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshSchedule,
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: Could not load schedule."));
          }
          if (snapshot.hasData) {
            final appointments = snapshot.data!['appointments'] as List;
            if (appointments.isEmpty) {
              return Center(child: Text("You have no upcoming appointments."));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                final date = DateTime.parse(appt['date']);
                final formattedDate = DateFormat.yMMMd().add_jm().format(date);
                final status = appt['status'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _showUpdateStatusDialog(appt), // Make the card tappable
                    leading: _getStatusIcon(status),
                    title: Text("Client: ${appt['owner']['name']}", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Reason: ${appt['reason']}\nOn: $formattedDate"),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }
          return Center(child: Text("No data found."));
        },
      ),
    );
  }

  // Helper function to show a different icon based on status
  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'Cancelled':
        return Icon(Icons.cancel, color: Colors.red);
      default: // 'Scheduled'
        return Icon(Icons.schedule, color: Colors.blue);
    }
  }
}