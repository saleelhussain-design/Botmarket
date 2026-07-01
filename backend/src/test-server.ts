import express from 'express';

const app = express();
const PORT = 3001;

app.get('/health', (req, res) => {
  res.status(200).send('Backend is alive!');
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Test server running at http://0.0.0.0:${PORT}`);
});
