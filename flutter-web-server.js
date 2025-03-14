const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();
const PORT = 5000;

// Console logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Check if required files exist and log their status
const publicDir = path.join(__dirname, 'public');
console.log(`Checking public directory at: ${publicDir}`);
console.log(`Directory exists: ${fs.existsSync(publicDir)}`);

if (fs.existsSync(publicDir)) {
  const filesCheck = [
    'index.html',
    'flutter.js',
    'main.dart.js'
  ];
  
  filesCheck.forEach(file => {
    const filePath = path.join(publicDir, file);
    console.log(`File ${file} exists: ${fs.existsSync(filePath)}`);
  });
}

// Serve static files from the public directory
app.use(express.static(publicDir));

// Health check route
app.get('/health', (req, res) => {
  res.status(200).send('Flutter Web App Server is healthy');
});

// For all other routes, serve index.html (SPA routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Flutter Web App server running on http://0.0.0.0:${PORT}`);
});