const express = require('express');
const router = express.Router();
const axios = require('axios'); // We'll use axios for our AI call
require('dotenv').config();

// Import all necessary models
const Pet = require('../models/Pet');
const HealthRecord = require('../models/HealthRecord');
const Appointment = require('../models/Appointment');
const User = require('../models/User');

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  console.error("CRITICAL ERROR: GEMINI_API_KEY not found in .env file.");
}
// Use the model that works for your project (gemini-1.5-pro-latest)
const API_ENDPOINT = `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

// --- HELPER FUNCTION: Calculate average values from records ---
function calculateBaseline(records) {
  if (!records || records.length === 0) {
    return null;
  }
  const totals = { heartRate: 0, temperature: 0, count: 0 };
  for (const record of records) {
    if (record.heartRate && record.temperature) {
      totals.heartRate += record.heartRate;
      totals.temperature += record.temperature;
      totals.count++;
    }
  }
  if (totals.count === 0) return null;
  return {
    avgHeartRate: totals.heartRate / totals.count,
    avgTemperature: totals.temperature / totals.count,
  };
}

// --- HELPER FUNCTION: AI ANALYSIS LOGIC ---
function analyzeHealth(latestRecord, baseline) {
  if (!latestRecord || !baseline) {
    return { status: "Normal", message: "Not enough data to analyze." };
  }
  const { heartRate, temperature, activityLevel } = latestRecord;
  // Rule 1: Fever Detection
  if (temperature > 39.2) {
    return {
      status: "Warning",
      message: `Fever Alert: Pet's temperature is ${temperature.toFixed(1)}°C, which is above the normal range.`
    };
  }
  // Rule 2: High Resting Heart Rate
  if (activityLevel === 'Resting' && heartRate > (baseline.avgHeartRate * 1.3)) { // 30% above average
    return {
      status: "Warning",
      message: `High Heart Rate: Pet's resting heart rate is ${heartRate} bpm, which is significantly higher than their average.`
    };
  }
  return {
    status: "Normal",
    message: "Pet's vitals appear to be within their normal range."
  };
}

// @route   GET /api/analysis/pet/:petId
// @desc    Analyze a pet's health and detect anomalies
router.get('/pet/:petId', async (req, res) => {
  try {
    const pet = await Pet.findById(req.params.petId);
    if (!pet) return res.status(404).json({ msg: 'Pet not found' });

    const history = await HealthRecord.find({ pet: req.params.petId }).sort({ timestamp: -1 }).limit(10);
    if (history.length === 0) {
      return res.json({ status: "Normal", message: "No health data recorded yet." });
    }

    const latestRecord = history[0];
    const baseline = calculateBaseline(history);
    const analysis = analyzeHealth(latestRecord, baseline);
    res.json(analysis);

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// --- NEW ROUTE ADDED BELOW ---
// @route   GET /api/analysis/user/:userId/recommendations
// @desc    Generate proactive recommendations for a user
router.get('/user/:userId/recommendations', async (req, res) => {
  console.log('Received /recommendations request');
  try {
    const user = await User.findById(req.params.userId).select('-password');
    if (!user) return res.status(404).json({ msg: 'User not found' });

    // 1. Gather all data
    const pets = await Pet.find({ owner: user._id });
    const appointments = await Appointment.find({ owner: user._id }).sort({ date: 1 });

    // 2. Create a "context profile" for the AI
    let context = `--- USER PROFILE ---\nUser Name: ${user.name}\n`;
    
    pets.forEach(pet => {
      context += `Pet Name: ${pet.name}, Breed: ${pet.breed}, Age: ${pet.age}\n`;
      // Add simplified medical info
      if (pet.vaccinations && pet.vaccinations.length > 0) {
        context += `Vaccinations: ${pet.vaccinations.length} records on file.\n`;
      } else {
        context += `Vaccinations: None listed.\n`;
      }
      if (pet.allergies && pet.allergies.length > 0) {
        context += `Allergies: ${pet.allergies.map(a => a.description).join(', ')}\n`;
      }
    });

    const upcomingAppointments = appointments.filter(a => new Date(a.date) > new Date() && a.status === 'Scheduled');
    if (upcomingAppointments.length > 0) {
      context += `Upcoming Appointments: ${upcomingAppointments.length}\n`;
    } else {
      context += `Upcoming Appointments: None\n`;
    }
    context += `--- END PROFILE ---\n`;

    // 3. Create the AI Prompt
    const prompt = `You are a proactive wellness assistant for the VetCare app. Analyze the following user profile and provide **one single, concise, and helpful recommendation**.
    - If a pet is old (8+ years) and has no appointments, suggest a senior wellness checkup.
    - If a pet has no vaccinations listed, recommend scheduling a vaccination appointment.
    - If an appointment is upcoming, provide a simple reminder.
    - If health is good and appointments are set, just give a simple wellness tip (e.g., 'Remember to check ${pets[0]?.name || 'your pet'}'s water bowl!').
    Keep the message friendly and under 40 words.
    
    ${context}
    
    Recommendation:`;

    // 4. Send to AI
    const requestPayload = { contents: [{ parts: [{ text: prompt }] }] };
    console.log('Sending recommendation prompt to Gemini...');

    const apiResponse = await axios.post(API_ENDPOINT, requestPayload, {
      headers: { 'Content-Type': 'application/json' }
    });

    const replyText = apiResponse.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "No recommendations at this time, but have a great day!";
    console.log('Received recommendation:', replyText);

    res.json({ recommendation: replyText });

  } catch (err) {
    console.error("--- ERROR GETTING RECOMMENDATION ---");
    // (Full error handling as in chatbot.js)
    if (err.response) {
      console.error("Status Code:", err.response.status);
      console.error("Response Data:", JSON.stringify(err.response.data, null, 2));
      res.status(err.response.status).json({ recommendation: "Could not fetch AI recommendations." });
    } else {
      console.error("Error Message:", err.message);
      res.status(500).json({ recommendation: "Could not connect to AI service." });
    }
  }
});

module.exports = router;