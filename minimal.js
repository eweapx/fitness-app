const express = require('express');
const app = express();
const port = 5000;

// Basic route that returns a simple HTML page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Minimal Express Server</title>
      </head>
      <body>
        <h1>Minimal Express Server</h1>
        <p>This is a minimal Express server running on port ${port}.</p>
        <p>Current time: ${new Date().toLocaleString()}</p>
      </body>
    </html>
  `);
});

// Start server
app.listen(port, '0.0.0.0', () => {
  console.log(`Minimal server running at http://0.0.0.0:${port}`);
});