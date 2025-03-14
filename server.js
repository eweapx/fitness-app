const http = require('http');
const fs = require('fs');

// Create a simple HTTP server
const server = http.createServer((req, res) => {
  console.log(`Request received: ${req.url}`);
  
  // For any request, just serve the index.html file
  fs.readFile('./index.html', (err, data) => {
    if (err) {
      console.error('Error reading index.html:', err);
      res.writeHead(500);
      res.end('Error loading index.html');
      return;
    }
    
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(data);
    res.end();
  });
});

// Start server on port 5000
const PORT = 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running at http://0.0.0.0:${PORT}`);
});