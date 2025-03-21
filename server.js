const express = require('express');
const path = require('path');
const fs = require('fs');
const session = require('express-session');

// Import services
const userService = require('./src/services/userService');

// Create Express app
const app = express();
const PORT = process.env.PORT || 5000; // Use port 5000 for Replit compatibility

// Define paths to static content
const publicDir = path.join(__dirname, 'public');
const flutterBuildDir = path.join(__dirname, 'build/web');

// Ensure data directory exists
const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
  console.log(`Created data directory: ${dataDir}`);
}

// Load user data from storage
userService.loadFromStorage();
console.log('User service initialized with stored data');

// Set up logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Parse JSON request bodies
app.use(express.json());

// Session middleware
app.use(session({
  secret: 'health-fitness-tracker-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 } // 1 day
}));

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

// Authentication API routes
app.post('/api/auth/register', (req, res) => {
  const { name, email, password } = req.body;
  
  if (!name || !email || !password) {
    return res.status(400).json({ success: false, message: 'All fields are required' });
  }
  
  const result = userService.register(name, email, password);
  
  if (result.success) {
    // Store user in session
    req.session.userId = result.user.id;
    res.status(201).json(result);
  } else {
    res.status(400).json(result);
  }
});

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email and password are required' });
  }
  
  const result = userService.login(email, password);
  
  if (result.success) {
    // Store user in session
    req.session.userId = result.user.id;
    res.json(result);
  } else {
    res.status(401).json(result);
  }
});

app.post('/api/auth/logout', (req, res) => {
  const result = userService.logout();
  
  // Destroy session
  req.session.destroy(err => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Error logging out' });
    }
    res.json(result);
  });
});

app.get('/api/auth/current-user', (req, res) => {
  // Check if user is logged in via session
  if (req.session.userId) {
    const user = userService.getUserById(req.session.userId);
    if (user) {
      return res.json({ 
        success: true, 
        user: user.toSafeObject() 
      });
    }
  }
  
  res.status(401).json({ 
    success: false, 
    message: 'Not authenticated' 
  });
});

// Route for our fitness tracker app
app.get('/fitness', (req, res) => {
  res.sendFile(path.join(publicDir, 'fitness.html'));
});

// Login page route
app.get('/login', (req, res) => {
  res.sendFile(path.join(publicDir, 'login.html'));
});

// Login.html route (alternative for direct file access)
app.get('/login.html', (req, res) => {
  res.sendFile(path.join(publicDir, 'login.html'));
});

// Signup page route
app.get('/signup', (req, res) => {
  res.sendFile(path.join(publicDir, 'signup.html'));
});

// Signup.html route (alternative for direct file access)
app.get('/signup.html', (req, res) => {
  res.sendFile(path.join(publicDir, 'signup.html'));
});

// Fitness app route
app.get('/fitness', (req, res) => {
  res.sendFile(path.join(publicDir, 'fitness.html'));
});

// Fitness.html route (alternative for direct file access)
app.get('/fitness.html', (req, res) => {
  res.sendFile(path.join(publicDir, 'fitness.html'));
});

// Route for our simple test page
app.get('/simple', (req, res) => {
  res.sendFile(path.join(publicDir, 'simple-index.html'));
});

// Fallback route for SPA, but only if the path doesn't already exist as a file
app.get('*', (req, res) => {
  // First check if this is a test file request
  const reqPath = req.path.startsWith('/') ? req.path.substring(1) : req.path;
  const filePath = path.join(__dirname, reqPath);
  
  // Check if the file exists (for test purposes)
  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    return res.sendFile(filePath);
  }
  
  // If file doesn't exist and it's not an API route, check for SPA files
  const indexPath = path.join(publicDir, 'index.html');
  const flutterIndexPath = path.join(flutterBuildDir, 'index.html');

  // Check if it's a non-test or an API endpoint
  if (req.path.startsWith('/api/') || req.path === '/test-static.txt' || req.path === '/non-existent-path') {
    return res.status(404).send('Not Found');
  }

  // Serve the appropriate SPA index
  if (fs.existsSync(flutterIndexPath)) {
    res.sendFile(flutterIndexPath);
  } else if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send('No index.html found');
  }
});

// Only start the server if this file is run directly
if (require.main === module) {
  // Make sure we're binding to 0.0.0.0
  const HOST = '0.0.0.0';
  const server = app.listen(PORT, HOST, () => {
    console.log(`Server running at http://${HOST}:${PORT}`);
    
    // Signal that the server is ready to accept connections
    console.log(`Server ready - listening on port ${PORT}`);
    
    // Log additional binding information for debugging
    const addressInfo = server.address();
    console.log(`Server IP bindings: ${JSON.stringify(addressInfo)}`);
    
    // Extra debug output to ensure proper startup
    console.log(`Server is listening on ${addressInfo.address}:${addressInfo.port}`);
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