const express = require('express');
const path = require('path');
const app = express();
const port = 5000;

// Serve static files from the root directory
app.use(express.static(path.join(__dirname)));

// Serve index.html as the main page
app.get('/', function(req, res) {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Fuel Fitness app running at http://0.0.0.0:${port}`);
});