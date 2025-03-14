const http = require('http');
const fs = require('fs');
const path = require('path');

// Port for the Flutter web app
const PORT = 5001;

// Map of file extensions to MIME types
const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.eot': 'application/vnd.ms-fontobject',
  '.otf': 'font/otf'
};

// Create server
const server = http.createServer((req, res) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  
  // Handle root path
  let filePath = './public' + req.url;
  if (filePath === './public/') {
    filePath = './public/index.html';
  }

  // Get file extension
  const extname = String(path.extname(filePath)).toLowerCase();
  
  // Default content type
  let contentType = MIME_TYPES[extname] || 'application/octet-stream';
  
  // Read file
  fs.readFile(filePath, (error, content) => {
    if (error) {
      if(error.code === 'ENOENT') {
        // For SPA routing, serve index.html for all non-file routes
        if (!extname) {
          fs.readFile('./public/index.html', (err, content) => {
            if (err) {
              res.writeHead(500);
              res.end('Error: ' + err.code);
            } else {
              res.writeHead(200, { 'Content-Type': 'text/html' });
              res.end(content, 'utf-8');
            }
          });
        } else {
          res.writeHead(404);
          res.end(`File not found: ${req.url}`);
        }
      } else {
        res.writeHead(500);
        res.end('Error: ' + error.code);
      }
    } else {
      // Success - serve the file
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

// Start server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Flutter Web App running at http://0.0.0.0:${PORT}`);
  console.log(`Server started at: ${new Date().toISOString()}`);
  
  // Make this more obvious for the Replit environment
  console.log(`PORT=${PORT}`);
  console.log(`STATUS=ready`);
});

// Handle server errors
server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(`⚠️ Port ${PORT} is already in use`);
    console.error('Please close other applications using this port or change the port in this script');
  } else {
    console.error('Server error:', error);
  }
});