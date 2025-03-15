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

// Global server variables
let server = null;
let serverUptime = 0;
let uptimeInterval = null;

// Error handling helper
const logError = (message, error) => {
  console.error(`[ERROR] ${message}:`, error);
};

// Create server with error handling
function createServer() {
  try {
    server = http.createServer((req, res) => {
      // Wrap the request handling in try/catch to prevent crashes
      try {
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
              logError(`Error serving ${filePath}`, error);
              res.writeHead(500);
              res.end('500 Internal Server Error');
            }
            return;
          }
          
          // Success - return the file
          res.writeHead(200, { 'Content-Type': contentType });
          res.end(content);
        });
      } catch (err) {
        logError('Unhandled exception in request handler', err);
        res.writeHead(500);
        res.end('500 Internal Server Error');
      }
    });
    
    // Error event handlers to prevent crashes
    server.on('error', (err) => {
      logError('Server error', err);
      restartServer();
    });
    
    server.on('clientError', (err, socket) => {
      logError('Client error', err);
      socket.end('HTTP/1.1 400 Bad Request\r\n\r\n');
    });
    
    process.on('uncaughtException', (err) => {
      logError('Uncaught exception', err);
      restartServer();
    });
    
    return server;
  } catch (err) {
    logError('Error creating server', err);
    return null;
  }
}

// Handle API requests
function handleApiRequest(req, res) {
  try {
    if (req.url === '/api/tracker' && req.method === 'GET') {
      // Return tracker data (for now, just a placeholder)
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        stepsCount: 0,
        caloriesBurned: 0,
        activitiesLogged: 0,
        activities: []
      }));
    } else if (req.url === '/api/health' && req.method === 'GET') {
      // Health check endpoint
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        status: 'ok',
        uptime: serverUptime,
        timestamp: new Date().toISOString()
      }));
    } else {
      // API endpoint not found
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'API endpoint not found' }));
    }
  } catch (err) {
    logError('Error in API handler', err);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Internal server error' }));
  }
}

// Restart server function
function restartServer() {
  console.log('[SERVER] Attempting to restart server...');
  
  if (server) {
    try {
      server.close();
    } catch (err) {
      logError('Error closing server', err);
    }
  }
  
  if (uptimeInterval) {
    clearInterval(uptimeInterval);
  }
  
  setTimeout(() => {
    startServer();
  }, 1000);
}

// Start server function
function startServer() {
  const PORT = 5002;
  serverUptime = 0;
  
  server = createServer();
  
  if (!server) {
    console.error('Failed to create server, retrying in 5 seconds...');
    setTimeout(startServer, 5000);
    return;
  }
  
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`\n====================================`);
    console.log(`✅ SERVER STARTED SUCCESSFULLY`);
    console.log(`✅ PORT: ${PORT}`);
    console.log(`✅ Access URL: http://0.0.0.0:${PORT}`);
    console.log(`====================================\n`);
    
    // Track uptime and heartbeat
    uptimeInterval = setInterval(() => {
      serverUptime += 10;
      if (serverUptime % 60 === 0) {
        console.log(`Server health: Running on port ${PORT} for ${serverUptime} seconds`);
      }
    }, 10000);
  });
  
  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`Port ${PORT} is already in use. Will retry on a different port.`);
      setTimeout(() => {
        server.close();
        server.listen(PORT + 1, '0.0.0.0');
      }, 1000);
    } else {
      logError('Server startup error', err);
      restartServer();
    }
  });
}

// Initial server start
startServer();