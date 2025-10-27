
const express = require('express');
require('dotenv').config();

const app = express();
app.use(express.json());
const port = process.env.PORT || 3000;

// Import routes
const authRoutes = require('./authRoutes');

// Use routes
app.use('/api/auth', authRoutes);

app.get('/', (req, res) => {
  res.send('Kantin App API is running...');
});

app.listen(port, () => {
  console.log(`Server is listening on port ${port}`);
});
