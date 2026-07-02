const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 5000;
const STATIC_ROOT = path.join(__dirname, 'site');

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

const server = http.createServer((req, res) => {
  console.log(`Request received: ${req.method} ${req.url}`);
  
  let urlPath = req.url === '/' ? '/index.html' : req.url;
  let filePath = path.join(STATIC_ROOT, urlPath);
  
  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        console.error(`File not found: ${filePath}`);
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('404 Not Found');
      } else {
        console.error(`Server Error: ${err.message}`);
        res.writeHead(500);
        res.end('500 Internal Server Error');
      }
    } else {
      const ext = path.extname(filePath);
      const contentType = MIME_TYPES[ext] || 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    }
  });
});

server.on('error', (e) => {
  if (e.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use. Please kill the process using it.`);
  } else {
    console.error(`Server error: ${e}`);
  }
  process.exit(1);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Frontend server is LIVE at http://0.0.0.0:${PORT}/`);
  console.log(`Static files are being served from: ${STATIC_ROOT}`);
});
