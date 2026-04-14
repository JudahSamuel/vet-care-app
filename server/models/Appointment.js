const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  date: {
    type: Date,
    required: true,
  },
  reason: {
    type: String,
    required: true,
    trim: true,
  },
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  vet: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vet',
    required: true,
  },
  // --- NEW FIELD ADDED ---
  status: {
    type: String,
    required: true,
    enum: ['Scheduled', 'Completed', 'Cancelled'], // Only allows these values
    default: 'Scheduled', // New appointments will default to 'Scheduled'
  },
}, { timestamps: true });

const Appointment = mongoose.model('Appointment', appointmentSchema);

module.exports = Appointment;