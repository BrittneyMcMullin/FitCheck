const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/auth');

// GET /api/outfits - get all outfits for logged in user
router.get('/', authMiddleware, async (req, res) => {
  try {
    const outfits = await pool.query(
      `SELECT o.*, 
        json_agg(
          json_build_object(
            'id', i.id,
            'name', i.name,
            'category', i.category,
            'image_url', i.image_url,
            'brand', i.brand
          )
        ) FILTER (WHERE i.id IS NOT NULL) as items
       FROM outfits o
       LEFT JOIN outfit_items oi ON o.id = oi.outfit_id
       LEFT JOIN items i ON oi.item_id = i.id
       WHERE o.user_id = $1
       GROUP BY o.id
       ORDER BY o.created_at DESC`,
      [req.userId]
    );
    res.json(outfits.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/outfits - create a new outfit
router.post('/', authMiddleware, async (req, res) => {
  const { name, item_ids } = req.body;

  if (!name || !item_ids || item_ids.length === 0) {
    return res.status(400).json({ error: 'Name and at least one item are required' });
  }

  try {
    const outfitResult = await pool.query(
      'INSERT INTO outfits (user_id, name) VALUES ($1, $2) RETURNING *',
      [req.userId, name]
    );

    const outfit = outfitResult.rows[0];

    for (const itemId of item_ids) {
      await pool.query(
        'INSERT INTO outfit_items (outfit_id, item_id) VALUES ($1, $2)',
        [outfit.id, itemId]
      );
    }

    res.status(201).json(outfit);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/outfits/:id
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM outfits WHERE id = $1 AND user_id = $2 RETURNING *',
      [req.params.id, req.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Outfit not found' });
    }

    res.json({ message: 'Outfit deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/outfits/:id/wear - mark outfit as worn
router.post('/:id/wear', authMiddleware, async (req, res) => {
  try {
    const outfitItems = await pool.query(
      'SELECT item_id FROM outfit_items WHERE outfit_id = $1',
      [req.params.id]
    );

    for (const row of outfitItems.rows) {
      await pool.query(
        'INSERT INTO wear_history (user_id, item_id) VALUES ($1, $2)',
        [req.userId, row.item_id]
      );
      await pool.query(
        'UPDATE items SET last_worn = NOW() WHERE id = $1',
        [row.item_id]
      );
    }

    res.json({ message: 'Outfit marked as worn' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});
// PUT /api/outfits/:id - edit outfit name and items
router.put('/:id', authMiddleware, async (req, res) => {
  const { name, item_ids } = req.body;
  const outfitId = req.params.id;

  try {
    // Make sure outfit belongs to this user
    const check = await pool.query(
      `SELECT id FROM outfits WHERE id = $1 AND user_id = $2`,
      [outfitId, req.userId]
    );
    if (check.rows.length === 0) return res.status(404).json({ error: 'Outfit not found' });

    // Update name if provided
    if (name) {
      await pool.query(
        `UPDATE outfits SET name = $1 WHERE id = $2`,
        [name, outfitId]
      );
    }

    // Replace items if provided
    if (item_ids && item_ids.length > 0) {
      await pool.query(`DELETE FROM outfit_items WHERE outfit_id = $1`, [outfitId]);
      for (const itemId of item_ids) {
        await pool.query(
          `INSERT INTO outfit_items (outfit_id, item_id) VALUES ($1, $2)`,
          [outfitId, itemId]
        );
      }
    }

    // Return updated outfit
    const result = await pool.query(
      `SELECT o.id, o.name, o.created_at,
        json_agg(json_build_object(
          'id', i.id, 'name', i.name, 'category', i.category, 'image_url', i.image_url
        )) FILTER (WHERE i.id IS NOT NULL) as items
       FROM outfits o
       LEFT JOIN outfit_items oi ON o.id = oi.outfit_id
       LEFT JOIN items i ON oi.item_id = i.id
       WHERE o.id = $1
       GROUP BY o.id`,
      [outfitId]
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;