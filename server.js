const express = require('express');
const path = require('path');
const fs = require('fs');

// Create Express app
const app = express();
const PORT = process.env.PORT || 5002; // Using port 5002 since 5000 and 5001 are occupied

// Define paths to static content
const publicDir = path.join(__dirname, 'public');
const flutterBuildDir = path.join(__dirname, 'build/web');

// Set up logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Serve static files from public directory
app.use(express.static(publicDir));

// If Flutter web build exists, serve from there too
if (fs.existsSync(flutterBuildDir)) {
  console.log(`Serving Flutter web from: ${flutterBuildDir}`);
  app.use(express.static(flutterBuildDir));
}

// API routes
app.get('/api/health', (req, res) => {
  const uptime = process.uptime();
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: uptime,
    version: '1.0.0'
  });
});

app.get('/api/version', (req, res) => {
  res.json({ version: '1.0.0', platform: 'web' });
});

// Route for our fitness tracker app
app.get('/fitness', (req, res) => {
  res.sendFile(path.join(publicDir, 'fitness.html'));
});

// Fallback route for SPA, but only if the path doesn't already exist as a file
app.get('*', (req, res) => {
  // First check if this is a test file request
  const reqPath = req.path.startsWith('/') ? req.path.substring(1) : req.path;
  const filePath = path.join(__dirname, reqPath);
  
  // Check if the file exists (for test purposes)
  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    return res.sendFile(filePath);
  }
  
  // If file doesn't exist and it's not an API route, check for SPA files
  const indexPath = path.join(publicDir, 'index.html');
  const flutterIndexPath = path.join(flutterBuildDir, 'index.html');

  // Check if it's a non-test or an API endpoint
  if (req.path.startsWith('/api/') || req.path === '/test-static.txt') {
    return res.status(404).send('Not Found');
  }

  // Serve the appropriate SPA index
  if (fs.existsSync(flutterIndexPath)) {
    res.sendFile(flutterIndexPath);
  } else if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send('No index.html found');
  }
});

// Only start the server if this file is run directly
if (require.main === module) {
  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running at http://0.0.0.0:${PORT}`);
    // Signal that the server is ready to accept connections
    console.log(`Server ready - listening on port ${PORT}`);
  });

  // Handle server errors
  server.on('error', (error) => {
    console.error(`Server error: ${error.message}`);
    if (error.code === 'EADDRINUSE') {
      console.error(`Port ${PORT} is already in use. Try a different port.`);
    }
    process.exit(1);
  });
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    console.log('Shutting down server gracefully...');
    server.close(() => {
      console.log('Server has been gracefully shutdown');
      process.exit(0);
    });
  });
}

// Export for testing
module.exports = app;