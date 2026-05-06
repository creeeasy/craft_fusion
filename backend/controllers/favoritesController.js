const db = require("../config/db");

// GET /api/favorites — client's saved products
exports.getAll = async (req, res) => {
  try {
    const result = await db.query(
      `
      SELECT p.*, u.name AS artisan_name, u.location,
             ap.badge, ap.avg_rating, ap.is_sponsored,
             c.name AS category_name, c.icon
      FROM favorites f
      JOIN products p          ON p.id = f.product_id
      JOIN users u             ON u.id = p.artisan_id
      JOIN artisan_profiles ap ON ap.user_id = u.id
      LEFT JOIN categories c   ON c.id = p.category_id
      WHERE f.user_id = $1 AND p.is_active = 1
      ORDER BY f.created_at DESC
    `,
      [req.user.id],
    );
    res.json({ favorites: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// POST /api/favorites/:productId — toggle add/remove
exports.toggle = async (req, res) => {
  try {
    const { productId } = req.params;
    const existingResult = await db.query(
      "SELECT id FROM favorites WHERE user_id = $1 AND product_id = $2",
      [req.user.id, productId],
    );

    if (existingResult.rows.length) {
      await db.query(
        "DELETE FROM favorites WHERE user_id = $1 AND product_id = $2",
        [req.user.id, productId],
      );
      return res.json({ saved: false, message: "Removed from favorites" });
    }

    await db.query(
      "INSERT INTO favorites (user_id, product_id) VALUES ($1, $2)",
      [req.user.id, productId],
    );
    res.json({ saved: true, message: "Added to favorites" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/favorites/ids — just IDs for fast UI state on startup
exports.getIds = async (req, res) => {
  try {
    const result = await db.query(
      "SELECT product_id FROM favorites WHERE user_id = $1",
      [req.user.id],
    );
    res.json({ ids: result.rows.map((r) => r.product_id) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};
