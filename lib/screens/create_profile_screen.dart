import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({Key? key}) : super(key: key);

  @override
  _CreateProfilePageState createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controllers for User
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controllers for Pet
  final _petNameController = TextEditingController();
  final _petAgeController = TextEditingController();
  String? _gender;

  // --- State for new dropdowns ---
  String? _selectedAnimalType;
  String? _selectedBreed;
  List<String> _breeds = [];
  bool _isBreedLoading = false;
  final List<String> _animalTypes = ['dog', 'cat', 'cattle'];
  // ---------------------------------

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _petNameController.dispose();
    _petAgeController.dispose();
    super.dispose();
  }

  // --- Logic for the dependent dropdown ---
  void _onAnimalTypeChanged(String? newValue) {
    if (newValue == null || newValue == _selectedAnimalType) return;
    
    setState(() {
      _selectedAnimalType = newValue;
      _selectedBreed = null;
      _breeds = [];
      _isBreedLoading = true;
    });
    _fetchBreeds(newValue);
  }

  void _fetchBreeds(String animalType) async {
    final breeds = await _apiService.getBreeds(animalType);
    setState(() {
      _breeds = breeds;
      _isBreedLoading = false;
      if (_breeds.length == 1) {
        _selectedBreed = _breeds.first;
      }
    });
  }
  // --- End of dropdown logic ---

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }

    setState(() { _isLoading = true; });

    try {
      // Step 1: Register the User
      final regResult = await _apiService.registerUser(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      if (regResult['statusCode'] != 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: ${regResult['body']['msg']}")),
        );
        setState(() { _isLoading = false; });
        return;
      }

      final String userId = regResult['body']['userId'];

      // Step 2: Add their first pet
      final petResult = await _apiService.addPet(
        name: _petNameController.text,
        breed: _selectedBreed!, // Use the selected breed
        age: int.parse(_petAgeController.text),
        ownerId: userId,
      );
      
      if (!mounted) return;
      if (petResult['statusCode'] == 201) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              gender: _gender ?? 'male', // Gender is for the pet
              userId: userId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account created, but failed to add pet: ${petResult['body']['msg']}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Your Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- User Details Section ---
              Text("Your Details", style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Your Name",
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) => value!.isEmpty ? "Please enter your name" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value!.isEmpty || !value.contains('@')) ? "Please enter a valid email" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                obscureText: true,
                validator: (value) => (value!.length < 6) ? "Password must be at least 6 characters" : null,
              ),
              SizedBox(height: 30),

              // --- Pet Details Section ---
              Text("Your First Pet", style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 16),
              TextFormField(
                controller: _petNameController,
                decoration: InputDecoration(
                  labelText: "Pet's Name",
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) => value!.isEmpty ? "Please enter your pet's name" : null,
              ),
              SizedBox(height: 16),

              // --- Animal Type Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedAnimalType,
                hint: Text('Select Animal Type'),
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _animalTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                }).toList(),
                onChanged: _onAnimalTypeChanged,
                validator: (value) => value == null ? "Please select an animal" : null,
              ),
              SizedBox(height: 16),

              // --- Breed Dropdown (Dynamic) ---
              if (_isBreedLoading)
                Center(child: CircularProgressIndicator())
              else if (_selectedAnimalType != null)
                DropdownButtonFormField<String>(
                  value: _selectedBreed,
                  hint: Text('Select Breed'),
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _breeds.map((breed) {
                    return DropdownMenuItem(value: breed, child: Text(breed));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() { _selectedBreed = newValue; });
                  },
                  validator: (value) => value == null ? "Please select a breed" : null,
                ),
              SizedBox(height: 16),

              TextFormField(
                controller: _petAgeController,
                decoration: InputDecoration(
                  labelText: "Pet's Age (Years)",
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Please enter your pet's age" : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                hint: Text('Select Pet Gender'),
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: ['Male', 'Female']
                    .map((g) => DropdownMenuItem(value: g.toLowerCase(), child: Text(g)))
                    .toList(),
                onChanged: (val) {
                  setState(() { _gender = val; });
                },
                validator: (value) => value == null ? "Please select a gender" : null,
              ),
              SizedBox(height: 40),

              // --- Submit Button ---
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text("Create Account & Add Pet", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}