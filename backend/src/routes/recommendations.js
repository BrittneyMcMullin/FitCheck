const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/auth');

const colorPairings = {
  'black': ['white', 'gray', 'red', 'blue', 'green', 'yellow', 'pink', 'beige', 'navy'],
  'white': ['black', 'navy', 'gray', 'blue', 'green', 'red', 'brown', 'beige'],
  'navy': ['white', 'gray', 'beige', 'light blue', 'yellow', 'red'],
  'gray': ['black', 'white', 'navy', 'blue', 'pink', 'red', 'yellow'],
  'beige': ['white', 'black', 'navy', 'brown', 'olive', 'burgundy'],
  'brown': ['beige', 'white', 'olive', 'cream', 'orange', 'navy'],
  'blue': ['white', 'gray', 'beige', 'navy', 'brown', 'black'],
  'red': ['black', 'white', 'gray', 'navy', 'beige'],
  'green': ['white', 'beige', 'brown', 'navy', 'black', 'olive'],
  'olive': ['beige', 'brown', 'white', 'black', 'orange'],
  'pink': ['white', 'gray', 'black', 'navy', 'beige'],
  'yellow': ['navy', 'gray', 'white', 'black', 'brown'],
  'orange': ['navy', 'white', 'brown', 'black', 'olive'],
  'burgundy': ['beige', 'white', 'gray', 'navy', 'black'],
  'purple': ['white', 'gray', 'black', 'beige', 'navy'],
};

const neutralColors = ['black', 'white', 'gray', 'beige', 'navy', 'brown'];

function colorsMatch(colors1, colors2) {
  if (!colors1 || !colors2 || colors1.length === 0 || colors2.length === 0) return true;
  const c1 = colors1.map(c => c.toLowerCase());
  const c2 = colors2.map(c => c.toLowerCase());
  if (c1.some(c => neutralColors.includes(c))) return true;
  if (c2.some(c => neutralColors.includes(c))) return true;
  for (const color of c1) {
    const pairs = colorPairings[color] || [];
    if (c2.some(c => pairs.includes(c))) return true;
  }
  return false;
}

function pickBestColorMatch(anchor, candidates) {
  if (!anchor || !candidates.length) return candidates[0] || null;
  const matched = candidates.filter(c => colorsMatch(anchor.colors, c.colors));
  if (matched.length > 0) {
    return matched.sort((a, b) => {
      if (!a.last_worn) return -1;
      if (!b.last_worn) return 1;
      return new Date(a.last_worn) - new Date(b.last_worn);
    })[0];
  }
  return candidates[0];
}

const shuffle = (arr) => [...arr].sort(() => 0.5 - Math.random());

