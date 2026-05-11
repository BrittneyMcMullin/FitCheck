const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/auth');

// POST /api/social/posts - share an outfit to feed
router.post('/posts', authMiddleware, async (req, res) => {
  const { outfit_id, caption } = req.body;
  if (!outfit_id) return res.status(400).json({ error: 'outfit_id is required' });

  try {
    const result = await pool.query(
      `INSERT INTO posts (user_id, outfit_id, caption) VALUES ($1, $2, $3) RETURNING *`,
      [req.userId, outfit_id, caption || '']
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/social/feed - get posts from followed users + own posts
router.get('/feed', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
            `SELECT 
              p.id, p.caption, p.created_at,
              u.id as user_id, u.display_name, u.profile_photo_url,
              o.name as outfit_name,
              COUNT(DISTINCT lk.user_id) as like_count,
              COUNT(DISTINCT c.id) as comment_count,
              EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = $1) as liked_by_me,
              COUNT(DISTINCT d.user_id) as dislike_count,
EXISTS(SELECT 1 FROM dislikes WHERE post_id = p.id AND user_id = $1) as disliked_by_me,
              json_agg(DISTINCT jsonb_build_object(
                'id', i.id,
                'name', i.name,
                'image_url', NULLIF(i.image_url, ''),
                'category', i.category
              )) FILTER (WHERE i.id IS NOT NULL) as items
             FROM posts p
             JOIN users u ON p.user_id = u.id
             JOIN outfits o ON p.outfit_id = o.id
             LEFT JOIN outfit_items oi ON o.id = oi.outfit_id
             LEFT JOIN items i ON oi.item_id = i.id
             LEFT JOIN likes lk ON p.id = lk.post_id
             LEFT JOIN dislikes d ON p.id = d.post_id
             LEFT JOIN comments c ON p.id = c.post_id
             WHERE p.user_id = $1
                OR p.user_id IN (
                  SELECT following_id FROM follows WHERE follower_id = $1
                )
             GROUP BY p.id, u.id, o.name
             ORDER BY p.created_at DESC
             LIMIT 50`,
            [req.userId]
          );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/social/posts/:id - delete a post
router.delete('/posts/:id', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `DELETE FROM posts WHERE id = $1 AND user_id = $2 RETURNING *`,
      [req.params.id, req.userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Post not found' });
    res.json({ message: 'Post deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/social/likes - toggle like on a post
router.post('/likes', authMiddleware, async (req, res) => {
  const { post_id } = req.body;
  if (!post_id) return res.status(400).json({ error: 'post_id is required' });

  try {
    const existing = await pool.query(
        `SELECT user_id FROM likes WHERE post_id = $1 AND user_id = $2`,
        [post_id, req.userId]
      );

    if (existing.rows.length > 0) {
      await pool.query(`DELETE FROM likes WHERE post_id = $1 AND user_id = $2`, [post_id, req.userId]);
      res.json({ liked: false });
    } else {
      await pool.query(`INSERT INTO likes (post_id, user_id) VALUES ($1, $2)`, [post_id, req.userId]);
      res.json({ liked: true });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});
// POST /api/social/dislikes - toggle dislike on a post
router.post('/dislikes', authMiddleware, async (req, res) => {
    const { post_id } = req.body;
    if (!post_id) return res.status(400).json({ error: 'post_id is required' });
  
    try {
      // Remove like if exists
      await pool.query(
        `DELETE FROM likes WHERE post_id = $1 AND user_id = $2`,
        [post_id, req.userId]
      );
  
      const existing = await pool.query(
        `SELECT user_id FROM dislikes WHERE post_id = $1 AND user_id = $2`,
        [post_id, req.userId]
      );
  
      if (existing.rows.length > 0) {
        await pool.query(
          `DELETE FROM dislikes WHERE post_id = $1 AND user_id = $2`,
          [post_id, req.userId]
        );
        res.json({ disliked: false });
      } else {
        await pool.query(
          `INSERT INTO dislikes (post_id, user_id) VALUES ($1, $2)`,
          [post_id, req.userId]
        );
        res.json({ disliked: true });
      }
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  });

// GET /api/social/comments/:post_id - get comments for a post
router.get('/comments/:post_id', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT c.*, u.display_name, u.profile_photo_url
       FROM comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.post_id = $1
       ORDER BY c.created_at ASC`,
      [req.params.post_id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/social/comments - add a comment
router.post('/comments', authMiddleware, async (req, res) => {
  const { post_id, content } = req.body;
  if (!post_id || !content) return res.status(400).json({ error: 'post_id and content are required' });

  try {
    const result = await pool.query(
      `INSERT INTO comments (post_id, user_id, content) VALUES ($1, $2, $3) RETURNING *`,
      [post_id, req.userId, content]
    );
    const comment = result.rows[0];
    const user = await pool.query(`SELECT display_name FROM users WHERE id = $1`, [req.userId]);
    res.status(201).json({ ...comment, display_name: user.rows[0].display_name });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/social/follows - toggle follow
router.post('/follows', authMiddleware, async (req, res) => {
  const { user_id } = req.body;
  if (!user_id) return res.status(400).json({ error: 'user_id is required' });
  if (user_id === req.userId) return res.status(400).json({ error: 'Cannot follow yourself' });

  try {
    const existing = await pool.query(
      `SELECT id FROM follows WHERE follower_id = $1 AND following_id = $2`,
      [req.userId, user_id]
    );

    if (existing.rows.length > 0) {
      await pool.query(`DELETE FROM follows WHERE follower_id = $1 AND following_id = $2`, [req.userId, user_id]);
      res.json({ following: false });
    } else {
      await pool.query(`INSERT INTO follows (follower_id, following_id) VALUES ($1, $2)`, [req.userId, user_id]);
      res.json({ following: true });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/social/followers/:user_id - get follower/following counts
router.get('/followers/:user_id', authMiddleware, async (req, res) => {
  try {
    const followers = await pool.query(
      `SELECT COUNT(*) FROM follows WHERE following_id = $1`, [req.params.user_id]
    );
    const following = await pool.query(
      `SELECT COUNT(*) FROM follows WHERE follower_id = $1`, [req.params.user_id]
    );
    const isFollowing = await pool.query(
      `SELECT id FROM follows WHERE follower_id = $1 AND following_id = $2`,
      [req.userId, req.params.user_id]
    );
    res.json({
      followers: parseInt(followers.rows[0].count),
      following: parseInt(following.rows[0].count),
      is_following: isFollowing.rows.length > 0
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});


// GET /api/social/users/search?q=username
router.get('/users/search', authMiddleware, async (req, res) => {
  const { q } = req.query;
  if (!q) return res.status(400).json({ error: 'Search query required' });

  try {
    const result = await pool.query(
      `SELECT u.id, u.display_name, u.profile_photo_url,
        COUNT(DISTINCT f.id) as follower_count,
        EXISTS(SELECT 1 FROM follows f2 WHERE f2.follower_id = $1 AND f2.following_id = u.id) as is_following
       FROM users u
       LEFT JOIN follows f ON u.id = f.following_id
       WHERE u.display_name ILIKE $2 AND u.id != $1
       GROUP BY u.id
       LIMIT 20`,
      [req.userId, `%${q}%`]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/social/users/:id/wardrobe - get a user's public wardrobe
router.get('/users/:id/wardrobe', authMiddleware, async (req, res) => {
    try {
      const items = await pool.query(
        `SELECT i.*,
          NULLIF(i.image_url, '') as image_url,
          ARRAY_AGG(DISTINCT ic.color) FILTER (WHERE ic.color IS NOT NULL) as colors,
          COUNT(DISTINCT il.user_id) as like_count,
          COUNT(DISTINCT id2.user_id) as dislike_count,
          COUNT(DISTINCT ic2.id) as comment_count,
          EXISTS(SELECT 1 FROM item_likes WHERE item_id = i.id AND user_id = $2) as liked_by_me,
          EXISTS(SELECT 1 FROM item_dislikes WHERE item_id = i.id AND user_id = $2) as disliked_by_me
         FROM items i
         LEFT JOIN item_colors ic ON i.id = ic.item_id
         LEFT JOIN item_likes il ON i.id = il.item_id
         LEFT JOIN item_dislikes id2 ON i.id = id2.item_id
         LEFT JOIN item_comments ic2 ON i.id = ic2.item_id
         WHERE i.user_id = $1
         GROUP BY i.id
         ORDER BY i.created_at DESC`,
        [req.params.id, req.userId]
      );
      res.json(items.rows);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  });
  
  // GET /api/social/users/:id/profile - get a user's profile info
  router.get('/users/:id/profile', authMiddleware, async (req, res) => {
    try {
      const user = await pool.query(
        `SELECT u.id, u.display_name, u.bio, u.profile_photo_url,
          COUNT(DISTINCT i.id) as item_count,
          COUNT(DISTINCT o.id) as outfit_count,
          COUNT(DISTINCT f1.follower_id) as follower_count,
          COUNT(DISTINCT f2.following_id) as following_count,
          EXISTS(SELECT 1 FROM follows WHERE follower_id = $2 AND following_id = u.id) as is_following
         FROM users u
         LEFT JOIN items i ON u.id = i.user_id
         LEFT JOIN outfits o ON u.id = o.user_id
         LEFT JOIN follows f1 ON u.id = f1.following_id
         LEFT JOIN follows f2 ON u.id = f2.follower_id
         WHERE u.id = $1
         GROUP BY u.id`,
        [req.params.id, req.userId]
      );
      if (user.rows.length === 0) return res.status(404).json({ error: 'User not found' });
      res.json(user.rows[0]);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  });
  
  // POST /api/social/items/:id/like - toggle like on an item
  router.post('/items/:id/like', authMiddleware, async (req, res) => {
    try {
      await pool.query(`DELETE FROM item_dislikes WHERE item_id = $1 AND user_id = $2`, [req.params.id, req.userId]);
      const existing = await pool.query(
        `SELECT user_id FROM item_likes WHERE item_id = $1 AND user_id = $2`,
        [req.params.id, req.userId]
      );
      if (existing.rows.length > 0) {
        await pool.query(`DELETE FROM item_likes WHERE item_id = $1 AND user_id = $2`, [req.params.id, req.userId]);
        res.json({ liked: false });
      } else {
        await pool.query(`INSERT INTO item_likes (item_id, user_id) VALUES ($1, $2)`, [req.params.id, req.userId]);
        res.json({ liked: true });
      }
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  });
  
  // POST /api/social/items/:id/dislike - toggle dislike on an item
  router.post('/items/:id/dislike', authMiddleware, async (req, res) => {
    try {
      await pool.query(`DELETE FROM item_likes WHERE item_id = $1 AND user_id = $2`, [req.params.id, req.userId]);
      const existing = await pool.query(
        `SELECT user_id FROM item_dislikes WHERE item_id = $1 AND user_id = $2`,
        [req.params.id, req.userId]
      );
      if (existing.rows.length > 0) {
        await pool.query(`DELETE FROM item_dislikes WHERE item_id = $1 AND user_id = $2`, [req.params.id, req.userId]);
        res.json({ disliked: false });
      } else {
        await pool.query(`INSERT INTO item_dislikes (item_id, user_id) VALUES ($1, $2)`, [req.params.id, req.userId]);
        res.json({ disliked: true });
      }
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  });
  
  // GET /api/social/items/:id/comments - get comments on an item
  router.get('/items/:id/comments', authMiddleware, async (req, res) => {
    try {
      const result = await pool.query(
        `SELECT ic.*, u.display_name FROM item_comments ic
         JOIN users u ON ic.user_id = u.id
         WHERE ic.item_id = $1
         ORDER BY ic.created_at ASC`,
        [req.params.id]
      );
      res.json(result.rows);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  });
  
  // POST /api/social/items/:id/comments - comment on an item
  router.post('/items/:id/comments', authMiddleware, async (req, res) => {
    const { content } = req.body;
    if (!content) return res.status(400).json({ error: 'content is required' });
    try {
      const result = await pool.query(
        `INSERT INTO item_comments (item_id, user_id, content) VALUES ($1, $2, $3) RETURNING *`,
        [req.params.id, req.userId, content]
      );
      const comment = result.rows[0];
      const user = await pool.query(`SELECT display_name FROM users WHERE id = $1`, [req.userId]);
      res.status(201).json({ ...comment, display_name: user.rows[0].display_name });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  });
    router.get('/users', authMiddleware, async (req, res) => {
        try {
          const { q } = req.query;
          const result = await pool.query(
            `SELECT u.id, u.display_name, u.profile_photo_url, u.bio,
              EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = u.id) as is_following
             FROM users u
             WHERE u.id != $1
             AND ($2 = '' OR LOWER(u.display_name) LIKE LOWER($3))
             ORDER BY u.display_name ASC`,
            [req.userId, q || '', `%${q || ''}%`]
          );
          res.json(result.rows);
        } catch (err) {
          console.error(err);
          res.status(500).json({ error: 'Server error' });
        }
      });
module.exports = router;