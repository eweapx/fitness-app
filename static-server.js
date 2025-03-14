const express = require('express');
const path = require('path');
const fs = require('fs');

// Function to create and start server
function createServer(initialPort) {
  const app = express();
  const publicDir = path.join(__dirname, 'public');
  const flutterBuildDir = path.join(__dirname, 'fitness_tracker/build/web');

  console.log(`Starting static server on port ${initialPort}`);
  console.log(`Public directory exists: ${fs.existsSync(publicDir)}`);
  console.log(`Flutter build directory exists: ${fs.existsSync(flutterBuildDir)}`);

  // Serve static files
  app.use(express.static(publicDir));
  app.use(express.static(flutterBuildDir));

  // Request logging
  app.use((req, res, next) => {
    console.log(`Request: ${req.method} ${req.url}`);
    next();
  });

  // Health check
  app.get('/health', (req, res) => {
    res.status(200).send('OK');
  });

  // SPA fallback
  app.get('*', (req, res) => {
    const indexPath = path.join(publicDir, 'index.html');
    
    if (fs.existsSync(indexPath)) {
      res.sendFile(indexPath);
    } else {
      res.status(404).send('Not Found');
    }
  });

  // Start the server on the specified port
  function startServer() {
    return app.listen(initialPort, '0.0.0.0', () => {
      console.log(`Static server running at http://0.0.0.0:${initialPort}`);
      
      // Print file diagnostics
      console.log('File Diagnostics:');
      const requiredFiles = ['index.html', 'flutter.js', 'main.dart.js'];
      requiredFiles.forEach(file => {
        const filePath = path.join(publicDir, file);
        console.log(`${file} exists: ${fs.existsSync(filePath)}`);
      });
    });
  }

  return startServer();
}

// Start the server on port 5000
createServer(5000);