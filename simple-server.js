const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 5000;

// Middleware to handle JSON and URL-encoded data
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the current directory
app.use(express.static(path.join(__dirname)));

// Middleware for basic error logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Serve index.html as the main page
app.get('/', function(req, res) {
  console.log('Serving index.html');
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Catch-all handler for 404 errors
app.use((req, res) => {
  console.log(`404 - Not Found: ${req.path}`);
  res.status(404).send('404 - Not Found');
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`Error: ${err.message}`);
  res.status(500).send('Internal Server Error');
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Simple Fitness app running at http://0.0.0.0:${port}`);
  console.log(`Serving files from ${__dirname}`);
});