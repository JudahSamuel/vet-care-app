const mongoose = require('mongoose');

const breedInfoSchema = new mongoose.Schema({
  animalType: {
    type: String,
    enum: ['dog', 'cat', 'cattle'], // The main animal category
    required: true,
    index: true,
  },
  breedName: {
    type: String,
    required: true,
    unique: true,
  },
  // --- This is the new, crucial data ---
  baselineVitals: {
    normalTempMin: { type: Number, required: true },
    normalTempMax: { type: Number, required: true },
    normalRestingHeartRateMin: { type: Number, required: true },
    normalRestingHeartRateMax: { type: Number, required: true },
    normalRestingRespRateMin: { type: Number, required: true }, // Respiratory Rate
    normalRestingRespRateMax: { type: Number, required: true },
  }
});

const BreedInfo = mongoose.model('BreedInfo', breedInfoSchema);

module.exports = BreedInfo;