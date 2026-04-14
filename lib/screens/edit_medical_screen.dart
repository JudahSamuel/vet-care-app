import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

// Helper class for Vaccination data
class Vaccination {
  String vaccineName;
  DateTime? dateAdministered;
  DateTime? nextDueDate;

  Vaccination({this.vaccineName = '', this.dateAdministered, this.nextDueDate});

  // Convert to JSON for sending to the server
  Map<String, dynamic> toJson() => {
    'vaccineName': vaccineName,
    'dateAdministered': dateAdministered?.toIso8601String(),
    'nextDueDate': nextDueDate?.toIso8601String(),
  };

  // Create from JSON (from the server)
  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      vaccineName: json['vaccineName'] ?? '',
      dateAdministered: json['dateAdministered'] != null ? DateTime.parse(json['dateAdministered']) : null,
      nextDueDate: json['nextDueDate'] != null ? DateTime.parse(json['nextDueDate']) : null,
    );
  }
}

class EditMedicalScreen extends StatefulWidget {
  final String petId;
  final Function onMedicalUpdated; // Callback to refresh the previous screen

  const EditMedicalScreen({Key? key, required this.petId, required this.onMedicalUpdated}) : super(key: key);

  @override
  _EditMedicalScreenState createState() => _EditMedicalScreenState();
}

class _EditMedicalScreenState extends State<EditMedicalScreen> {
  final ApiService _apiService = ApiService();
  final _notesController = TextEditingController();
  final _allergyController = TextEditingController();
  
  List<Vaccination> _vaccinations = [];
  List<String> _allergies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicalData();
  }

  // Fetch the pet's current medical data
  void _loadMedicalData() async {
    try {
      final data = await _apiService.getPetDetails(widget.petId);
      final pet = data['pet'];

      setState(() {
        _notesController.text = pet['medicalNotes'] ?? '';
        
        // Parse vaccinations
        _vaccinations = (pet['vaccinations'] as List? ?? [])
            .map((v) => Vaccination.fromJson(v))
            .toList();
        
        // Simple allergy list (we'll keep it simple for this UI)
        _allergies = (pet['allergies'] as List? ?? [])
            .map((a) => a['description'].toString())
            .toList();
            
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading data: $e")));
    }
  }

  // --- Save All Data ---
  void _handleSaveMedicalData() async {
    setState(() { _isLoading = true; });

    // Convert simple allergy strings back to the object format the server expects
    final allergyPayload = _allergies.map((desc) => {'description': desc, 'type': 'General'}).toList();
    
    // Convert Vaccination objects to JSON
    final vaccinationPayload = _vaccinations.map((v) => v.toJson()).toList();

    final result = await _apiService.updateMedicalRecords(
      petId: widget.petId,
      medicalNotes: _notesController.text,
      allergies: allergyPayload,
      vaccinations: vaccinationPayload,
    );

    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (result['statusCode'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Medical records updated!")));
      widget.onMedicalUpdated(); // Call the refresh callback
      Navigator.pop(context); // Go back
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result['body']['msg']}")));
    }
  }

  // --- UI for adding a new vaccination ---
  void _showVaccinationDialog({Vaccination? existingVaccine, int? index}) {
    final nameController = TextEditingController(text: existingVaccine?.vaccineName);
    DateTime? administeredDate = existingVaccine?.dateAdministered;
    DateTime? dueDate = existingVaccine?.nextDueDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingVaccine == null ? "Add Vaccination" : "Edit Vaccination"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  // ✅ --- THIS IS THE FIX ---
                  mainAxisSize: MainAxisSize.min, // Was MainAxisSizeCmin
                  // --- END FIX ---
                  children: [
                    TextField(controller: nameController, decoration: InputDecoration(labelText: "Vaccine Name")),
                    SizedBox(height: 16),
                    Text("Date Administered: ${administeredDate == null ? 'Not set' : DateFormat.yMd().format(administeredDate!)}"),
                    ElevatedButton(
                      child: Text("Select Date"),
                      onPressed: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                        if (date != null) setStateDialog(() => administeredDate = date);
                      },
                    ),
                    SizedBox(height: 16),
                    Text("Next Due Date: ${dueDate == null ? 'Not set' : DateFormat.yMd().format(dueDate!)}"),
                    ElevatedButton(
                      child: Text("Select Date"),
                      onPressed: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2040));
                        if (date != null) setStateDialog(() => dueDate = date);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(context)),
            TextButton(
              child: Text("Save"),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    final newVaccine = Vaccination(
                      vaccineName: nameController.text,
                      dateAdministered: administeredDate,
                      nextDueDate: dueDate,
                    );
                    if (index != null) {
                      _vaccinations[index] = newVaccine; // Update existing
                    } else {
                      _vaccinations.add(newVaccine); // Add new
                    }
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- UI for adding a new allergy ---
  void _showAllergyDialog() {
    _allergyController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Allergy"),
          content: TextField(controller: _allergyController, decoration: InputDecoration(labelText: "Allergy Description (e.g., Pollen)")),
          actions: [
            TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(context)),
            TextButton(
              child: Text("Add"),
              onPressed: () {
                if (_allergyController.text.isNotEmpty) {
                  setState(() {
                    _allergies.add(_allergyController.text);
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Medical Records"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: "Save Changes",
            onPressed: _handleSaveMedicalData,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // --- VACCINATIONS SECTION ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Vaccinations", style: Theme.of(context).textTheme.titleLarge),
                    IconButton(icon: Icon(Icons.add), onPressed: _showVaccinationDialog),
                  ],
                ),
                if (_vaccinations.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text("No vaccination records added.")))
                else
                  ..._vaccinations.map((v) {
                    int index = _vaccinations.indexOf(v);
                    return ListTile(
                      title: Text(v.vaccineName),
                      subtitle: Text("Due: ${v.nextDueDate == null ? 'N/A' : DateFormat.yMd().format(v.nextDueDate!)}"),
                      trailing: IconButton(icon: Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _vaccinations.removeAt(index))),
                      onTap: () => _showVaccinationDialog(existingVaccine: v, index: index),
                    );
                  }),
                
                SizedBox(height: 30),

                // --- ALLERGIES SECTION ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Allergies", style: Theme.of(context).textTheme.titleLarge),
                    IconButton(icon: Icon(Icons.add), onPressed: _showAllergyDialog),
                  ],
                ),
                if (_allergies.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text("No allergies listed.")))
                else
                  ..._allergies.map((a) {
                    return ListTile(
                      title: Text(a),
                      trailing: IconButton(icon: Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _allergies.remove(a))),
                    );
                  }),
                
                SizedBox(height: 30),

                // --- GENERAL NOTES SECTION ---
                Text("General Medical Notes", style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter any general notes about your pet's health...",
                  ),
                ),
              ],
            ),
    );
  }
}