// Robust HTTP server with Node.js standard modules & improved error handling
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
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.eot': 'application/vnd.ms-fontobject'
};

// Global server variables 
let server = null;
let serverUptime = 0;
let uptimeInterval = null;
let heartbeatInterval = null;
let crashCount = 0;
const MAX_CRASH_COUNT = 5;
const DEFAULT_PORT = 5000; // Explicitly use port 5000 as required
let currentPort = DEFAULT_PORT;

// Error handling helper
const logError = (message, error) => {
  console.error(`[ERROR] ${message}:`, error?.message || error);
  
  // Keep track of consecutive crashes to prevent infinite restart loop
  if (message.includes('crash') || message.includes('error')) {
    crashCount++;
    console.warn(`Crash count: ${crashCount}/${MAX_CRASH_COUNT}`);
  }
};

// Reset crash count periodically to allow recovery
setInterval(() => {
  if (crashCount > 0) {
    crashCount--;
  }
}, 60000);

// Create server with improved error handling
function createServer() {
  try {
    const newServer = http.createServer((req, res) => {
      // Add request timeout to prevent hanging connections
      req.setTimeout(30000, () => {
        logError('Request timeout', { url: req.url });
        res.writeHead(408);
        res.end('Request Timeout');
      });
      
      // Wrap the request handling in try/catch to prevent crashes
      try {
        console.log(`Request: ${req.method} ${req.url}`);
        
        // Handle API requests
        if (req.url.startsWith('/api/')) {
          handleApiRequest(req, res);
          return;
        }
        
        // Handle CORS preflight requests
        if (req.method === 'OPTIONS') {
          res.writeHead(204, {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
          });
          res.end();
          return;
        }
        
        // Parse the URL to get the file path
        let filePath = req.url === '/' ? '/index.html' : req.url;
        
        // Sanitize file path to prevent directory traversal
        filePath = path.normalize(filePath).replace(/^(\.\.[\/\\])+/, '');
        filePath = '.' + filePath;
        
        // Check if path exists before trying to read it
        fs.access(filePath, fs.constants.F_OK, (err) => {
          if (err) {
            // Try index.html for SPAs when path doesn't exist
            if (!path.extname(filePath) && !filePath.includes('api')) {
              filePath = './index.html';
            } else {
              res.writeHead(404);
              res.end('404 Not Found');
              return;
            }
          }
          
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
            
            // Add CORS headers
            const headers = { 
              'Content-Type': contentType,
              'Access-Control-Allow-Origin': '*'
            };
            
            // Add caching for static assets
            if (extname !== '.html') {
              headers['Cache-Control'] = 'max-age=86400'; // 1 day
            } else {
              headers['Cache-Control'] = 'no-cache';
            }
            
            // Success - return the file
            res.writeHead(200, headers);
            res.end(content);
          });
        });
      } catch (err) {
        logError('Unhandled exception in request handler', err);
        if (!res.headersSent) {
          res.writeHead(500);
          res.end('500 Internal Server Error');
        }
      }
    });
    
    // Error event handlers to prevent crashes
    newServer.on('error', (err) => {
      logError('Server error', err);
      if (err.code !== 'EADDRINUSE') {
        restartServer();
      }
    });
    
    newServer.on('clientError', (err, socket) => {
      if (socket.writable) {
        logError('Client error', err);
        socket.end('HTTP/1.1 400 Bad Request\r\n\r\n');
      }
    });
    
    // Set timeouts to prevent hanging connections
    newServer.timeout = 60000; // 60 seconds
    newServer.keepAliveTimeout = 5000; // 5 seconds
    
    return newServer;
  } catch (err) {
    logError('Error creating server', err);
    return null;
  }
}

// Handle API requests
function handleApiRequest(req, res) {
  try {
    // Set common headers for all API responses
    const headers = {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'no-cache'
    };
    
    if (req.url === '/api/tracker' && req.method === 'GET') {
      // Return tracker data (for now, just a placeholder)
      res.writeHead(200, headers);
      res.end(JSON.stringify({
        stepsCount: 0,
        caloriesBurned: 0,
        activitiesLogged: 0,
        activities: []
      }));
    } else if (req.url === '/api/health' && req.method === 'GET') {
      // Health check endpoint
      res.writeHead(200, headers);
      res.end(JSON.stringify({
        status: 'ok',
        uptime: serverUptime,
        timestamp: new Date().toISOString()
      }));
    } else {
      // API endpoint not found
      res.writeHead(404, headers);
      res.end(JSON.stringify({ error: 'API endpoint not found' }));
    }
  } catch (err) {
    logError('Error in API handler', err);
    if (!res.headersSent) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Internal server error' }));
    }
  }
}

// Restart server function with improved safety
function restartServer() {
  // Check if we've crashed too many times and should stop retrying
  if (crashCount >= MAX_CRASH_COUNT) {
    console.error('[SERVER] Too many crashes detected. Stopping restart attempts.');
    return;
  }
  
  console.log('[SERVER] Attempting to restart server...');
  
  if (server) {
    try {
      server.close();
    } catch (err) {
      logError('Error closing server', err);
    }
  }
  
  // Clear all intervals
  if (uptimeInterval) {
    clearInterval(uptimeInterval);
    uptimeInterval = null;
  }
  
  if (heartbeatInterval) {
    clearInterval(heartbeatInterval);
    heartbeatInterval = null;
  }
  
  // Use a delay before restarting to prevent immediate crash loops
  const restartDelay = Math.min(1000 * crashCount, 10000);
  console.log(`[SERVER] Restarting in ${restartDelay/1000} seconds...`);
  
  setTimeout(() => {
    startServer();
  }, restartDelay);
}

// Start server function with port fallback
function startServer() {
  serverUptime = 0;
  
  server = createServer();
  
  if (!server) {
    console.error('[SERVER] Failed to create server, retrying in 5 seconds...');
    setTimeout(startServer, 5000);
    return;
  }
  
  // Use default port
  currentPort = DEFAULT_PORT;
  
  const startListening = (port) => {
    server.listen(port, '0.0.0.0', () => {
      console.log(`\n====================================`);
      console.log(`✅ SERVER STARTED SUCCESSFULLY`);
      console.log(`✅ PORT: ${port}`);
      console.log(`✅ Access URL: http://0.0.0.0:${port}`);
      console.log(`====================================\n`);
      
      // Reset crash count on successful startup
      crashCount = 0;
      
      // Track uptime and heartbeat
      uptimeInterval = setInterval(() => {
        serverUptime += 10;
      }, 10000);
      
      // Set up a heartbeat to regularly check server health
      heartbeatInterval = setInterval(() => {
        if (serverUptime % 60 === 0) {
          console.log(`[SERVER] Health check: Running on port ${port} for ${serverUptime} seconds`);
        }
      }, 10000);
    });
  };
  
  // Handle EADDRINUSE error more gracefully
  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.warn(`[SERVER] Port ${currentPort} is already in use.`);
      
      // Try to close the server if it exists
      if (server) {
        try {
          server.close();
        } catch (closeErr) {
          logError('Error closing server', closeErr);
        }
      }
      
      // Try a predefined port: 5001
      currentPort = 5002;
      console.log(`[SERVER] Trying alternative port: ${currentPort}`);
      
      setTimeout(() => {
        try {
          startListening(currentPort);
        } catch (e) {
          logError('Error starting server on alternate port', e);
          restartServer();
        }
      }, 1000);
    } else {
      logError('Server startup error', err);
      restartServer();
    }
  });
  
  // Start listening on primary port
  startListening(currentPort);
}

// Initial server start
startServer();