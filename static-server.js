// Ultra-simple HTTP server for serving static files with improved error handling
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

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
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.eot': 'application/vnd.ms-fontobject',
  '.otf': 'font/otf'
};

// Function to create a server with error handling and port fallback
function createServer(initialPort) {
  let currentPort = initialPort;
  let maxRetries = 5;
  let retryCount = 0;
  let serverInstance = null;
  
  // Create a simple HTTP server
  const server = http.createServer((req, res) => {
    console.log(`${new Date().toISOString()} - Request: ${req.method} ${req.url}`);
    
    // Set CORS headers for development
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
      res.writeHead(204);
      res.end();
      return;
    }
    
    // Special API endpoint for health check
    if (req.url === '/api/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        status: 'healthy', 
        time: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        hostname: os.hostname()
      }));
      return;
    }
    
    // Parse the URL and get the pathname
    let filePath = '.' + req.url;
    if (filePath === './') {
      filePath = './index.html';
    }
    
    // Clean the file path to avoid directory traversal attacks
    filePath = path.normalize(filePath).replace(/^(\.\.[\/\\])+/, '');
    
    // Get the file extension
    const extname = String(path.extname(filePath)).toLowerCase();
    const contentType = mimeTypes[extname] || 'application/octet-stream';
    
    // Check if file exists (synchronous to prevent race conditions)
    if (!fs.existsSync(filePath)) {
      // For SPAs, redirect to index.html for client-side routing
      if (req.url !== '/' && req.url !== '/index.html' && !req.url.includes('.')) {
        console.log(`File ${filePath} not found, serving index.html for client-side routing`);
        filePath = './index.html';
      } else {
        // File doesn't exist
        console.log(`File not found: ${filePath}`);
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end('<h1>404 - Not Found</h1><p>The requested resource could not be found on this server.</p>');
        return;
      }
    }
    
    // Read the file
    try {
      const content = fs.readFileSync(filePath);
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    } catch (error) {
      console.error('Error serving file:', error);
      res.writeHead(500, { 'Content-Type': 'text/html' });
      res.end('<h1>500 - Server Error</h1><p>Sorry, there was a problem serving the requested file.</p>');
    }
  });
  
  // Attempt to start the server with port fallback
  function startServer() {
    try {
      serverInstance = server.listen(currentPort, '0.0.0.0', () => {
        console.log(`✅ Static File Server running at http://0.0.0.0:${currentPort}`);
        console.log(`Server started at: ${new Date().toISOString()}`);
        
        // List all files in the current directory
        console.log('Files in directory:');
        try {
          const files = fs.readdirSync('.');
          files.forEach(file => {
            try {
              const stats = fs.statSync(file);
              if (stats.isDirectory()) {
                console.log(` - ${file}/`);
              } else if (file === 'index.html') {
                console.log(` - ${file} (MAIN PAGE)`);
              } else {
                console.log(` - ${file}`);
              }
            } catch (err) {
              console.log(` - ${file} (error reading stats)`);
            }
          });
        } catch (err) {
          console.error('Error reading directory:', err);
        }
      });
      
      // Handle server errors
      server.on('error', (err) => {
        if (err.code === 'EADDRINUSE') {
          retryCount++;
          if (retryCount <= maxRetries) {
            console.error(`⚠️ Port ${currentPort} is already in use`);
            currentPort++;
            console.log(`Trying port ${currentPort} (attempt ${retryCount}/${maxRetries})...`);
            
            // Try to close the server if it's running
            if (serverInstance) {
              try {
                serverInstance.close();
              } catch (e) {
                // Ignore errors when closing
              }
            }
            
            // Try the next port
            setTimeout(startServer, 1000);
          } else {
            console.error(`❌ Failed to start server after ${maxRetries} attempts.`);
            console.error(`Please ensure there are no other servers running on ports ${initialPort}-${currentPort-1}.`);
          }
        } else {
          console.error('Server error:', err);
        }
      });
    } catch (err) {
      console.error('Failed to start server:', err);
      process.exit(1);
    }
  }
  
  return {
    start: startServer,
    getInstance: () => serverInstance
  };
}

// Set the port
const PORT = process.env.PORT || 5000;

// Create and start the server
const serverController = createServer(PORT);
serverController.start();

// Handle process termination
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  const instance = serverController.getInstance();
  if (instance) {
    instance.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
    
    // Force exit after 5 seconds if the server doesn't close gracefully
    setTimeout(() => {
      console.log('Forcing exit after timeout');
      process.exit(1);
    }, 5000);
  } else {
    process.exit(0);
  }
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  const instance = serverController.getInstance();
  if (instance) {
    instance.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
    
    // Force exit after 5 seconds if the server doesn't close gracefully
    setTimeout(() => {
      console.log('Forcing exit after timeout');
      process.exit(1);
    }, 5000);
  } else {
    process.exit(0);
  }
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('Uncaught exception:', err);
  console.log('Server will continue running');
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  console.log('Server will continue running');
});