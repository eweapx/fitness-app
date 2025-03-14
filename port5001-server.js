const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

// Serve static files from the public directory
const publicDir = path.join(__dirname, 'public');
app.use(express.static(publicDir));

// Important: Also serve from the fitness_tracker/build/web directory
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

// SPA route handling
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

// Using a port that we know is free in Replit
const PORT = 5001;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${PORT}`);
  
  // Print file diagnostics
  console.log('File Diagnostics:');
  const requiredFiles = ['index.html', 'flutter.js', 'main.dart.js'];
  requiredFiles.forEach(file => {
    const filePath = path.join(publicDir, file);
    const flutterFilePath = path.join(flutterBuildDir, file);
    console.log(`${file} in public: ${fs.existsSync(filePath)}`);
    console.log(`${file} in Flutter build: ${fs.existsSync(flutterFilePath)}`);
  });
});