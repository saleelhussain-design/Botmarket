const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Plain JS Server is running!\n');
});

server.listen(3001, '0.0.0.0', () => {
  console.log('Plain JS server listening on port 3001');
});
