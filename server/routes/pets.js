const express = require('express');
const router = express.Router();

const Pet = require('../models/Pet');
const Appointment = require('../models/Appointment');

// @route   POST /api/pets/add
// @desc    Add a new pet for a user
router.post('/add', async (req, res) => {
  try {
    const { name, breed, age, ownerId } = req.body;

    if (!name || !breed || !age || !ownerId) {
      return res.status(400).json({ msg: 'Please provide all pet details.' });
    }

    const newPet = new Pet({
      name,
      breed,
      age,
      owner: ownerId,
    });

    await newPet.save();

    res.status(201).json({ msg: 'Pet added successfully!', pet: newPet });

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// --- UPDATED ROUTE ---
// @route   GET /api/pets/:id
// @desc    Get all details for a single pet, including its appointments
router.get('/:id', async (req, res) => {
  try {
    const petId = req.params.id;

    // Find the pet by its unique ID
    const pet = await Pet.findById(petId);
    if (!pet) {
      return res.status(404).json({ msg: 'Pet not found' });
    }

    // Now, find all appointments for this specific pet
    // and populate the vet's name for each appointment.
    const appointments = await Appointment.find({ owner: pet.owner, /* In a more complex app, you'd link appointments directly to pets */ })
      .populate('vet', 'name')
      .sort({ date: -1 }); // Sort by date, most recent first

    // Send back both the pet's details and their appointments
    res.json({ pet, appointments });

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;