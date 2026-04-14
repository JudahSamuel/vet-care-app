// server/routes/users.js

const express = require('express');
const router = express.Router();

const User = require('../models/User');
const Pet = require('../models/Pet');
const Appointment = require('../models/Appointment');

// @route   GET /api/users/:id/dashboard
// @desc    Get all dashboard data for a specific user
router.get('/:id/dashboard', async (req, res) => {
  try {
    const userId = req.params.id;

    const user = await User.findById(userId).select('-password');
    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    const pets = await Pet.find({ owner: userId });

    // ✅ THE CHANGE IS HERE: Populate the 'vet' field
    // This looks up the vet by their ID and includes their name in the response.
    const appointments = await Appointment.find({ owner: userId }).populate('vet', 'name');

    res.json({
      user,
      pets,
      appointments,
    });

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;