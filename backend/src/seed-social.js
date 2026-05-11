require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const pool = new Pool({
  host: 'localhost',
  database: 'fitcheck',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port: 5432
});

// Sample clothing items per persona
const personas = [
  {
    email: 'maya@fitcheck.app',
    display_name: 'Maya Chen',
    bio: 'Minimalist aesthetic | NYC',
    items: [
      { name: 'White Linen Shirt', category: 'tops', brand: 'Everlane', colors: ['White'], season: 'all seasons', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=400' },
      { name: 'Black Wide Leg Trousers', category: 'bottoms', brand: 'Zara', colors: ['Black'], season: 'all seasons', occasion: 'work', image_url: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400' },
      { name: 'Beige Trench Coat', category: 'outerwear', brand: 'Burberry', colors: ['Beige'], season: 'fall', occasion: 'work', image_url: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400' },
      { name: 'White Sneakers', category: 'shoes', brand: 'Common Projects', colors: ['White'], season: 'all seasons', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400' },
      { name: 'Gold Hoop Earrings', category: 'accessories', brand: 'Mejuri', colors: ['Gold'], season: 'all seasons', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1630019852942-f89202989a59?w=400' },
    ]
  },
  {
    email: 'jordan@fitcheck.app',
    display_name: 'Jordan Lee',
    bio: 'Streetwear head 🔥 | LA',
    items: [
      { name: 'Graphic Tee', category: 'tops', brand: 'Supreme', colors: ['Black'], season: 'all seasons', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400' },
      { name: 'Cargo Pants', category: 'bottoms', brand: 'Carhartt', colors: ['Olive'], season: 'fall', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1548883354-94bcfe321cbb?w=400' },
      { name: 'Puffer Jacket', category: 'outerwear', brand: 'North Face', colors: ['Black'], season: 'winter', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1547949003-9792a18a2601?w=400' },
      { name: 'Jordan 1s', category: 'shoes', brand: 'Nike', colors: ['Red', 'Black', 'White'], season: 'all seasons', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1556906781-9a412961a28c?w=400' },
      { name: 'Fitted Cap', category: 'accessories', brand: 'New Era', colors: ['Black'], season: 'all seasons', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=400' },
    ]
  },
  {
    email: 'sofia@fitcheck.app',
    display_name: 'Sofia Rivera',
    bio: 'Boho vibes always ✨ | Miami',
    items: [
      { name: 'Floral Wrap Dress', category: 'dresses', brand: 'Free People', colors: ['Pink', 'White'], season: 'summer', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400' },
      { name: 'Crochet Top', category: 'tops', brand: 'Urban Outfitters', colors: ['White'], season: 'summer', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1594938374182-a57369c4cc28?w=400' },
      { name: 'Linen Wide Pants', category: 'bottoms', brand: 'Mango', colors: ['Beige'], season: 'summer', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400' },
      { name: 'Strappy Sandals', category: 'shoes', brand: 'Steve Madden', colors: ['Brown'], season: 'summer', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400' },
      { name: 'Woven Tote Bag', category: 'accessories', brand: 'Lack of Color', colors: ['Beige'], season: 'summer', occasion: 'casual', image_url: 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=400' },
    ]
  },
  {
    email: 'alex@fitcheck.app',
    display_name: 'Alex Kim',
    bio: 'Business casual done right 💼 | Chicago',
    items: [
      { name: 'Navy Blazer', category: 'outerwear', brand: 'J.Crew', colors: ['Navy'], season: 'all seasons', occasion: 'work', image_url: 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400' },
      { name: 'White Oxford Shirt', category: 'tops', brand: 'Brooks Brothers', colors: ['White'], season: 'all seasons', occasion: 'work', image_url: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400' },
      { name: 'Slim Chinos', category: 'bottoms', brand: 'Banana Republic', colors: ['Beige'], season: 'all seasons', occasion: 'work', image_url: 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400' },
      { name: 'Oxford Shoes', category: 'shoes', brand: 'Cole Haan', colors: ['Brown'], season: 'all seasons', occasion: 'work', image_url: 'https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=400' },
      { name: 'Leather Watch', category: 'accessories', brand: 'Fossil', colors: ['Brown'], season: 'all seasons', occasion: 'work', image_url: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400' },
    ]
  }
];

const outfitCaptions = [
  "Today's fit — keeping it simple 🖤",
  "Weather had other plans but the outfit didn't 😅",
  "New pieces, who dis",
  "Outfit repeater and proud of it",
  "This combo just works every time",
  "Dressed for the job I want 💼",
  "Sunday vibes all week long",
  "Can't go wrong with the classics",
];

const commentTemplates = [
  "Love this look! 🔥",
  "The shoes are everything omg",
  "Where did you get that top?",
  "This is giving me so much inspo",
  "Obsessed with this combo",
  "You always nail it!",
  "The colors work so well together",
  "Need this entire outfit immediately",
  "Okay this is goals",
  "Slay! 💅",
];

async function seed() {
  try {
    console.log('Seeding bot users...');
    const password = await bcrypt.hash('botpassword123', 10);
    const userIds = [];

    // Create users and items
    for (const persona of personas) {
      // Check if user already exists
      const existing = await pool.query('SELECT id FROM users WHERE email = $1', [persona.email]);
      let userId;

      if (existing.rows.length > 0) {
        userId = existing.rows[0].id;
        console.log(`User ${persona.display_name} already exists, skipping...`);
      } else {
        const userResult = await pool.query(
          `INSERT INTO users (email, password_hash, display_name, bio)
           VALUES ($1, $2, $3, $4) RETURNING id`,
          [persona.email, password, persona.display_name, persona.bio]
        );
        userId = userResult.rows[0].id;
        console.log(`Created user: ${persona.display_name}`);
      }

      userIds.push(userId);

      // Add items
      for (const item of persona.items) {
        const existingItem = await pool.query(
          'SELECT id FROM items WHERE user_id = $1 AND name = $2',
          [userId, item.name]
        );
        if (existingItem.rows.length > 0) continue;

        const itemResult = await pool.query(
          `INSERT INTO items (user_id, name, category, brand, image_url, season, occasion)
           VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
          [userId, item.name, item.category, item.brand, item.image_url, item.season, item.occasion]
        );
        const itemId = itemResult.rows[0].id;

        // Add colors
        for (const color of item.colors) {
          await pool.query(
            'INSERT INTO item_colors (item_id, color) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [itemId, color]
          );
        }

        // Add tag
        await pool.query(
          'INSERT INTO item_tags (item_id, tag) VALUES ($1, $2) ON CONFLICT DO NOTHING',
          [itemId, item.occasion]
        );
      }
    }

    // Create outfits and posts for each bot
    console.log('Creating outfits and posts...');
    for (let i = 0; i < userIds.length; i++) {
      const userId = userIds[i];
      const persona = personas[i];

      const userItems = await pool.query(
        'SELECT id, category FROM items WHERE user_id = $1', [userId]
      );
      const items = userItems.rows;

      const top = items.find(item => item.category === 'tops' || item.category === 'dresses');
      const bottom = items.find(item => item.category === 'bottoms');
      const shoes = items.find(item => item.category === 'shoes');

      if (!top) continue;

      // Check if outfit already exists
      const existingOutfit = await pool.query(
        'SELECT id FROM outfits WHERE user_id = $1 LIMIT 1', [userId]
      );
      let outfitId;

      if (existingOutfit.rows.length > 0) {
        outfitId = existingOutfit.rows[0].id;
      } else {
        const outfitResult = await pool.query(
          `INSERT INTO outfits (user_id, name) VALUES ($1, $2) RETURNING id`,
          [userId, `${persona.display_name.split(' ')[0]}'s Signature Look`]
        );
        outfitId = outfitResult.rows[0].id;

        const outfitItems = [top, bottom, shoes].filter(Boolean);
        for (const item of outfitItems) {
          await pool.query(
            'INSERT INTO outfit_items (outfit_id, item_id) VALUES ($1, $2)',
            [outfitId, item.id]
          );
        }
      }

      // Create post
      const existingPost = await pool.query(
        'SELECT id FROM posts WHERE user_id = $1 LIMIT 1', [userId]
      );
      if (existingPost.rows.length === 0) {
        await pool.query(
          `INSERT INTO posts (user_id, outfit_id, caption) VALUES ($1, $2, $3)`,
          [userId, outfitId, outfitCaptions[i % outfitCaptions.length]]
        );
        console.log(`Created post for ${persona.display_name}`);
      }
    }

    // Make bots follow my account and each other
    console.log('Setting up follows...');
    const realUser = await pool.query(
      `SELECT id FROM users WHERE email = 'Brittneymcmullin@gmail.com'`
    );

    if (realUser.rows.length > 0) {
      const realUserId = realUser.rows[0].id;
      for (const botId of userIds) {
        // Bots follow me
        await pool.query(
          `INSERT INTO follows (follower_id, following_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
          [botId, realUserId]
        );
        // I follow bots
        await pool.query(
          `INSERT INTO follows (follower_id, following_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
          [realUserId, botId]
        );
      }
    }

    // Bots follow each other
    for (let i = 0; i < userIds.length; i++) {
      for (let j = 0; j < userIds.length; j++) {
        if (i !== j) {
          await pool.query(
            `INSERT INTO follows (follower_id, following_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
            [userIds[i], userIds[j]]
          );
        }
      }
    }

    // Add likes and comments to all posts
    console.log('Adding likes and comments...');
    const allPosts = await pool.query('SELECT id, user_id FROM posts');

    for (const post of allPosts.rows) {
      // Random bots like each post
      for (const botId of userIds) {
        if (botId !== post.user_id && Math.random() > 0.3) {
          await pool.query(
            `INSERT INTO likes (post_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
            [post.id, botId]
          );
        }
      }

      // Random bots comment
      const numComments = Math.floor(Math.random() * 3);
      for (let c = 0; c < numComments; c++) {
        const commenter = userIds[Math.floor(Math.random() * userIds.length)];
        if (commenter !== post.user_id) {
          const comment = commentTemplates[Math.floor(Math.random() * commentTemplates.length)];
          await pool.query(
            `INSERT INTO comments (post_id, user_id, content) VALUES ($1, $2, $3)`,
            [post.id, commenter, comment]
          );
        }
      }
    }

    console.log(' Seed complete!');
    pool.end();
  } catch (err) {
    console.error('Seed error:', err);
    pool.end();
  }
}

seed();