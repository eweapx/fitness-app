const express = require('express');
const path = require('path');
const fs = require('fs');

// Create Express app with detailed error handling
try {
  const app = express();
  // Important: Replit requires port 5000
  const PORT = 5000;

  console.log("Starting server setup...");
  console.log(`Current directory: ${__dirname}`);
  
  // Check if public directory exists
  const publicDir = path.join(__dirname, 'public');
  if (fs.existsSync(publicDir)) {
    console.log(`Public directory exists at: ${publicDir}`);
  } else {
    console.error(`Error: Public directory does not exist at: ${publicDir}`);
  }

  // Set up error handling middleware
  app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
  });

  // Add error handling middleware
  app.use((err, req, res, next) => {
    console.error(`Server error: ${err.message}`);
    res.status(500).send('Internal Server Error');
  });

  // Serve static files from public directory with error handling
  try {
    app.use(express.static(publicDir));
    console.log("Express static middleware set up for public directory");
  } catch (err) {
    console.error(`Error setting up static middleware: ${err.message}`);
  }

  // Basic route to test server
  app.get('/api/hello', (req, res) => {
    res.json({ message: 'Hello, World!' });
  });

  // Route for fitness tracker
  app.get('/fitness', (req, res) => {
    try {
      const fitnessPath = path.join(publicDir, 'fitness.html');
      if (fs.existsSync(fitnessPath)) {
        console.log(`Serving fitness.html from: ${fitnessPath}`);
        res.sendFile(fitnessPath);
      } else {
        console.error(`Error: fitness.html not found at: ${fitnessPath}`);
        res.status(404).send('Fitness page not found');
      }
    } catch (err) {
      console.error(`Error serving fitness page: ${err.message}`);
      res.status(500).send('Error serving fitness page');
    }
  });

  // Default route for index page
  app.get('/', (req, res) => {
    try {
      const indexPath = path.join(publicDir, 'index.html');
      if (fs.existsSync(indexPath)) {
        console.log(`Serving index.html from: ${indexPath}`);
        res.sendFile(indexPath);
      } else {
        console.error(`Error: index.html not found at: ${indexPath}`);
        res.status(404).send('Index page not found');
      }
    } catch (err) {
      console.error(`Error serving index page: ${err.message}`);
      res.status(500).send('Error serving index page');
    }
  });

  // Start server with detailed error handling
  try {
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running at http://0.0.0.0:${PORT}`);
      console.log(`Server ready - listening on port ${PORT}`);
    });

    // Handle server errors
    server.on('error', (error) => {
      console.error(`Server error: ${error.message}`);
      if (error.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} is already in use. Try a different port.`);
      }
    });
  } catch (err) {
    console.error(`Failed to start server: ${err.message}`);
  }
} catch (err) {
  console.error(`Fatal error: ${err.message}`);
}