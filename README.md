🐾 VetCare (PawTech)
VetCare is a comprehensive, cross-platform pet care and tracking application designed to help pet owners monitor their pets' health, manage medical records, and track their location in real-time using custom IoT hardware.

✨ Key Features
📍 Real-Time GPS Tracking: Integrated with Google Maps and third-party APIs to keep tabs on your pet's exact location at all times.

🌡️ Smart Health & Activity Monitoring: Pairs with a custom ESP32 wearable device to track movement and vitals using MPU-6050 (accelerometer/gyroscope) and DS18B20 (temperature) sensors.

🤖 AI Pet Care Chatbot: An integrated smart assistant to answer quick questions about pet care, diet, and behavior.

📋 Comprehensive Dashboard: A clean, intuitive UI to easily manage multiple pets, log medical records, and track upcoming vet appointments.

🔐 Secure Authentication & Sync: Real-time data synchronization and secure user authentication powered by Firebase.

🛠️ Tech Stack
Mobile Application:

Frontend: Flutter (Dart) for cross-platform iOS and Android support

Backend & Database: Firebase (Authentication, Cloud Firestore, Realtime Database)

Maps Integration: Google Maps API

IoT Hardware Wearable:

Microcontroller: ESP32

Sensors: MPU-6050 (Motion/Activity), DS18B20 (Temperature)

Programming Language: C / C++

🚀 Getting Started
Follow these instructions to set up the VetCare mobile app and IoT environment locally.

Prerequisites
Flutter SDK installed

An active Firebase Project

Arduino IDE or PlatformIO for the ESP32 hardware setup

Mobile App Installation
Clone the repository:

Bash
git clone https://github.com/your-username/vetcare.git
cd vetcare
Install Flutter dependencies:

Bash
flutter pub get
Firebase Setup:

Add your google-services.json file to the android/app directory.

Add your GoogleService-Info.plist file to the ios/Runner directory.

Run the App:

Bash
flutter run
IoT Hardware Setup (ESP32)
Navigate to the /hardware directory in the project.

Open the .ino or .cpp file in the Arduino IDE.

Ensure you have the required sensor libraries installed (Adafruit_MPU6050, OneWire, DallasTemperature).

Update the Wi-Fi credentials and Firebase/API endpoint URLs in the configuration section of the code.

Connect your ESP32 board and flash the code.

🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the issues page if you want to contribute.

👨‍💻 Author
Judah - Full Stack Developer

Empowering pet owners with smart tracking and proactive care.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
