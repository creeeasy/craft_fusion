const db = require("../config/db");

// GET /api/admin/dashboard
exports.dashboard = async (req, res) => {
  try {
    // PostgreSQL uses double quotes for identifiers, but for strings use single quotes
    const totalUsersResult = await db.query(
      "SELECT COUNT(*) AS total_users FROM users WHERE role != $1",
      ["admin"],
    );
    const total_users = parseInt(totalUsersResult.rows[0].total_users);

    const totalArtisansResult = await db.query(
      "SELECT COUNT(*) AS total_artisans FROM users WHERE role = $1",
      ["artisan"],
    );
    const total_artisans = parseInt(totalArtisansResult.rows[0].total_artisans);

    const pendingArtisansResult = await db.query(
      "SELECT COUNT(*) AS pending_artisans FROM users WHERE role = $1 AND is_approved = 0",
      ["artisan"],
    );
    const pending_artisans = parseInt(
      pendingArtisansResult.rows[0].pending_artisans,
    );

    const totalOrdersResult = await db.query(
      "SELECT COUNT(*) AS total_orders FROM orders",
    );
    const total_orders = parseInt(totalOrdersResult.rows[0].total_orders);

    const revenueResult = await db.query(
      "SELECT COALESCE(SUM(total_price * 0.05), 0) AS revenue FROM orders WHERE status = $1",
      ["delivered"],
    );
    const revenue = parseFloat(revenueResult.rows[0].revenue);

    const pendingSponsorshipsResult = await db.query(
      "SELECT COUNT(*) AS pending_sponsorships FROM sponsorships WHERE status = $1",
      ["pending"],
    );
    const pending_sponsorships = parseInt(
      pendingSponsorshipsResult.rows[0].pending_sponsorships,
    );

    res.json({
      total_users,
      total_artisans,
      pending_artisans,
      total_orders,
      revenue,
      pending_sponsorships,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/admin/artisans?approved=0
exports.getArtisans = async (req, res) => {
  try {
    const { approved } = req.query;
    let query = `
      SELECT u.id, u.name, u.email, u.phone, u.location, u.is_approved, u.created_at,
             ap.craft_type, ap.badge, ap.avg_rating, ap.total_sales
      FROM users u 
      JOIN artisan_profiles ap ON ap.user_id = u.id 
      WHERE u.role = $1
    `;
    const params = ["artisan"];

    if (approved !== undefined) {
      query += " AND u.is_approved = $" + (params.length + 1);
      params.push(approved);
    }
    query += " ORDER BY u.created_at DESC";

    const result = await db.query(query, params);
    res.json({ artisans: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// PATCH /api/admin/artisans/:id/approve
exports.approveArtisan = async (req, res) => {
  try {
    const { approve } = req.body;
    await db.query(
      "UPDATE users SET is_approved = $1 WHERE id = $2 AND role = $3",
      [approve ? 1 : 0, req.params.id, "artisan"],
    );
    res.json({ message: approve ? "Artisan approved" : "Artisan rejected" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/admin/sponsorships
exports.getSponsorships = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT s.*, u.name AS artisan_name, u.email,
              p.title_ar AS product_title
       FROM sponsorships s
       JOIN users u ON s.artisan_id = u.id
       LEFT JOIN products p ON p.id = s.product_id
       ORDER BY
         CASE s.status WHEN 'pending' THEN 1 ELSE 2 END,
         s.requested_at DESC`,
    );
    res.json({ sponsorships: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// PATCH /api/admin/sponsorships/:id
exports.reviewSponsorship = async (req, res) => {
  try {
    const { status, reject_reason } = req.body;
    if (!["approved", "rejected"].includes(status))
      return res.status(400).json({ message: "Invalid status" });

    const result = await db.query("SELECT * FROM sponsorships WHERE id = $1", [
      req.params.id,
    ]);
    if (!result.rows.length)
      return res.status(404).json({ message: "Not found" });
    const sp = result.rows[0];

    await db.query(
      "UPDATE sponsorships SET status = $1, reviewed_at = CURRENT_TIMESTAMP, reviewed_by = $2, reject_reason = $3 WHERE id = $4",
      [status, req.user.id, reject_reason || null, req.params.id],
    );

    if (status === "approved") {
      const until = new Date();
      until.setDate(until.getDate() + sp.duration_days);
      await db.query(
        "UPDATE artisan_profiles SET is_sponsored = 1, sponsored_until = $1 WHERE user_id = $2",
        [until, sp.artisan_id],
      );
    }

    res.json({ message: `Sponsorship ${status}` });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/admin/revenue
exports.revenue = async (req, res) => {
  try {
    // PostgreSQL uses TO_CHAR for date formatting instead of DATE_FORMAT
    const monthlyResult = await db.query(
      `SELECT TO_CHAR(created_at, 'YYYY-MM') AS month,
              COUNT(*) AS orders,
              SUM(total_price) AS gross,
              SUM(total_price * 0.05) AS commission
       FROM orders 
       WHERE status = $1
       GROUP BY month 
       ORDER BY month DESC 
       LIMIT 12`,
      ["delivered"],
    );

    const sponsorshipRevenueResult = await db.query(
      "SELECT COALESCE(SUM(amount), 0) AS total FROM sponsorships WHERE status = $1",
      ["approved"],
    );

    res.json({
      monthly: monthlyResult.rows,
      sponsorship_revenue:
        parseFloat(sponsorshipRevenueResult.rows[0].total) || 0,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// PATCH /api/admin/products/:id/toggle — admin deactivates/activates any product
exports.toggleProduct = async (req, res) => {
  try {
    const { is_active } = req.body;
    await db.query("UPDATE products SET is_active = $1 WHERE id = $2", [
      is_active,
      req.params.id,
    ]);
    res.json({
      message: is_active ? "Product activated" : "Product deactivated",
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};
