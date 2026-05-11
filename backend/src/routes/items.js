const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/auth');

// GET /api/items - get all items for logged in user
router.get('/', authMiddleware, async (req, res) => {
  try {
    const items = await pool.query(
      `SELECT i.id, i.user_id, i.name, i.category, i.brand,
        NULLIF(i.image_url, '') as image_url,
        i.season, i.occasion, i.last_worn, i.created_at, i.updated_at,
        ARRAY_AGG(DISTINCT ic.color) FILTER (WHERE ic.color IS NOT NULL) as colors,
        ARRAY_AGG(DISTINCT it.tag) FILTER (WHERE it.tag IS NOT NULL) as tags
       FROM items i
       LEFT JOIN item_colors ic ON i.id = ic.item_id
       LEFT JOIN item_tags it ON i.id = it.item_id
       WHERE i.user_id = $1
       GROUP BY i.id
       ORDER BY i.created_at DESC`,
      [req.userId]
    );
    res.json(items.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/items - add a new item
router.post('/', authMiddleware, async (req, res) => {
  const { name, category, brand, image_url, season, occasion, colors, tags } = req.body;

  if (!name || !category) {
    return res.status(400).json({ error: 'Name and category are required' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO items (user_id, name, category, brand, image_url, season, occasion)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [req.userId, name, category, brand, image_url, season, occasion]
    );

    const item = result.rows[0];

    if (colors && colors.length > 0) {
      for (const color of colors) {
        await pool.query(
          'INSERT INTO item_colors (item_id, color) VALUES ($1, $2)',
          [item.id, color]
        );
      }
    }

    if (tags && tags.length > 0) {
      for (const tag of tags) {
        await pool.query(
          'INSERT INTO item_tags (item_id, tag) VALUES ($1, $2)',
          [item.id, tag]
        );
      }
    }

    res.status(201).json({ ...item, colors: colors || [], tags: tags || [] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/items/:id - delete an item
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM items WHERE id = $1 AND user_id = $2 RETURNING *',
      [req.params.id, req.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Item not found' });
    }

    res.json({ message: 'Item deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;