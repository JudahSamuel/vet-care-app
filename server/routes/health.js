const express = require('express');
const router = express.Router();

const Pet = require('../models/Pet');
const HealthRecord = require('../models/HealthRecord');

// @route   GET /api/health/pet/:petId/latest
// @desc    Get the most recent health record for a specific pet
router.get('/pet/:petId/latest', async (req, res) => {
  try {
    const pet = await Pet.findById(req.params.petId);
    if (!pet) {
      return res.status(404).json({ msg: 'Pet not found' });
    }

    const latestRecord = await HealthRecord.findOne({ pet: req.params.petId })
      .sort({ timestamp: -1 });

    if (!latestRecord) {
      return res.status(200).json(null);
    }

    res.json(latestRecord);

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// --- NEW ROUTE ADDED BELOW ---
// @route   GET /api/health/pet/:petId/history
// @desc    Get all health records for a specific pet, sorted by date
router.get('/pet/:petId/history', async (req, res) => {
  try {
    const pet = await Pet.findById(req.params.petId);
    if (!pet) {
      return res.status(404).json({ msg: 'Pet not found' });
    }

    // Find all records for this pet and sort by the recorded timestamp
    const records = await HealthRecord.find({ pet: req.params.petId })
      .sort({ timestamp: -1 }); // Newest records first

    res.json(records);

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});


// @route   POST /api/health/update
// @desc    (FUTURE USE) Webhook endpoint for the hardware to send data
router.post('/update', async (req, res) => {
  console.log("Received data from hardware:", req.body);
  res.status(200).send('Data received');
});


// @route   GET /api/health/pet/:petId/generate-mock
// @desc    Generate fake health data for a pet (for testing)
router.get('/pet/:petId/generate-mock', async (req, res) => {
  try {
    const pet = await Pet.findById(req.params.petId);
    if (!pet) {
      return res.status(404).json({ msg: 'Pet not found' });
    }
    
    // Generate 3 fake records
    const records = [];
    for (let i = 0; i < 3; i++) {
      const newRecord = new HealthRecord({
        pet: pet._id,
        deviceId: pet.healthDeviceId || "mock_device_123",
        timestamp: new Date(Date.now() - i * 60 * 60 * 1000), // 1 hour ago, 2 hours ago...
        heartRate: 70 + Math.floor(Math.random() * 20),
        temperature: 38.5 + (Math.random() - 0.5),
        activityLevel: ['Resting', 'Walking', 'Playing'][i % 3],
        caloriesBurned: 50 + Math.floor(Math.random() * 50),
      });
      await newRecord.save();
      records.push(newRecord);
    }
    
    res.status(201).json({ msg: 'Mock data generated!', records });
    
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;