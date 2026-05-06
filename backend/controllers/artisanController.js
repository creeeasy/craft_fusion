const db = require("../config/db");

// GET /api/artisans/map — all approved artisans with coordinates
exports.getMapArtisans = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT
        u.id, u.name, u.location,
        ap.craft_type, ap.badge, ap.avg_rating,
        ap.total_sales, ap.is_sponsored,
        ap.latitude, ap.longitude
      FROM users u
      JOIN artisan_profiles ap ON ap.user_id = u.id
      WHERE u.role = 'artisan'
        AND u.is_approved = 1
        AND ap.latitude IS NOT NULL
        AND ap.longitude IS NOT NULL
    `);
    res.json({ artisans: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// PATCH /api/artisans/:id/location — artisan updates own location
exports.updateLocation = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    if (!latitude || !longitude)
      return res
        .status(400)
        .json({ message: "latitude and longitude required" });

    await db.query(
      "UPDATE artisan_profiles SET latitude = $1, longitude = $2 WHERE user_id = $3",
      [latitude, longitude, req.user.id],
    );
    res.json({ message: "Location updated" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// PATCH /api/admin/artisans/:id/badge — admin assigns badge manually
exports.assignBadge = async (req, res) => {
  try {
    const { badge } = req.body;
    if (!["new", "silver", "gold"].includes(badge))
      return res
        .status(400)
        .json({ message: "Badge must be: new, silver, or gold" });

    await db.query(
      "UPDATE artisan_profiles SET badge = $1 WHERE user_id = $2",
      [badge, req.params.id],
    );
    res.json({ message: `Badge updated to ${badge}` });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/artisans/:id/reviews — all reviews for an artisan
exports.getReviews = async (req, res) => {
  try {
    const reviewsResult = await db.query(
      `SELECT r.rating, r.comment, r.created_at,
              u.name AS client_name,
              p.title_ar, p.title
       FROM reviews r
       JOIN users u    ON u.id = r.client_id
       JOIN products p ON p.id = r.product_id
       WHERE r.artisan_id = $1
       ORDER BY r.created_at DESC
       LIMIT 20`,
      [req.params.id],
    );
    res.json({ reviews: reviewsResult.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};
