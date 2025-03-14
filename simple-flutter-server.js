const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

// Immediately log that we're starting
console.log('STARTING FLUTTER WEB SERVER');

// Define directories
const publicDir = path.join(__dirname, 'public');
const flutterBuildDir = path.join(__dirname, 'fitness_tracker/build/web');

// Serve static files
console.log(`Public directory exists: ${fs.existsSync(publicDir)}`);
app.use(express.static(publicDir));

console.log(`Flutter build directory exists: ${fs.existsSync(flutterBuildDir)}`);
app.use(express.static(flutterBuildDir));

// Middleware for logging
app.use((req, res, next) => {
  console.log(`Request: ${req.method} ${req.url}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('Server is healthy!');
});

// SPA fallback
app.get('*', (req, res) => {
  // Try to serve index.html from either directory
  const indexPath = path.join(publicDir, 'index.html');
  const flutterIndexPath = path.join(flutterBuildDir, 'index.html');
  
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else if (fs.existsSync(flutterIndexPath)) {
    res.sendFile(flutterIndexPath);
  } else {
    res.status(404).send('No index.html found');
  }
});

// Fixed port - use port 5000 which is what Replit expects
function startServer(preferredPort = 5000) {
  // Start server immediately on the preferred port
  app.listen(preferredPort, '0.0.0.0', () => {
    console.log(`Flutter Web Server running at http://0.0.0.0:${preferredPort}`);
    
    // Check required files
    console.log('File availability:');
    ['index.html', 'flutter.js', 'main.dart.js'].forEach(file => {
      console.log(`${file} in public: ${fs.existsSync(path.join(publicDir, file))}`);
      console.log(`${file} in Flutter build: ${fs.existsSync(path.join(flutterBuildDir, file))}`);
    });
  }).on('error', (err) => {
    console.error(`Server failed to start on port ${preferredPort}:`, err.message);
  });
}

// Start the server on port 5000
startServer();