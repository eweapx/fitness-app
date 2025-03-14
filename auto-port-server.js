const express = require('express');
const path = require('path');
const fs = require('fs');
const http = require('http');
const app = express();

// Serve static files from the public directory
const publicDir = path.join(__dirname, 'public');
app.use(express.static(publicDir));

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
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Create a server but don't start it yet
const server = http.createServer(app);

// Print diagnostic information
console.log('Fitness Tracker Flutter Web Server');
console.log(`Public directory: ${publicDir}`);
console.log(`Directory exists: ${fs.existsSync(publicDir)}`);

// Check required files
const requiredFiles = ['index.html', 'flutter.js', 'main.dart.js'];
requiredFiles.forEach(file => {
  const filePath = path.join(publicDir, file);
  console.log(`File ${file} exists: ${fs.existsSync(filePath)}`);
});

// Function to find an available port
function startServer(preferredPorts = [8080, 3000, 5000, 5001, 5002]) {
  // Try ports in order
  tryPort(preferredPorts, 0);
}

function tryPort(ports, index) {
  if (index >= ports.length) {
    console.log('No preferred ports available. Letting the system choose a port...');
    server.listen(0, '0.0.0.0', onServerStart);
    return;
  }

  const port = ports[index];
  
  server.once('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.log(`Port ${port} is already in use. Trying next port...`);
      tryPort(ports, index + 1);
    } else {
      console.error(`Error starting server: ${err.message}`);
    }
  });
  
  server.listen(port, '0.0.0.0', onServerStart);
}

function onServerStart() {
  const address = server.address();
  console.log(`\n====================================`);
  console.log(`✅ SERVER STARTED SUCCESSFULLY`);
  console.log(`✅ PORT: ${address.port}`);
  console.log(`✅ Access URL: http://0.0.0.0:${address.port}`);
  console.log(`====================================\n`);
  
  // Remove the error handler after successful start
  server.removeAllListeners('error');
  
  // Add a new error handler for runtime errors
  server.on('error', (err) => {
    console.error(`Runtime server error: ${err.message}`);
  });
  
  // Keep the server alive indication
  const intervalId = setInterval(() => {
    console.log(`Server health: Running on port ${address.port} at ${new Date().toISOString()}`);
  }, 10000);
  
  // Handle server close to clear interval
  server.on('close', () => {
    clearInterval(intervalId);
    console.log('Server shut down');
  });
}

// Start the server
startServer();