const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

// --- Import Routes ---
const authRoutes = require('./routes/auth');
const appointmentRoutes = require('./routes/appointments');
const vetRoutes = require('./routes/vets');
const userRoutes = require('./routes/users');
const petRoutes = require('./routes/pets');
const chatbotRoutes = require('./routes/chatbot');
const healthRoutes = require ('./routes/health');
const analysisRoutes = require('./routes/analysis');
const visionRoutes = require('./routes/vision');
const audioRoutes = require('./routes/audio');
const breedRoutes = require('./routes/breeds');
const locationRoutes = require('./routes/location');
const commandRoutes = require('./routes/commands');

const app = express();
const PORT = 5000;
const HOST = '0.0.0.0'; // <-- ADD THIS: Tell Express to listen on all IP addresses

// --- Middleware ---
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// --- Database Connection ---
const connectionString = process.env.DB_CONNECTION_STRING;
mongoose.connect(connectionString)
  .then(() => console.log('Successfully connected to MongoDB!'))
  .catch((err) => console.error('Connection error', err));

// --- Use Routes ---
app.use('/api/auth', authRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/vets', vetRoutes);
app.use('/api/users', userRoutes);
app.use('/api/pets', petRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/analysis', analysisRoutes);
app.use('/api/vision', visionRoutes);
app.use('/api/audio', audioRoutes);
app.use('/api/breeds', breedRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/commands', commandRoutes);

// --- Start the Server ---
app.listen(PORT, HOST, () => { // <-- MODIFIED LINE
  console.log(`Server is running on http://${HOST}:${PORT}`);
});