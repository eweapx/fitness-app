const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

// Diagnostic information
console.log('Starting Fitness Tracker Flutter Web Server');

// Define directories to check for serving
const publicDir = path.join(__dirname, 'public');
const flutterBuildDir = path.join(__dirname, 'fitness_tracker/build/web');

// Check if directories exist
console.log(`Public directory exists: ${fs.existsSync(publicDir)}`);
console.log(`Flutter build directory exists: ${fs.existsSync(flutterBuildDir)}`);

// Serve static files from multiple directories
if (fs.existsSync(publicDir)) {
  console.log('Serving from public directory');
  app.use(express.static(publicDir));
}

if (fs.existsSync(flutterBuildDir)) {
  console.log('Serving from Flutter build directory');
  app.use(express.static(flutterBuildDir));
}

// Middleware for logging
app.use((req, res, next) => {
  console.log(`Request: ${req.method} ${req.url}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('Server is healthy!');
});

// SPA fallback for Flutter routing
app.get('*', (req, res) => {
  // Try to serve index.html from either directory
  let indexPath = path.join(publicDir, 'index.html');
  let flutterIndexPath = path.join(flutterBuildDir, 'index.html');
  
  if (fs.existsSync(indexPath)) {
    console.log(`Serving index.html from public directory for: ${req.url}`);
    res.sendFile(indexPath);
  } else if (fs.existsSync(flutterIndexPath)) {
    console.log(`Serving index.html from Flutter build directory for: ${req.url}`);
    res.sendFile(flutterIndexPath);
  } else {
    console.log(`No index.html found for: ${req.url}`);
    res.status(404).send('No index.html found in any directory');
  }
});

// Function to start server with port conflict resolution
function startServerWithAvailablePort(initialPort) {
  let port = initialPort;
  const maxPortAttempts = 10;
  
  function attemptToStart(currentPort, attempts) {
    if (attempts >= maxPortAttempts) {
      console.error(`Failed to find an available port after ${attempts} attempts.`);
      process.exit(1);
      return;
    }
    
    const server = app.listen(currentPort, '0.0.0.0', () => {
      console.log(`\n====================================`);
      console.log(`✅ SERVER STARTED SUCCESSFULLY`);
      console.log(`✅ PORT: ${currentPort}`);
      console.log(`✅ Access URL: http://0.0.0.0:${currentPort}`);
      console.log(`====================================\n`);
      
      // Print file diagnostics
      console.log('File Diagnostics:');
      ['index.html', 'flutter.js', 'main.dart.js'].forEach(file => {
        const publicFilePath = path.join(publicDir, file);
        const flutterFilePath = path.join(flutterBuildDir, file);
        console.log(`${file} in public: ${fs.existsSync(publicFilePath)}`);
        console.log(`${file} in Flutter build: ${fs.existsSync(flutterFilePath)}`);
      });
    }).on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.log(`Port ${currentPort} is in use, trying port ${currentPort + 1}...`);
        attemptToStart(currentPort + 1, attempts + 1);
      } else {
        console.error(`Error starting server: ${err.message}`);
        process.exit(1);
      }
    });
  }
  
  // Start the first attempt
  attemptToStart(port, 0);
}

// Start the server at port 5002 (avoiding 5000 which might be in use)
startServerWithAvailablePort(5002);