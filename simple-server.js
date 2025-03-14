// Import the required modules
const express = require('express');
const path = require('path');
const fs = require('fs');

// Create a new Express application
const app = express();

// Set the port to either the environment variable or 5000 as default
const port = process.env.PORT || 5000;

// Middleware to parse JSON bodies
app.use(express.json());

// Middleware to parse URL-encoded bodies
app.use(express.urlencoded({ extended: true }));

// Serve static files from the current directory
app.use(express.static(__dirname));

// Log all requests for debugging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Special route to confirm server is working
app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', time: new Date().toISOString() });
});

// Route to serve the index.html for any route that doesn't match static files
app.get('*', (req, res) => {
  // Check if index.html exists first
  const indexPath = path.join(__dirname, 'index.html');
  
  fs.access(indexPath, fs.constants.F_OK, (err) => {
    if (err) {
      console.error('index.html not found:', err);
      return res.status(404).send('index.html not found');
    }
    
    console.log('Serving index.html from', indexPath);
    res.sendFile(indexPath);
  });
});

// Start the server
const server = app.listen(port, '0.0.0.0', () => {
  console.log(`Fitness App Server running at http://0.0.0.0:${port}`);
  console.log(`Server time: ${new Date().toISOString()}`);
  console.log(`Serving files from: ${__dirname}`);
  
  // Log all files in the current directory for debugging
  fs.readdir(__dirname, (err, files) => {
    if (err) {
      console.error('Error reading directory:', err);
      return;
    }
    console.log('Files in directory:');
    files.forEach(file => {
      if (file === 'index.html') {
        console.log(` - ${file} (MAIN PAGE)`);
      } else {
        console.log(` - ${file}`);
      }
    });
  });
});

// Handle server errors
server.on('error', (err) => {
  console.error('Server error:', err);
  
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${port} is already in use. Trying again in 5 seconds...`);
    setTimeout(() => {
      server.close();
      server.listen(port, '0.0.0.0');
    }, 5000);
  }
});

// Handle process termination gracefully
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
  });
});