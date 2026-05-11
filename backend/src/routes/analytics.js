const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/auth');

// GET /api/analytics
router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    // Total items and outfits
    const totals = await pool.query(
      `SELECT 
        (SELECT COUNT(*) FROM items WHERE user_id = $1) as total_items,
        (SELECT COUNT(*) FROM outfits WHERE user_id = $1) as total_outfits,
        (SELECT COUNT(*) FROM follows WHERE following_id = $1) as followers,
        (SELECT COUNT(*) FROM follows WHERE follower_id = $1) as following`,
      [userId]
    );

    // Most worn items
    const mostWorn = await pool.query(
      `SELECT i.name, i.category, i.image_url, COUNT(wh.id) as wear_count
       FROM items i
       LEFT JOIN wear_history wh ON i.id = wh.item_id
       WHERE i.user_id = $1
       GROUP BY i.id
       ORDER BY wear_count DESC
       LIMIT 5`,
      [userId]
    );

    // Unworn items
    const unworn = await pool.query(
      `SELECT i.name, i.category, i.image_url
       FROM items i
       LEFT JOIN wear_history wh ON i.id = wh.item_id
       WHERE i.user_id = $1 AND wh.id IS NULL
       LIMIT 5`,
      [userId]
    );

    // Category breakdown
    const categories = await pool.query(
      `SELECT category, COUNT(*) as count
       FROM items WHERE user_id = $1
       GROUP BY category
       ORDER BY count DESC`,
      [userId]
    );

    res.json({
      totals: totals.rows[0],
      most_worn: mostWorn.rows,
      unworn: unworn.rows,
      categories: categories.rows
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;