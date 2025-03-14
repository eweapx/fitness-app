// Improved HTTP server with Node.js standard modules
const http = require('http');
const fs = require('fs');
const path = require('path');

// MIME types mapping for content-type headers
const contentTypes = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

// Create server
const server = http.createServer((req, res) => {
  console.log(`Request: ${req.method} ${req.url}`);
  
  // Handle API requests
  if (req.url.startsWith('/api/')) {
    handleApiRequest(req, res);
    return;
  }
  
  // Parse the URL to get the file path
  let filePath = req.url === '/' ? '/index.html' : req.url;
  filePath = '.' + filePath;
  
  // Get the file extension to determine content type
  const extname = path.extname(filePath);
  const contentType = contentTypes[extname] || 'text/plain';
  
  // Read and serve the file
  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        // File not found - return 404
        res.writeHead(404);
        res.end('404 Not Found');
      } else {
        // Server error - return 500
        console.error(`Error serving ${filePath}:`, error);
        res.writeHead(500);
        res.end('500 Internal Server Error');
      }
      return;
    }
    
    // Success - return the file
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(content);
  });
});

// Handle API requests
function handleApiRequest(req, res) {
  if (req.url === '/api/tracker' && req.method === 'GET') {
    // Return tracker data (for now, just a placeholder)
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      stepsCount: 0,
      caloriesBurned: 0,
      activitiesLogged: 0,
      activities: []
    }));
  } else {
    // API endpoint not found
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'API endpoint not found' }));
  }
}

// Start server on port 5002 (changed from 5000 to avoid conflicts)
const PORT = 5002;

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Basic Server running at http://0.0.0.0:${PORT}`);
});