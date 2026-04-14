const mongoose = require('mongoose');

const petLocationSchema = new mongoose.Schema({
  pet: { 
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Pet',
    required: true,
    index: true, 
  },
  deviceId: { 
    type: String,
    required: true,
    index: true, 
  },
  latitude: {
    type: Number,
    required: true,
  },
  longitude: {
    type: Number,
    required: true,
  },
  timestamp: { 
    type: Date,
    required: true,
    default: Date.now,
    index: true, 
  },
}, {
  timestamps: { createdAt: true, updatedAt: false }
});

const PetLocation = mongoose.model('PetLocation', petLocationSchema);
module.exports = PetLocation;