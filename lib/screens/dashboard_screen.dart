import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../widgets/pet_card.dart';
import '../widgets/appointment_card.dart';
import 'add_pet_screen.dart';
import 'home_screen.dart';
import 'pet_detail_screen.dart';
import 'chat_screen.dart';
import 'symptom_checker_screen.dart';

// ===================================================================
// Main Dashboard Page
// ===================================================================
class DashboardPage extends StatefulWidget {
  final String gender;
  final String userId;
  DashboardPage({required this.gender, required this.userId});
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardDataFuture;
  late Future<Map<String, dynamic>> _recommendationFuture; // <-- 1. ADD NEW FUTURE

  @override
  void initState() {
    super.initState();
    _loadData(); // Call helper to load all data
  }

  void _loadData() {
    setState(() {
      _dashboardDataFuture = _apiService.getDashboardData(widget.userId);
      _recommendationFuture = _apiService.getRecommendation(widget.userId); // <-- 2. LOAD RECOMMENDATION
    });
  }

  void _refreshDashboard() {
    _loadData(); // Refresh all data
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Color getThemeColor() {
    if (widget.gender == 'male') return Colors.teal;
    return Colors.purple;
  }

  void _showAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AppointmentBookingDialog(userId: widget.userId);
      },
    ).then((result) {
      if (result == true) {
        _refreshDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            tooltip: 'AI Assistant',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshDashboard,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPetScreen(ownerId: widget.userId),
            ),
          );
          if (result == true) {
            _refreshDashboard();
          }
        },
        icon: Icon(Icons.add),
        label: Text("Add Pet"),
        backgroundColor: getThemeColor(),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: Could not load data. Please try again."));
          }
          if (snapshot.hasData) {
            final data = snapshot.data!;
            final user = data['user'];
            final pets = data['pets'] as List;
            final appointments = data['appointments'] as List;

            return ListView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 80),
              children: [
                Center(
                  child: Text(
                    "Welcome, ${user['name']}!",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),

                // --- 3. ADD RECOMMENDATION CARD ---
                _buildRecommendationCard(),
                SizedBox(height: 30),

                _buildSymptomCheckerCard(),
                SizedBox(height: 30),

                Text("Your Pets", style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 10),
                if (pets.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32.0), child: Text("You haven't added any pets yet.")))
                else
                  ...pets.map((petData) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetDetailScreen(
                              petId: petData['_id'],
                              themeColor: getThemeColor(),
                            ),
                          ),
                        ).then((_) => _refreshDashboard()); // Refresh dashboard when returning from pet details
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: PetCard(
                          name: petData['name'],
                          breed: petData['breed'],
                          age: (petData['age'] is int) ? petData['age'] : int.tryParse(petData['age'].toString()) ?? 0,
                          themeColor: getThemeColor(),
                        ),
                      ),
                    );
                  }).toList(),
                
                SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Your Appointments", style: Theme.of(context).textTheme.titleLarge),
                    TextButton(onPressed: _showAppointmentDialog, child: Text("Book New")),
                  ],
                ),
                SizedBox(height: 10),
                if (appointments.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32.0), child: Text("You have no upcoming appointments.")))
                else
                  ...appointments.map((apptData) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: AppointmentCard(appointmentData: apptData, themeColor: getThemeColor()),
                      )),
              ],
            );
          }
          return Center(child: Text("No data found."));
        },
      ),
    );
  }

  // --- 4. HELPER WIDGET FOR RECOMMENDATION CARD ---
  Widget _buildRecommendationCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _recommendationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a simple placeholder while loading
          return Card(
            elevation: 0,
            color: Colors.indigo.withOpacity(0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              leading: Icon(Icons.lightbulb_outline, color: Colors.indigo, size: 32),
              title: Text("AI Wellness Tip", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Analyzing your profile..."),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox.shrink(); // Don't show the card if it fails
        }
        
        final recommendation = snapshot.data!['recommendation'];
        
        return Card(
          elevation: 0,
          color: Colors.indigo.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.indigo, width: 1)
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            leading: Icon(Icons.lightbulb_outline, color: Colors.indigo, size: 32),
            title: Text("AI Wellness Tip", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(recommendation),
          ),
        );
      },
    );
  }

  Widget _buildSymptomCheckerCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue, width: 1)
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        leading: Icon(Icons.camera_alt_outlined, color: Colors.blue, size: 32),
        title: Text("Visual Symptom Checker", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Have a concern? Get AI-powered insights from a photo."),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SymptomCheckerScreen()),
          );
        },
      ),
    );
  }
}

// ===================================================================
// Appointment Booking Dialog Widget
// ===================================================================
class AppointmentBookingDialog extends StatefulWidget {
  final String userId;
  const AppointmentBookingDialog({Key? key, required this.userId}) : super(key: key);

  @override
  _AppointmentBookingDialogState createState() => _AppointmentBookingDialogState();
}

class _AppointmentBookingDialogState extends State<AppointmentBookingDialog> {
  final ApiService _apiService = ApiService();
  final _reasonController = TextEditingController();
  late Future<List<dynamic>> _vetsFuture;
  String? _selectedVetId;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _vetsFuture = _apiService.getVerifiedVets();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleBooking() async {
    if (_selectedVetId == null || _selectedDay == null || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a vet, date, and enter a reason.")),
      );
      return;
    }
    final ownerId = widget.userId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final result = await _apiService.bookAppointment(
      reason: _reasonController.text,
      ownerId: ownerId,
      vetId: _selectedVetId!,
      selectedDate: _selectedDay!,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading indicator

    if (result['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Appointment Booked Successfully!")));
      Navigator.pop(context, true);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result['body']['msg']}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Book an Appointment"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: FutureBuilder<List<dynamic>>(
            future: _vetsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                   return Text("Could not load vets. Please try again later.");
              }

              final vets = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select Date:", style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8),
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(Duration(days: 90)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    availableCalendarFormats: const { CalendarFormat.month: 'Month'},
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                     headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text("Select Veterinarian:", style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedVetId,
                    isExpanded: true,
                    hint: Text("Choose a Vet"),
                    items: vets.map((vet) {
                      return DropdownMenuItem<String>(
                        value: vet['_id'],
                        child: Text(vet['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() { _selectedVetId = value; });
                    },
                     decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text("Reason for Visit:", style: Theme.of(context).textTheme.titleMedium),
                   SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: "e.g., Annual Checkup",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
        ElevatedButton(onPressed: _handleBooking, child: Text("Confirm Booking")),
      ],
    );
  }
}