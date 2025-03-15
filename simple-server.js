const express = require('express');
const app = express();
const PORT = 5000;

// Serve static files from public directory
app.use(express.static('public'));

// Simple test endpoint
app.get('/hello', (req, res) => {
  res.send('Hello, World!');
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Simple server running at http://0.0.0.0:${PORT}`);
});