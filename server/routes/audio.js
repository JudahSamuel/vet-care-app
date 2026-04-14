const express = require('express');
const router = express.Router();
const axios = require('axios');
require('dotenv').config();

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  console.error("CRITICAL ERROR: GEMINI_API_KEY not found in .env file.");
}

// Use the fast 'flash' model for audio analysis
const API_ENDPOINT = `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-latest:generateContent?key=${apiKey}`;

// @route   POST /api/audio/analyze
// @desc    Analyze a pet's vocalization
router.post('/analyze', async (req, res) => {
  console.log('Received /api/audio/analyze request');
  try {
    const { audioBase64, audioMimeType } = req.body;

    if (!audioBase64 || !audioMimeType) {
      return res.status(400).json({ msg: 'Missing audioBase64 or audioMimeType.' });
    }
    
    // Prompt for the AI
    const systemPrompt = `You are an AI pet mood analyzer. A user has recorded their pet's sound. Analyze the audio and respond with a simple, friendly classification of the likely emotion (e.g., "Playful," "Anxious," "Warning," "Greeting," "Hungry," or "Curious"). Provide a very brief, one-sentence explanation. Always add a disclaimer that this is for entertainment and not a substitute for professional observation.`;
    
    // Construct the payload for the API
    const requestPayload = {
      contents: [
        {
          parts: [
            { text: systemPrompt },
            { text: "Please analyze this sound:" },
            {
              inlineData: {
                mimeType: audioMimeType, // e.g., 'audio/wav'
                data: audioBase64        // The pure Base64 string
              }
            }
          ]
        }
      ]
    };

    console.log('Sending audio to Gemini...');
    
    // Send the request
    const apiResponse = await axios.post(API_ENDPOINT, requestPayload, {
      headers: { 'Content-Type': 'application/json' }
    });

    const replyText = apiResponse.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "Sorry, I couldn't analyze the audio.";
    console.log('Received response from Gemini:', replyText);
    res.json({ reply: replyText });

  } catch (err) {
    console.error("--- ERROR CALLING GEMINI AUDIO API ---");
    if (err.response) {
      console.error("Status Code:", err.response.status);
      console.error("Response Data:", JSON.stringify(err.response.data, null, 2));
      const statusCode = err.response.status;
      let errorMsg = err.response.data?.error?.message || 'Server error communicating with AI.';
      if (statusCode === 429 || (err.response.data?.error?.code === 503)) {
         errorMsg = 'AI service is busy or overloaded. Please try again later.';
      }
      res.status(statusCode).json({ msg: errorMsg });
    } else {
      console.error("Error Message:", err.message);
      res.status(503).json({ msg: 'Server error: Could not reach AI service.' });
    }
    console.error("--- END ERROR ---");
  }
});

module.exports = router;