const express = require('express');
const router = express.Router();
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
require('dotenv').config();

const AGORA_APP_ID = '1ac161c863c94d1cb8909601371de9f7'; // <-- Replace with your App ID
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE;

// The token expires in 3600 seconds (1 hour)
const expirationTimeInSeconds = 3600;

// @route   GET /api/video/token
// @desc    Generates a secure Agora token for a user/vet to join a channel
router.get('/token', (req, res) => {
    try {
        // Channel and UID are required parameters from the Flutter app
        const { channelName, uid } = req.query;

        if (!channelName || !uid) {
            return res.status(400).json({ msg: 'Channel name and UID are required.' });
        }

        const currentTimestamp = Math.floor(Date.now() / 1000);
        const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

        // Generate the token
        const token = RtcTokenBuilder.buildTokenWithUid(
            AGORA_APP_ID,
            AGORA_APP_CERTIFICATE,
            channelName,
            uid,
            RtcRole.PUBLISHER, // User will publish audio/video
            privilegeExpiredTs
        );

        res.json({ token });

    } catch (err) {
        console.error("Agora Token Generation Error:", err.message);
        res.status(500).send('Server error during token generation.');
    }
});

module.exports = router;