// server/routes/vets.js

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const Vet = require('../models/Vet');
const Appointment = require('../models/Appointment');

// @route   POST /api/vets/login
// @desc    Authenticate a vet and return a token
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find the vet by email
    const vet = await Vet.findOne({ email });
    if (!vet) {
      return res.status(400).json({ msg: 'Invalid credentials' });
    }

    // Since we don't hash vet passwords yet, we'll do a simple compare.
    // In a real app, you would hash vet passwords upon registration.
    if (password !== vet.password) {
        return res.status(400).json({ msg: 'Invalid credentials' });
    }

    // Ensure the vet is verified before allowing login
    if (!vet.isVerified) {
        return res.status(401).json({ msg: 'Account not verified. Please contact admin.' });
    }
    
    // Create and sign a JWT
    const payload = { vet: { id: vet.id } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        res.json({ token, vetId: vet.id });
      }
    );
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});


// @route   GET /api/vets/verified
// @desc    Get a list of all verified vets for booking
router.get('/verified', async (req, res) => {
  try {
    const vets = await Vet.find({ isVerified: true }).select('-password');
    res.json(vets);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET /api/vets/:id/dashboard
// @desc    Get all dashboard data for a specific vet
router.get('/:id/dashboard', async (req, res) => {
    try {
        const vetId = req.params.id;

        // Find all appointments assigned to this vet
        // Populate owner's name and email for display
        const appointments = await Appointment.find({ vet: vetId })
            .populate('owner', 'name email');

        res.json({ appointments });

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;