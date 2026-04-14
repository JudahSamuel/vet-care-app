// server/models/Vet.js
const mongoose = require('mongoose');

const vetSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  specialization: { type: String, default: 'General Practice' },
  isVerified: { type: Boolean, default: false }, // Vets can't receive bookings until this is true
});

const Vet = mongoose.model('Vet', vetSchema);
module.exports = Vet;