const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const itemRoutes = require('./routes/items');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/items', itemRoutes);

const uploadRoutes = require('./routes/upload');
app.use('/api/upload', uploadRoutes);

const outfitRoutes = require('./routes/outfits');
app.use('/api/outfits', outfitRoutes);

const recommendationRoutes = require('./routes/recommendations');
app.use('/api/recommendations', recommendationRoutes);

app.get('/', (req, res) => {
  res.json({ message: 'FitCheck API is running!' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`FitCheck server running on port ${PORT}`);

const socialRoutes = require('./routes/social');
app.use('/api/social', socialRoutes);

const analyticsRoutes = require('./routes/analytics');
app.use('/api/analytics', analyticsRoutes);

const plannerRoutes = require('./routes/planner');
app.use('/api/planner', plannerRoutes);
});