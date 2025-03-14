const http = require('http');
const fs = require('fs');
const url = require('url');
const { Activity, tracker } = require('./models');

// Create HTTP server
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  
  console.log(`${req.method} ${path}`);
  
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  // Handle API requests
  if (path.startsWith('/api/')) {
    handleApiRequest(req, res, path);
    return;
  }

  // Serve static files (for now, just index.html)
  if (path === '/' || path === '/index.html') {
    serveFile(res, './index.html', 'text/html');
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('404 Not Found');
  }
});

// Handle API requests
function handleApiRequest(req, res, path) {
  // Set content type for all API responses
  res.setHeader('Content-Type', 'application/json');
  
  // GET /api/tracker - Return tracker data
  if (path === '/api/tracker' && req.method === 'GET') {
    const data = {
      activities: tracker.getActivities(),
      caloriesBurned: tracker.getTotalCalories(),
      stepsCount: tracker.getTotalSteps(),
      activitiesLogged: tracker.getActivitiesCount()
    };
    res.writeHead(200);
    res.end(JSON.stringify(data));
    return;
  }
  
  // POST /api/steps - Add steps
  if (path === '/api/steps' && req.method === 'POST') {
    let body = '';
    
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        
        if (data.steps && !isNaN(data.steps)) {
          tracker.addSteps(parseInt(data.steps));
          
          const responseData = {
            activities: tracker.getActivities(),
            caloriesBurned: tracker.getTotalCalories(),
            stepsCount: tracker.getTotalSteps(),
            activitiesLogged: tracker.getActivitiesCount()
          };
          
          res.writeHead(200);
          res.end(JSON.stringify(responseData));
        } else {
          res.writeHead(400);
          res.end(JSON.stringify({ error: 'Invalid steps data' }));
        }
      } catch (error) {
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Invalid JSON data' }));
      }
    });
    
    return;
  }
  
  // POST /api/activities - Add activity
  if (path === '/api/activities' && req.method === 'POST') {
    let body = '';
    
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        
        if (data.name && data.calories && data.duration && data.type) {
          const activity = new Activity(
            data.name,
            parseInt(data.calories),
            parseInt(data.duration),
            data.type
          );
          
          tracker.addActivity(activity);
          
          const responseData = {
            activities: tracker.getActivities(),
            caloriesBurned: tracker.getTotalCalories(),
            stepsCount: tracker.getTotalSteps(),
            activitiesLogged: tracker.getActivitiesCount()
          };
          
          res.writeHead(200);
          res.end(JSON.stringify(responseData));
        } else {
          res.writeHead(400);
          res.end(JSON.stringify({ error: 'Missing required activity data' }));
        }
      } catch (error) {
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Invalid JSON data' }));
      }
    });
    
    return;
  }
  
  // Method not allowed
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  // Not found
  res.writeHead(404);
  res.end(JSON.stringify({ error: 'API endpoint not found' }));
}

// Helper function to serve files
function serveFile(res, filePath, contentType) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('500 Internal Server Error');
      return;
    }
    
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

// Start server
const PORT = 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Fitness Tracker Server running at http://0.0.0.0:${PORT}`);
});