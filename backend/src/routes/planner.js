const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/auth');

// GET /api/planner/week?start=YYYY-MM-DD
router.get('/week', authMiddleware, async (req, res) => {
  try {
    const { start } = req.query;
    const startDate = start || new Date().toISOString().split('T')[0];

    const result = await pool.query(
      `SELECT 
        p.id, p.planned_date, p.worn,
        o.id as outfit_id, o.name as outfit_name,
        json_agg(json_build_object(
          'id', i.id, 'name', i.name, 'category', i.category, 'image_url', i.image_url
        )) FILTER (WHERE i.id IS NOT NULL) as items
       FROM outfit_planner p
       JOIN outfits o ON p.outfit_id = o.id
       LEFT JOIN outfit_items oi ON o.id = oi.outfit_id
       LEFT JOIN items i ON oi.item_id = i.id
       WHERE p.user_id = $1
       AND p.planned_date >= $2
       AND p.planned_date < ($2::date + interval '7 days')
       GROUP BY p.id, o.id
       ORDER BY p.planned_date ASC`,
      [req.userId, startDate]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/planner - assign outfit to a day
router.post('/', authMiddleware, async (req, res) => {
  const { outfit_id, planned_date } = req.body;
  if (!outfit_id || !planned_date) {
    return res.status(400).json({ error: 'outfit_id and planned_date are required' });
  }
  try {
    const result = await pool.query(
      `INSERT INTO outfit_planner (user_id, outfit_id, planned_date)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, planned_date)
       DO UPDATE SET outfit_id = $2, worn = FALSE
       RETURNING *`,
      [req.userId, outfit_id, planned_date]
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/planner/:id/worn - mark a planned outfit as worn
router.post('/:id/worn', authMiddleware, async (req, res) => {
  try {
    // Mark as worn
    const planner = await pool.query(
      `UPDATE outfit_planner SET worn = TRUE WHERE id = $1 AND user_id = $2 RETURNING *`,
      [req.params.id, req.userId]
    );
    if (planner.rows.length === 0) return res.status(404).json({ error: 'Not found' });

    // Get outfit items and record wear history
    const items = await pool.query(
      `SELECT item_id FROM outfit_items WHERE outfit_id = $1`,
      [planner.rows[0].outfit_id]
    );
    for (const item of items.rows) {
      await pool.query(
        `INSERT INTO wear_history (user_id, item_id, worn_at) VALUES ($1, $2, $3)`,
        [req.userId, item.item_id, planner.rows[0].planned_date]
      );
    }
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/planner/:id - remove outfit from a day
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      `DELETE FROM outfit_planner WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.userId]
    );
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;