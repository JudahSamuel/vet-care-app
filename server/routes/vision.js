const express = require('express');
const router = express.Router();
const axios = require('axios');
require('dotenv').config();

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  console.error("CRITICAL ERROR: GEMINI_API_KEY not found in .env file.");
}

// --- Use a Multimodal Model ---
// We use 'gemini-1.5-pro-latest' which can handle both text and images
const API_ENDPOINT = `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

// @route   POST /api/vision/analyze
// @desc    Analyze an image of a pet's symptom
router.post('/analyze', async (req, res) => {
  console.log('Received /api/vision/analyze request');
  try {
    const { prompt, imageBase64, imageMimeType } = req.body;

    if (!prompt || !imageBase64 || !imageMimeType) {
      return res.status(400).json({ msg: 'Missing prompt, imageBase64, or imageMimeType.' });
    }
    
    // 1. Define the system-level prompt for safety
    const systemPrompt = "You are a helpful assistant for a pet care app. A user is sending you a picture of their pet to ask about a visual symptom. Analyze the image and the user's question. Provide general information about possible conditions, but DO NOT provide a diagnosis. You MUST strongly recommend they consult a real veterinarian for a proper diagnosis and treatment.";

    // 2. Construct the multimodal payload for the API
    const requestPayload = {
      contents: [
        {
          parts: [
            { text: systemPrompt },
            { text: `User's question: "${prompt}"` },
            {
              inlineData: {
                mimeType: imageMimeType, // e.g., 'image/jpeg'
                data: imageBase64        // The pure Base64 string
              }
            }
          ]
        }
      ]
    };

    console.log('Sending prompt and image to Gemini...');
    
    // 3. Make the POST request using axios
    const apiResponse = await axios.post(API_ENDPOINT, requestPayload, {
      headers: { 'Content-Type': 'application/json' }
    });

    // 4. Extract and send the response
    const replyText = apiResponse.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "Sorry, I couldn't analyze the image.";
    console.log('Received response from Gemini:', replyText);
    res.json({ reply: replyText });

  } catch (err) {
    console.error("--- ERROR CALLING GEMINI VISION API ---");
    if (err.response) {
      console.error("Status Code:", err.response.status);
      console.error("Response Data:", JSON.stringify(err.response.data, null, 2));
      const statusCode = err.response.status;
      let errorMsg = err.response.data?.error?.message || 'Server error communicating with AI.';
      res.status(statusCode).json({ msg: errorMsg });
    } else {
      console.error("Error Message:", err.message);
      res.status(503).json({ msg: 'Server error: Could not reach AI service.' });
    }
    console.error("--- END ERROR ---");
  }
});

module.exports = router;