router.get('/', authMiddleware, async (req, res) => {
  try {
    const { lat, lon } = req.query;
    let weatherCondition = 'mild';
    let temperature = 70;
    let weatherDescription = 'mild';

    if (lat && lon) {
      try {
        const weatherResponse = await fetch(
          `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${process.env.WEATHER_API_KEY}&units=imperial`
        );
        const weatherData = await weatherResponse.json();
        temperature = weatherData.main?.temp || 70;
        weatherDescription = weatherData.weather?.[0]?.description || 'clear';
        if (temperature < 40) weatherCondition = 'cold';
        else if (temperature < 55) weatherCondition = 'cool';
        else if (temperature < 75) weatherCondition = 'mild';
        else weatherCondition = 'warm';
      } catch (weatherErr) {
        console.log('Weather API failed, using defaults');
      }
    }

    const itemsResult = await pool.query(
      `SELECT i.*,
        ARRAY_AGG(DISTINCT ic.color) FILTER (WHERE ic.color IS NOT NULL) as colors,
        ARRAY_AGG(DISTINCT it.tag) FILTER (WHERE it.tag IS NOT NULL) as tags
       FROM items i
       LEFT JOIN item_colors ic ON i.id = ic.item_id
       LEFT JOIN item_tags it ON i.id = it.item_id
       WHERE i.user_id = $1
       GROUP BY i.id`,
      [req.userId]
    );

    const items = itemsResult.rows;

    const seasonMap = {
      cold: ['winter', 'fall', 'all_seasons', 'all seasons'],
      cool: ['fall', 'spring', 'all_seasons', 'all seasons'],
      mild: ['spring', 'fall', 'all_seasons', 'all seasons', 'summer'],
      warm: ['summer', 'spring', 'all_seasons', 'all seasons']
    };
    const preferredSeasons = seasonMap[weatherCondition];

    const getByCategory = (category) =>
      items.filter(i => i.category.toLowerCase() === category.toLowerCase() &&
        (!i.season || preferredSeasons.includes(i.season.toLowerCase()))
      );

    // Shuffle each category so different items appear across occasions
    const allTops = shuffle(getByCategory('Tops'));
    const allBottoms = shuffle(getByCategory('Bottoms'));
    const allShoes = shuffle(getByCategory('Shoes'));
    const allDresses = shuffle(getByCategory('Dresses'));
    const allOuterwear = shuffle(getByCategory('Outerwear'));
    const allAccessories = shuffle(getByCategory('Accessories'));

    const occasions = ['casual', 'work', 'formal', 'athletic', 'party'];
    const occasionLabels = {
      casual: { label: 'Casual Day', icon: '👟' },
      work: { label: 'Work Ready', icon: '💼' },
      formal: { label: 'Formal', icon: '✨' },
      athletic: { label: 'Athletic', icon: '🏃' },
      party: { label: 'Night Out', icon: '🎉' }
    };

    const recommendations = [];

    for (const occasion of occasions) {

      const filterByOccasion = (arr) => {
        const tagged = arr.filter(i =>
          (i.occasion && i.occasion.toLowerCase() === occasion.toLowerCase()) ||
          (i.tags && i.tags.some(t => t.toLowerCase() === occasion.toLowerCase()))
        );
        if (tagged.length > 0) return tagged;

        if (occasion === 'formal' || occasion === 'party') {
          const formal = arr.filter(i =>
            i.occasion?.toLowerCase() !== 'athletic' &&
            !(i.tags || []).some(t => t.toLowerCase() === 'athletic' || t.toLowerCase() === 'sporty')
          );
          return formal.length > 0 ? formal : arr;
        }

        return arr;
      };

      const tops = filterByOccasion(allTops);
      const bottoms = filterByOccasion(allBottoms);
      const shoes = filterByOccasion(allShoes);
      const dresses = filterByOccasion(allDresses);
      const outerwear = filterByOccasion(allOuterwear);
      const accessories = filterByOccasion(allAccessories);

      let outfit = {};
      let anchor = null;

      if (dresses.length > 0 && (occasion === 'formal' || occasion === 'party')) {
        anchor = dresses[0];
        outfit.dress = anchor;
      } else if (tops.length > 0) {
        anchor = tops[0];
        outfit.top = anchor;
        if (bottoms.length > 0) {
          outfit.bottom = pickBestColorMatch(anchor, bottoms);
        }
      }

      if (!anchor) continue;

      if (shoes.length > 0) {
        outfit.shoes = pickBestColorMatch(anchor, shoes);
      }

      if ((weatherCondition === 'cold' || weatherCondition === 'cool') && outerwear.length > 0) {
        outfit.outerwear = pickBestColorMatch(anchor, outerwear);
      }

      if (accessories.length > 0) {
        outfit.accessory = pickBestColorMatch(anchor, accessories);
      }

      if (Object.keys(outfit).length > 0) {
        recommendations.push({
          occasion,
          label: occasionLabels[occasion].label,
          icon: occasionLabels[occasion].icon,
          outfit
        });
      }
    }

    res.json({
      weather: {
        temperature: Math.round(temperature),
        condition: weatherCondition,
        description: weatherDescription
      },
      recommendations
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;