const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();
const PORT = 5000; // Try port 5000 first

// Function to find an available port
function startServerWithAvailablePort(initialPort) {
  const server = app.listen(initialPort, '0.0.0.0', () => {
    console.log(`Flutter Web App server running on http://0.0.0.0:${initialPort}`);
    
    // Log a clear message every 5 seconds to indicate the server is running
    setInterval(() => {
      console.log(`[HEALTH CHECK] Flutter Web App still running on port ${initialPort} - ${new Date().toISOString()}`);
    }, 5000);
    
    // Log a message to ensure port is visible to port detection
    console.log(`PORT=${initialPort} EXPLICITLY LISTENING`);
  }).on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`Port ${initialPort} is already in use. Trying another port.`);
      startServerWithAvailablePort(initialPort + 1);
    } else {
      console.error(`Error starting server: ${err.message}`);
      process.exit(1);
    }
  });
}

// Console logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
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

// Custom health check route
app.get('/health', (req, res) => {
  res.status(200).send('Flutter Web App Server is healthy');
});

// For all other routes, serve index.html (SPA routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`Error: ${err.message}`);
  res.status(500).send('Something went wrong!');
});

// Start the server with the port finding function
startServerWithAvailablePort(PORT);