const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  // --- MODIFICATION ---
  // Password is no longer required, as a user can sign in with Google
  password: {
    type: String,
    required: false, // <-- Changed from true
  },
  // --- NEW FIELDS ---
  authMethod: {
    type: String,
    enum: ['email', 'google'], // Tracks how the user was created
    default: 'email',
  },
  googleId: { // Stores the user's unique Google ID
    type: String,
    unique: true,
    sparse: true, // Allows multiple null values, but ensures non-nulls are unique
  }
});

const User = mongoose.model('User', userSchema);

module.exports = User;