const express = require('express');
const router = express.Router();
const BreedInfo = require('../models/BreedInfo');

// @route   GET /api/breeds
// @desc    Get a list of breeds for a specific animal type
// @query   ?type=dog
router.get('/', async (req, res) => {
  try {
    const { type } = req.query;
    if (!type) {
      return res.status(400).json({ msg: 'Animal type query is required' });
    }

    // Find all breeds matching the animalType
    const breeds = await BreedInfo.find({ animalType: type }).select('breedName');
    
    // Return just the list of breed names
    res.json(breeds.map(b => b.breedName));

  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET /api/breeds/info/:breedName
// @desc    Get the detailed baseline vitals for a specific breed
router.get('/info/:breedName', async (req, res) => {
  try {
    const breed = await BreedInfo.findOne({ breedName: req.params.breedName });
    if (!breed) {
      return res.status(404).json({ msg: 'Breed info not found' });
    }
    res.json(breed.baselineVitals);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;