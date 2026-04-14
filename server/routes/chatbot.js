const express = require('express');
const router = express.Router();
const axios = require('axios'); // Used for making HTTP requests
require('dotenv').config();

const Pet = require('../models/Pet'); // Import Pet model
const HealthRecord = require('../models/HealthRecord'); // Import Health model

// Get API Key from environment variables
const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  console.error("CRITICAL ERROR: GEMINI_API_KEY not found in .env file.");
}

// Use the 'gemini-2.5-pro-latest' model
const API_ENDPOINT = `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

router.post('/ask', async (req, res) => {
  console.log('Received /ask request (using axios)');
  try {
    const { message, petId } = req.body;
    console.log('User message:', message);
    if (petId) console.log('For petId:', petId);

    if (!message || message.trim() === "") {
      console.log('Error: Message is empty');
      return res.status(400).json({ msg: 'Message cannot be empty.' });
    }

    // --- Build Pet Context ---
    let petContext = ""; 
    if (petId) {
      const pet = await Pet.findById(petId).select('name breed age');
      const latestHealth = await HealthRecord.findOne({ pet: petId }).sort({ timestamp: -1 });
      
      if (pet) {
        petContext = `The user is asking about their pet, ${pet.name}, who is a ${pet.age}-year-old ${pet.breed}.`;
      }
      if (latestHealth) {
        petContext += ` The pet's latest recorded vitals are: Heart Rate: ${latestHealth.heartRate} bpm, Temperature: ${latestHealth.temperature}°C, Activity: ${latestHealth.activityLevel}.`;
      }
    }

    // Construct the payload required by the REST API
    const systemPrompt = "You are a helpful assistant for a pet care app called VetCare. Answer the user's question about pet health or care in a concise and friendly manner, but always remind the user to consult a real veterinarian for serious issues or diagnoses.";
    
    const requestPayload = {
      contents: [{
        parts: [
          { text: systemPrompt },
          { text: `PET CONTEXT: ${petContext}` },
          { text: `USER QUESTION: "${message}"` }
        ]
      }],
    };

    console.log('Sending prompt to Gemini via REST API...');

    const apiResponse = await axios.post(API_ENDPOINT, requestPayload, {
      headers: { 'Content-Type': 'application/json' }
    });

    const replyText = apiResponse.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "Sorry, I received an unexpected response from the AI.";
    console.log('Received response from Gemini:', replyText);

    res.json({ reply: replyText });

  } catch (err) {
    console.error("--- ERROR CALLING GEMINI REST API ---");
    console.error("Timestamp:", new Date().toISOString());
    if (err.response) {
      console.error("Status Code:", err.response.status);
      console.error("Response Data:", JSON.stringify(err.response.data, null, 2));
      const statusCode = err.response.status;
      let errorMsg = err.response.data?.error?.message || 'Server error communicating with AI.';
      if (statusCode === 400 && errorMsg.includes('API key not valid')) {
         errorMsg = 'Server error: Invalid API Key configuration.';
      } else if (statusCode === 404) {
         errorMsg = 'Server error: AI Model not found or API endpoint issue.';
      } else if (statusCode === 429) {
         errorMsg = 'AI service busy or rate limit exceeded. Please try again later.';
      }
      res.status(statusCode).json({ msg: errorMsg });
    } else {
      console.error("Error Message:", err.message);
      res.status(503).json({ msg: 'Server error: Could not reach AI service. Check network/DNS.' });
    }
    console.error("--- END ERROR ---");
  }
});

module.exports = router;