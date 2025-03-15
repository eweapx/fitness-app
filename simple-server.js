const express = require('express');
const path = require('path');
const fs = require('fs');

// Create Express app
const app = express();
const PORT = 8080; // Use port 8080 explicitly

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
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/version', (req, res) => {
  res.json({ version: '1.0.0', platform: 'web' });
});

// Serve our basic-index.html test page
app.get('/basic', (req, res) => {
  const basicIndexPath = path.join(__dirname, 'basic-index.html');
  if (fs.existsSync(basicIndexPath)) {
    res.sendFile(basicIndexPath);
  } else {
    res.status(404).send('basic-index.html not found');
  }
});

// Fallback route for SPA
app.get('*', (req, res) => {
  const indexPath = path.join(publicDir, 'index.html');
  const flutterIndexPath = path.join(flutterBuildDir, 'index.html');
  const basicIndexPath = path.join(__dirname, 'basic-index.html');

  if (fs.existsSync(flutterIndexPath)) {
    res.sendFile(flutterIndexPath);
  } else if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else if (fs.existsSync(basicIndexPath)) {
    // Use our basic index as a fallback
    res.sendFile(basicIndexPath);
  } else {
    res.status(404).send('No index.html found');
  }
});

// Start the server
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${PORT}`);
  console.log(`Server ready to accept connections on port ${PORT}`);
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