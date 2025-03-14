const express = require('express');
const path = require('path');
const fs = require('fs');

// Create the Express app
const app = express();
const PORT = 5001;

// Logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Public directory setup
const publicDir = path.join(__dirname, 'public');
console.log(`Using public directory at: ${publicDir}`);

// Verify files exist
const requiredFiles = ['index.html', 'flutter.js', 'main.dart.js'];
let allFilesExist = true;

requiredFiles.forEach(file => {
  const filePath = path.join(publicDir, file);
  const exists = fs.existsSync(filePath);
  console.log(`File ${file} exists: ${exists}`);
  if (!exists) allFilesExist = false;
});

if (!allFilesExist) {
  console.warn('WARNING: Some required files are missing!');
}

// Serve static files
app.use(express.static(publicDir));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('Server is healthy and running on port 5001');
});

// Catch-all route for SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Flutter Web Server running on port ${PORT}`);
  console.log(`✓ Access at http://0.0.0.0:${PORT}`);
  
  // Output a message every 5 seconds to indicate the server is still running
  setInterval(() => {
    console.log(`Server health check: Still running on port ${PORT} at ${new Date().toISOString()}`);
  }, 5000);
});