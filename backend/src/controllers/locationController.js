import { query } from '../config/db.js';

const CATEGORIES = [
  'lecture_hall', 'library', 'laboratory',
  'cafeteria', 'office', 'hostel', 'other',
];

function shape(row) {
  return {
    locationId: row.location_id,
    name: row.name,
    category: row.category,
    description: row.description,
    latitude: Number(row.latitude),
    longitude: Number(row.longitude),
  };
}

/**
 * GET /api/locations?category=library&search=balme
 * Backs the campus map's search bar and category filter (Module 6).
 */
export async function listLocations(req, res, next) {
  const { category, search } = req.query;

  if (category && !CATEGORIES.includes(category)) {
    return res.status(400).json({
      error: `category must be one of: ${CATEGORIES.join(', ')}`,
    });
  }

  try {
    const { rows } = await query(
      `SELECT location_id, name, category, description, latitude, longitude
         FROM locations
        WHERE ($1::text IS NULL OR category = $1)
          AND ($2::text IS NULL OR name ILIKE '%' || $2 || '%')
        ORDER BY name`,
      [category ?? null, search ?? null]
    );

    return res.json({ locations: rows.map(shape) });
  } catch (err) {
    return next(err);
  }
}

/** GET /api/locations/categories - lets the app build its filter chips. */
export function listCategories(_req, res) {
  res.json({ categories: CATEGORIES });
}
