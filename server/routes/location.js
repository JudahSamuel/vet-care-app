const express = require('express');
const router = express.Router();
const Pet = require('../models/Pet');
const PetLocation = require('../models/PetLocation');

// @route   POST /api/location/update
// @desc    (FUTURE USE) Webhook endpoint for GPS hardware to send data
router.post('/update', async (req, res) => {
  try {
    const { petId, deviceId, latitude, longitude, timestamp } = req.body;
    
    // Find the pet
    const pet = await Pet.findById(petId);
    if (!pet) {
       // If pet isn't found by petId, maybe find by deviceId
       const petByDevice = await Pet.findOne({ gpsDeviceId: deviceId });
       if (!petByDevice) return res.status(404).json({ msg: 'Pet not found' });
       // If found, use this pet's ID
       req.body.petId = petByDevice._id;
    }

    const newLocation = new PetLocation({
      pet: req.body.petId,
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ? new Date(timestamp) : new Date()
    });

    await newLocation.save();
    res.status(201).send('Location data received');

  } catch (err) {
    console.error("Error in /api/location/update:", err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET /api/location/pet/:petId/latest
// @desc    Get the most recent GPS location for a specific pet
router.get('/pet/:petId/latest', async (req, res) => {
  try {
    const pet = await Pet.findById(req.params.petId);
    if (!pet) {
      return res.status(404).json({ msg: 'Pet not found' });
    }

    const latestLocation = await PetLocation.findOne({ pet: req.params.petId })
      .sort({ timestamp: -1 });

    if (!latestLocation) {
      return res.status(200).json(null); // No location found
    }

    res.json(latestLocation);

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// (Your mock data generator route can remain here for testing)
router.get('/pet/:petId/generate-mock', async (req, res) => { /* ... */ });

module.exports = router;