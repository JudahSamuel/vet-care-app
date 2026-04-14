import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddPetScreen extends StatefulWidget {
  final String ownerId;

  const AddPetScreen({Key? key, required this.ownerId}) : super(key: key);

  @override
  _AddPetScreenState createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final ApiService _apiService = ApiService();

  // State variables for the dropdowns
  String? _selectedAnimalType;
  String? _selectedBreed;
  List<String> _breeds = [];
  bool _isBreedLoading = false;

  final List<String> _animalTypes = ['dog', 'cat', 'cattle'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // --- Logic for the dependent dropdown ---
  void _onAnimalTypeChanged(String? newValue) {
    if (newValue == null || newValue == _selectedAnimalType) return;
    
    setState(() {
      _selectedAnimalType = newValue;
      _selectedBreed = null; // Reset breed
      _breeds = []; // Clear old breed list
      _isBreedLoading = true;
    });

    _fetchBreeds(newValue);
  }

  void _fetchBreeds(String animalType) async {
    final breeds = await _apiService.getBreeds(animalType);
    setState(() {
      _breeds = breeds;
      _isBreedLoading = false;
      // If there's only one option (like for 'cattle'), select it
      if (_breeds.length == 1) {
        _selectedBreed = _breeds.first;
      }
    });
  }
  // --- End of dropdown logic ---

  void _handleAddPet() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAnimalType == null || _selectedBreed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select an animal type and breed.")),
        );
        return;
      }

      final result = await _apiService.addPet(
        name: _nameController.text,
        breed: _selectedBreed!,
        age: int.parse(_ageController.text),
        ownerId: widget.ownerId,
      );

      if (!mounted) return;

      if (result['statusCode'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pet added successfully!")),
        );
        Navigator.pop(context, true); // Go back and signal success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${result['body']['msg']}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add a New Pet")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Pet's Name"),
                validator: (value) => value!.isEmpty ? "Please enter a name" : null,
              ),
              SizedBox(height: 20),

              // --- Animal Type Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedAnimalType,
                hint: Text('Select Animal Type'),
                items: _animalTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                }).toList(),
                onChanged: _onAnimalTypeChanged,
                validator: (value) => value == null ? "Please select an animal" : null,
              ),
              SizedBox(height: 20),

              // --- Breed Dropdown (Dynamic) ---
              if (_isBreedLoading)
                Center(child: CircularProgressIndicator())
              else if (_selectedAnimalType != null)
                DropdownButtonFormField<String>(
                  value: _selectedBreed,
                  hint: Text('Select Breed'),
                  items: _breeds.map((breed) {
                    return DropdownMenuItem(value: breed, child: Text(breed));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() { _selectedBreed = newValue; });
                  },
                  validator: (value) => value == null ? "Please select a breed" : null,
                ),
              SizedBox(height: 20),
              
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: "Age (Years)"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Please enter an age" : null,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _handleAddPet,
                child: Text("Save Pet"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}