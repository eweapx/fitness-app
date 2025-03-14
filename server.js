const express = require('express');
const path = require('path');
const fs = require('fs');

// Create Express app
const app = express();
const PORT = 5000;

// Define paths to static content
const publicDir = path.join(__dirname, 'public');
const flutterBuildDir = path.join(__dirname, 'fitness_tracker/build/web');

// Set up logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// API routes handler
function handleApiRequest(req, res, path) {
  if (path === '/api/health') {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
  } else if (path === '/api/version') {
    res.json({ version: '1.0.0', platform: 'web' });
  } else {
    res.status(404).json({ error: 'API endpoint not found' });
  }
}

// Helper to serve files with proper content types
function serveFile(res, filePath, contentType) {
  try {
    if (fs.existsSync(filePath)) {
      res.setHeader('Content-Type', contentType);
      fs.createReadStream(filePath).pipe(res);
    } else {
      res.status(404).send('File not found');
    }
  } catch (error) {
    console.error(`Error serving file ${filePath}:`, error);
    res.status(500).send('Internal server error');
  }
}

// Serve static files from public directory
app.use(express.static(publicDir));

// If Flutter web build exists, serve from there too
if (fs.existsSync(flutterBuildDir)) {
  console.log(`Serving Flutter web from: ${flutterBuildDir}`);
  app.use(express.static(flutterBuildDir));
}

// Handle API requests
app.use('/api', (req, res) => {
  handleApiRequest(req, res, req.path);
});

// Fallback route - important for SPA
app.get('*', (req, res) => {
  const indexPath = path.join(publicDir, 'index.html');
  const flutterIndexPath = path.join(flutterBuildDir, 'index.html');
  
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else if (fs.existsSync(flutterIndexPath)) {
    res.sendFile(flutterIndexPath);
  } else {
    res.status(404).send('No index.html found');
  }
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${PORT}`);
  
  // Print diagnostics about available files
  ['index.html', 'flutter.js', 'main.dart.js'].forEach(file => {
    const publicPath = path.join(publicDir, file);
    const flutterPath = path.join(flutterBuildDir, file);
    console.log(`${file} in public: ${fs.existsSync(publicPath)}`);
    console.log(`${file} in Flutter build: ${fs.existsSync(flutterPath)}`);
  });
});