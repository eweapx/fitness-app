const express = require('express');
const path = require('path');
const fs = require('fs');
const net = require('net');
const app = express();

// Console logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Serve static files from the public directory
const publicDir = path.join(__dirname, 'public');
app.use(express.static(publicDir));

// Health check route
app.get('/health', (req, res) => {
  res.status(200).send('Flutter Web App Server is healthy');
});

// For all other routes, serve index.html (SPA routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Function to check if a port is in use
function isPortInUse(port) {
  return new Promise((resolve) => {
    const server = net.createServer()
      .once('error', () => resolve(true))
      .once('listening', () => {
        server.close();
        resolve(false);
      })
      .listen(port, '0.0.0.0');
  });
}

// Function to create the server with a guaranteed free port
async function createServer() {
  // Try port 5001 specifically for workflow compatibility
  const preferredPorts = [5001, 5000, 3000, 8080, 4000];
  
  for (const port of preferredPorts) {
    const isInUse = await isPortInUse(port);
    
    if (!isInUse) {
      console.log(`Starting server on available port: ${port}`);
      
      // Start the server on the available port
      app.listen(port, '0.0.0.0', () => {
        console.log(`Flutter Web App server running on http://0.0.0.0:${port}`);
      });
      
      return;
    } else {
      console.log(`Port ${port} is already in use, trying next...`);
    }
  }
  
  // If all preferred ports are in use, use a random port
  console.log(`All preferred ports are in use, using a random port...`);
  app.listen(0, '0.0.0.0', () => {
    const addressInfo = app.address();
    console.log(`Flutter Web App server running on http://0.0.0.0:${addressInfo.port}`);
  });
}

// Check if required files exist and log their status
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

// Start the server
createServer();