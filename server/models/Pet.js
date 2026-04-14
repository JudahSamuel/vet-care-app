const mongoose = require('mongoose');

const medicalRecordSchema = new mongoose.Schema({
  date: { type: Date, default: Date.now },
  description: { type: String, required: true },
  notes: { type: String }
});

const petSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  breed: {
    type: String,
    required: true,
  },
  age: {
    type: Number,
    required: true,
  },
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  gpsDeviceId: { // Field to store the unique ID from the physical GPS tracker
    type: String,
    trim: true,
    index: true, 
    sparse: true 
  },
  healthDeviceId: { 
    type: String,
    trim: true,
    index: true,
    sparse: true
  },
  vaccinations: [{
    vaccineName: String,
    dateAdministered: Date,
    nextDueDate: Date,
  }],
  allergies: [{
    type: String,
    description: String,
    severity: String,
  }],
  pastConditions: [medicalRecordSchema],
  medicalNotes: { type: String },
});

const Pet = mongoose.model('Pet', petSchema);
module.exports = Pet;