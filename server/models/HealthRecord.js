const mongoose = require('mongoose');

const healthRecordSchema = new mongoose.Schema({
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
  timestamp: {
    type: Date,
    required: true,
    index: true,
  },
  heartRate: {
    type: Number,
  },
  respiratoryRate: {
    type: Number,
  },
  temperature: {
    type: Number,
  },
  activityLevel: {
    type: String,
  },
  caloriesBurned: {
    type: Number,
  },
}, {
  timestamps: { createdAt: true, updatedAt: false }
});

healthRecordSchema.index({ createdAt: 1 }, { expireAfterSeconds: 6 * 30 * 24 * 60 * 60 });

const HealthRecord = mongoose.model('HealthRecord', healthRecordSchema);

module.exports = HealthRecord;