const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(express.static(path.join(__dirname)));

// Serve index.html as the main page
app.get('/', function(req, res) {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Simple Fitness app running at http://0.0.0.0:${port}`);
});