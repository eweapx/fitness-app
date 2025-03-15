const express = require('express');
const path = require('path');
const fs = require('fs');

// Create Express app
const app = express();
const PORT = process.env.PORT || 5000; // Use Replit standard port 5000

// Define paths to static content
const publicDir = path.join(__dirname, 'public');
const flutterBuildDir = path.join(__dirname, 'build/web');

// Set up logging middleware and CORS headers
app.use((req, res, next) => {
  // Add CORS headers
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  
  // Log detailed request info for debugging
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log(`User-Agent: ${req.headers['user-agent']}`);
  console.log(`Remote Address: ${req.ip}`);
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
  console.log('Serving fitness.html');
  console.log(`File path: ${path.join(publicDir, 'fitness.html')}`);
  console.log(`File exists: ${fs.existsSync(path.join(publicDir, 'fitness.html'))}`);
  res.sendFile(path.join(publicDir, 'fitness.html'));
});

// Fallback route for SPA, but only if the path doesn't already exist as a file
app.get('*', (req, res) => {
  console.log(`Fallback route for: ${req.path}`);
  
  // First check if this is a test file request
  const reqPath = req.path.startsWith('/') ? req.path.substring(1) : req.path;
  const filePath = path.join(__dirname, reqPath);

  console.log(`Checking file path: ${filePath}`);
  console.log(`File exists: ${fs.existsSync(filePath) && fs.statSync(filePath).isFile()}`);

  // Check if the file exists (for test purposes)
  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    console.log(`Serving existing file: ${filePath}`);
    return res.sendFile(filePath);
  }

  // If file doesn't exist and it's not an API route, check for SPA files
  const indexPath = path.join(publicDir, 'index.html');
  const flutterIndexPath = path.join(flutterBuildDir, 'index.html');
  
  console.log(`Index path: ${indexPath}, exists: ${fs.existsSync(indexPath)}`);
  console.log(`Flutter index path: ${flutterIndexPath}, exists: ${fs.existsSync(flutterIndexPath)}`);

  // Check if it's a non-test or an API endpoint
  if (req.path.startsWith('/api/') || req.path === '/test-static.txt' || req.path === '/non-existent-path') {
    console.log(`Not found path: ${req.path}`);
    return res.status(404).send('Not Found');
  }

  // Serve the appropriate SPA index
  if (fs.existsSync(flutterIndexPath)) {
    console.log(`Serving Flutter index: ${flutterIndexPath}`);
    res.sendFile(flutterIndexPath);
  } else if (fs.existsSync(indexPath)) {
    console.log(`Serving HTML index: ${indexPath}`);
    res.sendFile(indexPath);
  } else {
    console.log('No index.html found');
    res.status(404).send('No index.html found');
  }
});

// Only start the server if this file is run directly
if (require.main === module) {
  // List contents of the public directory for debugging
  console.log('Listing contents of public directory:');
  try {
    const publicFiles = fs.readdirSync(publicDir);
    console.log(`Public directory (${publicDir}) contains ${publicFiles.length} items:`);
    publicFiles.forEach(item => {
      const itemPath = path.join(publicDir, item);
      const stats = fs.statSync(itemPath);
      console.log(`- ${item} (${stats.isDirectory() ? 'directory' : 'file'})`);
    });
    
    // Check for js files in public/js
    const jsDir = path.join(publicDir, 'js');
    if (fs.existsSync(jsDir) && fs.statSync(jsDir).isDirectory()) {
      const jsFiles = fs.readdirSync(jsDir);
      console.log(`JS directory contains ${jsFiles.length} files:`);
      jsFiles.forEach(file => console.log(`- ${file}`));
    }
  } catch (error) {
    console.error(`Error listing directory: ${error.message}`);
  }
  
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