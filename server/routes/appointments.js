const express = require('express');
const router = express.Router();
const Appointment = require('../models/Appointment');

// @route   POST /api/appointments/book
// @desc    Create a new appointment
router.post('/book', async (req, res) => {
  try {
    // Expect selectedDate instead of generating it on the server
    const { selectedDate, reason, ownerId, vetId } = req.body;

    if (!selectedDate || !reason || !ownerId || !vetId) {
      return res.status(400).json({ msg: 'Please provide all required fields (date, reason, ownerId, vetId).' });
    }

    // Basic validation to ensure selectedDate is a valid date string
    const appointmentDate = new Date(selectedDate);
    if (isNaN(appointmentDate.getTime())) {
         return res.status(400).json({ msg: 'Invalid date format provided.' });
    }


    const newAppointment = new Appointment({
      date: appointmentDate, // Use the date sent from the app
      reason,
      owner: ownerId,
      vet: vetId,
      status: 'Scheduled', // Ensure status is set
    });

    await newAppointment.save();
    res.status(201).json({ msg: 'Appointment booked successfully!', appointment: newAppointment });

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// @route   PUT /api/appointments/:id/status
// @desc    Update the status of an appointment
router.put('/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const appointmentId = req.params.id;
    const allowedStatuses = ['Completed', 'Cancelled'];
    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({ msg: 'Invalid status provided.' });
    }

    const updatedAppointment = await Appointment.findByIdAndUpdate(
      appointmentId,
      { status: status },
      { new: true }
    );

    if (!updatedAppointment) {
      return res.status(404).json({ msg: 'Appointment not found.' });
    }
    res.json({ msg: 'Appointment status updated!', appointment: updatedAppointment });

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;