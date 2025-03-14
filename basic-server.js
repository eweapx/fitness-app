// Ultra-minimal HTTP server with only standard Node.js modules
const http = require('http');
const fs = require('fs');
const path = require('path');

// Create server
const server = http.createServer((req, res) => {
  console.log(`Request: ${req.method} ${req.url}`);
  
  // Only serve specific files for maximum stability
  let filePath = '.';
  let contentType = 'text/html';
  
  if (req.url === '/' || req.url === '/index.html') {
    filePath += '/basic-index.html';
  } else {
    res.writeHead(404);
    res.end('404 Not Found');
    return;
  }
  
  // Read and serve file
  try {
    const content = fs.readFileSync(filePath);
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(content);
  } catch (error) {
    console.error(`Error serving ${filePath}:`, error);
    res.writeHead(500);
    res.end('500 Internal Server Error');
  }
});

// Start server on port 5000
const PORT = 5000;

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Basic Server running at http://0.0.0.0:${PORT}`);
});