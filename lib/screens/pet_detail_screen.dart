import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/appointment_card.dart';
import 'edit_medical_screen.dart';
import 'health_history_screen.dart';
import 'pet_map_screen.dart'; // <-- Import the new map screen

// Helper class for Vaccination data (needed for parsing)
class Vaccination {
  String vaccineName;
  DateTime? dateAdministered;
  DateTime? nextDueDate;

  Vaccination({this.vaccineName = '', this.dateAdministered, this.nextDueDate});

  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      vaccineName: json['vaccineName'] ?? '',
      dateAdministered: json['dateAdministered'] != null ? DateTime.parse(json['dateAdministered']) : null,
      nextDueDate: json['nextDueDate'] != null ? DateTime.parse(json['nextDueDate']) : null,
    );
  }
}

class PetDetailScreen extends StatefulWidget {
  final String petId;
  final Color themeColor;

  const PetDetailScreen({Key? key, required this.petId, required this.themeColor}) : super(key: key);

  @override
  _PetDetailScreenState createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _petDetailsFuture;
  late Future<Map<String, dynamic>?> _healthDataFuture;
  late Future<Map<String, dynamic>> _analysisFuture;
  Timer? _refreshTimer;
  bool _isFindingPet = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (Timer t) {
      print("Auto-refreshing health data...");
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _petDetailsFuture = _apiService.getPetDetails(widget.petId);
      _healthDataFuture = _apiService.getLatestHealthRecord(widget.petId);
      _analysisFuture = _apiService.getHealthAnalysis(widget.petId);
    });
  }

  void _handleGenerateMockData() async {
    await _apiService.generateMockHealthData(widget.petId);
    _loadData();
  }

  void _handleFindPet() async {
    setState(() { _isFindingPet = true; });
    final result = await _apiService.issueFindPetCommand(widget.petId);
    if (!mounted) return;
    if (result['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Find command sent! Collar will beep soon."), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${result['body']['msg']}")),
      );
    }
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() { _isFindingPet = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pet Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_petDetailsFuture, _healthDataFuture, _analysisFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: Could not load data."));
          }
          if (snapshot.hasData) {
            final petDetailsData = snapshot.data![0] as Map<String, dynamic>;
            final healthData = snapshot.data![1] as Map<String, dynamic>?;
            final analysisData = snapshot.data![2] as Map<String, dynamic>;
            final pet = petDetailsData['pet'];
            final appointments = petDetailsData['appointments'] as List;
            final allergies = (pet['allergies'] as List? ?? []).map((a) => a['description'].toString()).toList();
            final vaccinations = (pet['vaccinations'] as List? ?? []).map((v) => Vaccination.fromJson(v)).toList();

            return ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildPetHeader(pet),
                SizedBox(height: 30),
                _buildHealthStatusCard(analysisData),
                SizedBox(height: 30),
                
                // --- NEW GPS CARD ---
                _buildGpsCard(context, pet),
                SizedBox(height: 30),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HealthHistoryScreen(
                          petId: widget.petId,
                          petName: pet['name'],
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Health Vitals (Latest)", style: Theme.of(context).textTheme.titleLarge),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                        ],
                      ),
                      SizedBox(height: 10),
                      _buildHealthGrid(healthData),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _handleGenerateMockData,
                  child: Text("Generate Mock Health Data (Dev)"),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Medical Records", style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      child: Text("Manage"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMedicalScreen(
                              petId: widget.petId,
                              onMedicalUpdated: _loadData,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _buildMedicalList("Allergies", allergies.isNotEmpty ? allergies.join(', ') : "No allergies listed."),
                _buildMedicalList("Vaccinations", vaccinations.isNotEmpty ? vaccinations.map((v) => v.vaccineName).join(', ') : "No vaccinations listed."),
                SizedBox(height: 30),
                Text("Appointment History", style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 10),
                _buildAppointmentList(appointments),
              ],
            );
          }
          return Center(child: Text("No details found."));
        },
      ),
    );
  }

  // --- HELPER WIDGET FOR GPS CARD ---
  Widget _buildGpsCard(BuildContext context, Map<String, dynamic> pet) {
    return Card(
      elevation: 0,
      color: Colors.blue.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue, width: 1)
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        leading: Icon(Icons.location_on, color: Colors.blue, size: 32),
        title: Text("Live GPS Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("View ${pet['name']}'s location in real-time."),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetMapScreen(
                petId: pet['_id'],
                petName: pet['name'],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- All other helper widgets remain the same ---
  Widget _buildPetHeader(Map<String, dynamic> pet) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: widget.themeColor,
            child: const Icon(Icons.pets, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            pet['name'],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "${pet['breed']}, ${pet['age']} year(s) old",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isFindingPet ? null : _handleFindPet,
            icon: _isFindingPet 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : Icon(Icons.volume_up),
            label: Text(_isFindingPet ? "Sending..." : "Find Pet (In-Home)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor.withOpacity(0.8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHealthStatusCard(Map<String, dynamic> analysisData) {
    final status = analysisData['status'] ?? 'Normal';
    final message = analysisData['message'] ?? 'No data to analyze.';
    final color = status == 'Warning' ? Colors.orange.shade700 : Colors.green.shade600;
    final icon = status == 'Warning' ? Icons.warning_amber_rounded : Icons.check_circle_outline;

    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 1)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
                  ),
                  SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHealthGrid(Map<String, dynamic>? healthData) {
    if (healthData == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text("No health data available."),
      ));
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _buildHealthStatCard(Icons.favorite, "Heart Rate", "${healthData['heartRate'] ?? 'N/A'} bpm", Colors.red),
        _buildHealthStatCard(Icons.thermostat, "Temperature", "${(healthData['temperature'] as num?)?.toStringAsFixed(1) ?? 'N/A'} °C", Colors.orange),
        _buildHealthStatCard(Icons.run_circle, "Activity", "${healthData['activityLevel'] ?? 'N/A'}", Colors.green),
        _buildHealthStatCard(Icons.local_fire_department, "Calories", "${healthData['caloriesBurned'] ?? 'N/A'} kcal", Colors.deepOrange),
      ],
    );
  }
  Widget _buildHealthStatCard(IconData icon, String title, String value, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.white70)),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMedicalList(String title, String details) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
  Widget _buildAppointmentList(List appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Text("This pet has no appointments yet."),
        ),
      );
    }
    return Column(
      children: appointments.map((apptData) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: AppointmentCard(
            appointmentData: apptData,
            themeColor: widget.themeColor,
          ),
        );
      }).toList(),
    );
  }
}