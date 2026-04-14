const express = require('express');
const router = express.Router();
const DeviceCommand = require('../models/DeviceCommand');
const Pet = require('../models/Pet');

// @route   POST /api/commands/pet/:petId/find
// @desc    The Flutter App calls this to create a new "find" command
router.post('/pet/:petId/find', async (req, res) => {
  try {
    const pet = await Pet.findById(req.params.petId);
    if (!pet) {
      return res.status(404).json({ msg: 'Pet not found' });
    }

    // Create a new command in the "mailbox"
    const newCommand = new DeviceCommand({
      pet: req.params.petId,
      command: 'FIND_PET', // The command the ESP32 will look for
      isCompleted: false,  // Mark it as "not yet picked up"
    });

    await newCommand.save();
    res.status(201).json({ msg: 'Find command issued!', command: newCommand });

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET /api/commands/pet/:petId/check
// @desc    The ESP32 calls this to check for a new command
router.get('/pet/:petId/check', async (req, res) => {
  try {
    const petId = req.params.petId;

    // Find the newest, uncompleted command for this pet
    const pendingCommand = await DeviceCommand.findOne({
      pet: petId,
      isCompleted: false
    }).sort({ createdAt: -1 });

    if (pendingCommand) {
      // We found a command! Mark it as "completed"
      pendingCommand.isCompleted = true;
      await pendingCommand.save();
      
      // Send the command to the ESP32
      res.json({ command: pendingCommand.command }); // e.g., { "command": "FIND_PET" }
    } else {
      // No command found
      res.json({ command: null });
    }
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;