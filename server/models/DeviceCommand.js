const mongoose = require('mongoose');

const deviceCommandSchema = new mongoose.Schema({
  pet: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Pet',
    required: true,
    index: true,
  },
  command: {
    type: String, // e.g., 'FIND_PET', 'ACTIVATE_BUZZER'
    required: true,
  },
  isCompleted: {
    type: Boolean,
    default: false,
    index: true,
  }
}, { timestamps: true }); // Automatically adds createdAt

// Automatically delete commands after 1 hour
deviceCommandSchema.index({ createdAt: 1 }, { expireAfterSeconds: 3600 });

const DeviceCommand = mongoose.model('DeviceCommand', deviceCommandSchema);

module.exports = DeviceCommand;