const express = require('express');
const path = require('path');
const fs = require('fs');
const http = require('http');
const app = express();

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

// Function to find an available port and start the server
function startServer(preferredPort = 5000) {
  const server = http.createServer(app);
  
  server.on('error', (e) => {
    if (e.code === 'EADDRINUSE') {
      console.log(`Port ${preferredPort} is in use, trying ${preferredPort + 1}...`);
      startServer(preferredPort + 1);
    } else {
      console.error(`Server error: ${e.message}`);
    }
  });

  server.listen(preferredPort, '0.0.0.0', () => {
    const address = server.address();
    console.log(`Flutter Web App server running on http://0.0.0.0:${address.port}`);
    console.log(`PORT=${address.port}`);
    
    // Set up a ping every 5 seconds to keep the server detectable
    setInterval(() => {
      console.log(`SERVER HEALTH: Still running on port ${address.port} at ${new Date().toISOString()}`);
    }, 5000);
  });
}

// Try to start on port 5001 directly
startServer(5001);