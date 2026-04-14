import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({Key? key}) : super(key: key);

  @override
  _SymptomCheckerScreenState createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final _promptController = TextEditingController();

  File? _imageFile;
  String? _aiResponse;
  bool _isLoading = false;

  // Function to pick an image from the gallery
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _aiResponse = null; // Clear previous response
      });
    }
  }

  // Function to send data to the AI
  void _analyzeSymptom() async {
    if (_imageFile == null || _promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an image and ask a question.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });

    // 1. Read image as bytes
    final imageBytes = await _imageFile!.readAsBytes();
    // 2. Convert to Base64 string
    final imageBase64 = base64Encode(imageBytes);
    // 3. Get MIME type
    final imageMimeType = "image/jpeg"; // Or use a package to detect mime type

    final result = await _apiService.analyzeSymptom(
      prompt: _promptController.text,
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
    );

    setState(() {
      _isLoading = false;
      if (result['statusCode'] == 200) {
        _aiResponse = result['body']['reply'];
      } else {
        _aiResponse = "Error: ${result['body']['msg']}";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Visual Symptom Checker"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image Preview ---
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageFile == null
                  ? Center(child: Text("Select an image to analyze", style: TextStyle(color: Colors.grey)))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
            ),
            SizedBox(height: 16),

            // --- Image Picker Buttons ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text("Gallery"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text("Camera"),
                ),
              ],
            ),
            SizedBox(height: 24),

            // --- Prompt Field ---
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: "What are you concerned about?",
                hintText: "e.g., What is this rash on my dog's belly?",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 24),

            // --- Submit Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeSymptom,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Analyze Symptom"),
            ),
            SizedBox(height: 30),

            // --- AI Response Area ---
            if (_aiResponse != null)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Analysis:",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _aiResponse!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Disclaimer: This is not a medical diagnosis. Please consult a qualified veterinarian for any health concerns.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}