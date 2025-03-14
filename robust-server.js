const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

// Serve static files from the public directory
const publicDir = path.join(__dirname, 'public');
app.use(express.static(publicDir));

// Important: Also serve from the fitness_tracker/build/web directory
// This is where the Flutter build output is located
const flutterBuildDir = path.join(__dirname, 'fitness_tracker/build/web');
if (fs.existsSync(flutterBuildDir)) {
  console.log(`Flutter build directory found: ${flutterBuildDir}`);
  app.use(express.static(flutterBuildDir));
} else {
  console.log(`Flutter build directory not found: ${flutterBuildDir}`);
}

// Logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('Server is healthy!');
});

// SPA route handling (important for Flutter web apps)
app.get('*', (req, res) => {
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

// Fixed port approach - will try to start on port 5000
function startServer(port) {
  console.log(`Attempting to start server on port ${port}...`);
  
  app.listen(port, '0.0.0.0', () => {
    console.log(`\n====================================`);
    console.log(`✅ SERVER STARTED SUCCESSFULLY`);
    console.log(`✅ PORT: ${port}`);
    console.log(`✅ Access URL: http://0.0.0.0:${port}`);
    console.log(`====================================\n`);
    
    // Print file diagnostics
    console.log('File Diagnostics:');
    const requiredFiles = ['index.html', 'flutter.js', 'main.dart.js'];
    requiredFiles.forEach(file => {
      const filePath = path.join(publicDir, file);
      const flutterFilePath = path.join(flutterBuildDir, file);
      console.log(`${file} in public: ${fs.existsSync(filePath)}`);
      console.log(`${file} in Flutter build: ${fs.existsSync(flutterFilePath)}`);
    });
    
    // Keep-alive heartbeat
    setInterval(() => {
      console.log(`Server health: Running on port ${port} at ${new Date().toISOString()}`);
    }, 10000);
  }).on('error', (err) => {
    console.error(`Failed to start server on port ${port}: ${err.message}`);
  });
}

// Start the server on port 5000
startServer(5000);