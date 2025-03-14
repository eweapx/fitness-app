// Basic HTTP server with minimal dependencies and maximum resilience
const http = require('http');
const fs = require('fs');
const path = require('path');

// Common MIME types for file extensions
const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

// Create simple HTTP server with synchronous file serving
const server = http.createServer((req, res) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  
  // Special API endpoint for health check
  if (req.url === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', time: new Date().toISOString() }));
    return;
  }
  
  // Set default file path to index.html if root is requested
  let filePath = req.url === '/' ? './index.html' : '.' + req.url;
  
  try {
    // Check if file exists
    if (fs.existsSync(filePath)) {
      // Get file extension and content type
      const extname = path.extname(filePath);
      const contentType = mimeTypes[extname] || 'application/octet-stream';
      
      // Read and serve file synchronously to avoid any async issues
      const content = fs.readFileSync(filePath);
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    } else {
      // For single-page apps, serve index.html for any non-file path
      if (!path.extname(req.url) && req.url !== '/') {
        const content = fs.readFileSync('./index.html');
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(content);
      } else {
        // 404 for files that don't exist
        res.writeHead(404);
        res.end('404 Not Found');
      }
    }
  } catch (error) {
    console.error('Error serving file:', error);
    res.writeHead(500);
    res.end('Internal Server Error');
  }
});

// Try multiple ports if needed
function startServer(port) {
  try {
    server.listen(port, '0.0.0.0', () => {
      console.log(`Server is running on http://0.0.0.0:${port}`);
      console.log(`Server started at: ${new Date().toISOString()}`);
    });
  } catch (error) {
    console.error(`Could not start server on port ${port}:`, error);
    // Try next port
    if (port < 5010) {
      console.log(`Trying port ${port + 1}...`);
      startServer(port + 1);
    }
  }
}

// Handle server errors
server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.log(`Port 5000 is in use, trying 5001...`);
    startServer(5001);
  } else {
    console.error('Server error:', error);
  }
});

// Start the server on port 5000
startServer(5000);

// Handle process termination
process.on('SIGINT', () => {
  console.log('Server shutting down...');
  process.exit(0);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught exception:', error);
  console.log('Server will continue running');
});