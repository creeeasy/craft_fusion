const db = require("../config/db");

const PACKAGES = {
  bronze: { days: 7, price: 1000 },
  silver: { days: 14, price: 2500 },
  gold: { days: 30, price: 5000 },
};

// POST /api/sponsorships/request — artisan submits with photos
exports.request = async (req, res) => {
  try {
    const { promo_title, promo_message, product_id, package: pkg } = req.body;

    if (!pkg || !PACKAGES[pkg])
      return res
        .status(400)
        .json({ message: "Invalid package. Choose: bronze, silver, gold" });
    if (!promo_title)
      return res.status(400).json({ message: "promo_title is required" });

    const existingResult = await db.query(
      "SELECT id FROM sponsorships WHERE artisan_id = $1 AND status = $2",
      [req.user.id, "pending"],
    );
    if (existingResult.rows.length)
      return res
        .status(409)
        .json({ message: "لديك طلب ترويج قيد المراجعة بالفعل" });

    const { days, price } = PACKAGES[pkg];

    const photo_1 = req.files?.[0] ? `/uploads/${req.files[0].filename}` : null;
    const photo_2 = req.files?.[1] ? `/uploads/${req.files[1].filename}` : null;
    const photo_3 = req.files?.[2] ? `/uploads/${req.files[2].filename}` : null;

    const result = await db.query(
      `INSERT INTO sponsorships
        (artisan_id, duration_days, amount, package, promo_title, promo_message, product_id, photo_1, photo_2, photo_3)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id`,
      [
        req.user.id,
        days,
        price,
        pkg,
        promo_title,
        promo_message || null,
        product_id || null,
        photo_1,
        photo_2,
        photo_3,
      ],
    );

    res.status(201).json({
      message: "تم إرسال طلب الترويج بنجاح، سيتم مراجعته خلال 24 ساعة",
      amount: price,
      duration_days: days,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/sponsorships/my — artisan's own history
exports.my = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT s.*, p.title_ar, p.title AS product_title
       FROM sponsorships s
       LEFT JOIN products p ON p.id = s.product_id
       WHERE s.artisan_id = $1
       ORDER BY s.requested_at DESC`,
      [req.user.id],
    );
    res.json({ sponsorships: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/sponsorships/active — public: for home screen banner
exports.getActive = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT s.promo_title, s.promo_message,
              s.photo_1, s.photo_2, s.photo_3,
              s.package, s.artisan_id,
              u.name AS artisan_name, u.location,
              ap.badge, ap.avg_rating, ap.craft_type,
              p.id AS product_id, p.title_ar AS product_title, p.price
       FROM sponsorships s
       JOIN users u             ON u.id = s.artisan_id
       JOIN artisan_profiles ap ON ap.user_id = s.artisan_id
       LEFT JOIN products p     ON p.id = s.product_id
       WHERE s.status = 'approved'
         AND ap.is_sponsored = 1
         AND (ap.sponsored_until IS NULL OR ap.sponsored_until > CURRENT_TIMESTAMP)
       ORDER BY
         CASE s.package WHEN 'gold' THEN 1 WHEN 'silver' THEN 2 ELSE 3 END,
         s.reviewed_at DESC`,
    );
    res.json({ sponsored: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};
