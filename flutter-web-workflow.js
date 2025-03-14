const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

// The port we want to use
const PORT = 5000;

// Check public directory
const publicDir = path.join(__dirname, 'public');
console.log(`Checking public directory at: ${publicDir}`);
console.log(`Directory exists: ${fs.existsSync(publicDir)}`);

// Check required files
if (fs.existsSync(publicDir)) {
  const requiredFiles = ['index.html', 'flutter.js', 'main.dart.js'];
  requiredFiles.forEach(file => {
    const filePath = path.join(publicDir, file);
    console.log(`File ${file} exists: ${fs.existsSync(filePath)}`);
  });
}

// Logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Serve static files
app.use(express.static(publicDir));

// Health check
app.get('/health', (req, res) => {
  res.status(200).send('Server is healthy!');
});

// SPA route handling
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Create server with error handling
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Flutter Web App server running on http://0.0.0.0:${PORT}`);
})
.on('error', (e) => {
  if (e.code === 'EADDRINUSE') {
    console.log(`Port ${PORT} is already in use. Starting on port 5001 instead.`);
    
    // Try alternate port if main port is in use
    const server2 = app.listen(5001, '0.0.0.0', () => {
      console.log(`Flutter Web App server running on http://0.0.0.0:5001`);
    })
    .on('error', (err) => {
      console.error(`Could not start server on port 5001: ${err.message}`);
    });
  } else {
    console.error(`Server error: ${e.message}`);
  }
});