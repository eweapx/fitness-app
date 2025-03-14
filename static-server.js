// Ultra-simple HTTP server for serving static files
const http = require('http');
const fs = require('fs');
const path = require('path');

// Common MIME types
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

// Create a simple HTTP server
const server = http.createServer((req, res) => {
  console.log(`${new Date().toISOString()} - Request: ${req.method} ${req.url}`);
  
  // Special API endpoint for health check
  if (req.url === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', time: new Date().toISOString() }));
    return;
  }
  
  // Parse the URL and get the pathname
  let filePath = '.' + req.url;
  if (filePath === './') {
    filePath = './index.html';
  }
  
  // Get the file extension
  const extname = String(path.extname(filePath)).toLowerCase();
  const contentType = mimeTypes[extname] || 'application/octet-stream';
  
  // Read the file
  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        // If the request was for a non-root path and the file doesn't exist, try serving index.html
        if (req.url !== '/' && req.url !== '/index.html') {
          console.log(`File ${filePath} not found, trying index.html instead`);
          fs.readFile('./index.html', (indexError, indexContent) => {
            if (indexError) {
              console.error('Error serving index.html:', indexError);
              res.writeHead(500);
              res.end('Error serving index.html');
              return;
            }
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(indexContent, 'utf-8');
          });
          return;
        }
        
        // File doesn't exist
        console.log(`File not found: ${filePath}`);
        res.writeHead(404);
        res.end('404 - Not Found');
      } else {
        // Server error
        console.error('Server error:', error);
        res.writeHead(500);
        res.end(`Server Error: ${error.code}`);
      }
    } else {
      // Success - return the file
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

// Set the port
const port = process.env.PORT || 5000;

// Start the server
server.listen(port, '0.0.0.0', () => {
  console.log(`Static File Server running at http://0.0.0.0:${port}`);
  console.log(`Server started at: ${new Date().toISOString()}`);
  
  // List all files in the current directory
  console.log('Files in directory:');
  fs.readdir('.', (err, files) => {
    if (err) {
      console.error('Error reading directory:', err);
      return;
    }
    
    files.forEach(file => {
      const stats = fs.statSync(file);
      if (stats.isDirectory()) {
        console.log(` - ${file}/`);
      } else if (file === 'index.html') {
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
    console.error(`Port ${port} is already in use`);
    console.log('Attempting to find a different port...');
    
    // Try a different port
    const newPort = port + 1;
    console.log(`Trying port ${newPort}...`);
    server.listen(newPort, '0.0.0.0');
  }
});

// Handle process termination
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});