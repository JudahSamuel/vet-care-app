const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { OAuth2Client } = require('google-auth-library'); // <-- 1. IMPORT GOOGLE AUTH

// 2. CREATE GOOGLE CLIENT (get this ID from Google Cloud Console)
const GOOGLE_CLIENT_ID = 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';
const client = new OAuth2Client(GOOGLE_CLIENT_ID);


// --- REGISTRATION ROUTE (for email/password) ---
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ msg: 'Please enter all fields' });
    }
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ msg: 'User with this email already exists' });
    }
    user = new User({ name, email, password, authMethod: 'email' });
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(password, salt);
    await user.save();

    const payload = { user: { id: user.id } };
    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '5h' }, (err, token) => {
      if (err) throw err;
      res.status(201).json({ token, userId: user.id });
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});


// --- LOGIN ROUTE (for email/password) ---
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email, authMethod: 'email' }); // Only find email/pass users
    if (!user) {
      return res.status(400).json({ msg: 'Invalid credentials or user signed up with Google' });
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ msg: 'Invalid credentials' });
    }
    const payload = { user: { id: user.id } };
    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '5h' }, (err, token) => {
      if (err) throw err;
      res.json({ token, userId: user.id });
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});


// --- 3. NEW GOOGLE SIGN-IN ROUTE ---
// @route   POST /api/auth/google
// @desc    Authenticate user with Google idToken
router.post('/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ msg: 'Google token is required.' });
    }

    // 4. Verify the token with Google
    const ticket = await client.verifyIdToken({
        idToken: idToken,
        audience: GOOGLE_CLIENT_ID, // Specify the CLIENT_ID
    });
    const payload = ticket.getPayload();
    
    // 5. Get user info from the verified token
    const { sub: googleId, email, name } = payload;

    // 6. Find or create the user in our database
    let user = await User.findOne({ googleId: googleId });

    if (!user) {
      // User doesn't exist, create a new one
      user = new User({
        googleId: googleId,
        email: email,
        name: name,
        authMethod: 'google',
        // Password is not required
      });
      await user.save();
    }

    // 7. User exists or was just created. Create our app's JWT
    const appPayload = {
      user: {
        id: user.id
      }
    };

    jwt.sign(
      appPayload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        // 8. Send our token and user ID back to the app
        res.json({ token, userId: user.id });
      }
    );

  } catch (err) {
    console.error('Google Auth Error:', err.message);
    res.status(500).send('Server error during Google authentication');
  }
});


module.exports = router;