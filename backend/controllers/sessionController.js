const db = require("../config/db");

// GET /api/sessions - Public: List available sessions for clients
exports.getAll = async (req, res) => {
  try {
    const { category, sort } = req.query;
    let query = `
      SELECT s.*, 
              u.name AS artisan_name, 
              u.avatar AS artisan_avatar, 
              ap.badge, 
              ap.avg_rating,
              c.name AS category_name,
              c.name_ar AS category_name_ar,
              c.icon AS category_icon,
              (SELECT COUNT(*) FROM session_bookings sb 
               WHERE sb.session_id = s.id AND sb.status = 'booked') AS booked_count,
              (SELECT AVG(rating) FROM session_bookings sb2 
               WHERE sb2.session_id = s.id AND sb2.rating IS NOT NULL) AS avg_rating
       FROM sessions s
       JOIN users u ON s.artisan_id = u.id
       JOIN artisan_profiles ap ON ap.user_id = u.id
       LEFT JOIN categories c ON s.category_id = c.id
       WHERE s.is_active = 1 
         AND s.scheduled_at > CURRENT_TIMESTAMP
    `;

    const params = [];

    if (category) {
      query += ` AND s.category_id = $${params.length + 1}`;
      params.push(category);
    }

    query += " ORDER BY ";

    if (sort === "rating") {
      query += "avg_rating DESC NULLS LAST";
    } else if (sort === "price_asc") {
      query += "s.price ASC";
    } else if (sort === "price_desc") {
      query += "s.price DESC";
    } else {
      query += "s.scheduled_at ASC";
    }

    const result = await db.query(query, params);
    res.json({ sessions: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/sessions/my - Artisan: Get own sessions with booking count
exports.getMy = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT s.*,
        c.name AS category_name,
        (SELECT COUNT(*) 
         FROM session_bookings sb
         WHERE sb.session_id = s.id 
           AND sb.status = 'booked') AS booked_count,
        (SELECT COUNT(*) 
         FROM session_bookings sb2
         WHERE sb2.session_id = s.id 
           AND sb2.status = 'booked' 
           AND sb2.rating IS NOT NULL) AS rated_count
       FROM sessions s
       LEFT JOIN categories c ON s.category_id = c.id
       WHERE s.artisan_id = $1
       ORDER BY s.scheduled_at DESC`,
      [req.user.id],
    );
    res.json({ sessions: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};

// GET /api/sessions/my-bookings - Client: Get client's booked sessions
exports.getMyBookings = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT sb.*, 
              s.id AS session_id, 
              s.title, 
              s.description, 
              s.price, 
              s.duration_minutes, 
              s.scheduled_at, 
              s.is_active,
              s.image_url,
              u.id AS artisan_id, 
              u.name AS artisan_name, 
              u.avatar AS artisan_avatar,
              ap.badge,
              ap.avg_rating AS artisan_rating,
              c.name AS category_name,
              c.icon AS category_icon
       FROM session_bookings sb
       JOIN sessions s ON s.id = sb.session_id
       JOIN users u ON u.id = s.artisan_id
       JOIN artisan_profiles ap ON ap.user_id = u.id
       LEFT JOIN categories c ON s.category_id = c.id
       WHERE sb.client_id = $1 
         AND sb.status = 'booked'
       ORDER BY sb.created_at DESC`,
      [req.user.id],
    );
    res.json({ bookings: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};

// POST /api/sessions - Artisan: Create new session
exports.create = async (req, res) => {
  try {
    const {
      title,
      description,
      price,
      duration_minutes,
      max_participants,
      scheduled_at,
      category_id,
    } = req.body;

    if (!title || !price || !scheduled_at) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const image_url = req.file ? `/uploads/${req.file.filename}` : null;

    const result = await db.query(
      `INSERT INTO sessions 
       (artisan_id, category_id, title, description, price, duration_minutes, max_participants, scheduled_at, image_url) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`,
      [
        req.user.id,
        category_id || null,
        title,
        description || null,
        price,
        duration_minutes || 60,
        max_participants || 5,
        scheduled_at,
        image_url,
      ],
    );

    res.status(201).json({
      message: "Session created successfully",
      session_id: result.rows[0].id,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// POST /api/sessions/:id/book - Client: Book a session
exports.book = async (req, res) => {
  try {
    const sessionResult = await db.query(
      `SELECT * FROM sessions 
       WHERE id = $1 AND is_active = 1 AND scheduled_at > CURRENT_TIMESTAMP`,
      [req.params.id],
    );

    if (!sessionResult.rows.length) {
      return res.status(404).json({ message: "Session not found or expired" });
    }

    const session = sessionResult.rows[0];

    const existingResult = await db.query(
      `SELECT id FROM session_bookings 
       WHERE session_id = $1 AND client_id = $2 AND status = 'booked'`,
      [req.params.id, req.user.id],
    );

    if (existingResult.rows.length) {
      return res
        .status(409)
        .json({ message: "You already booked this session" });
    }

    const countResult = await db.query(
      `SELECT COUNT(*) AS count 
       FROM session_bookings 
       WHERE session_id = $1 AND status = 'booked'`,
      [req.params.id],
    );

    const count = parseInt(countResult.rows[0].count);

    if (count >= session.max_participants) {
      return res.status(400).json({ message: "Session is full" });
    }

    await db.query(
      `INSERT INTO session_bookings (session_id, client_id, status) 
       VALUES ($1, $2, 'booked')`,
      [req.params.id, req.user.id],
    );

    res.status(201).json({
      message: "Session booked successfully",
      total: session.price,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// POST /api/sessions/:id/rate - Client: Rate a session
exports.rateSession = async (req, res) => {
  try {
    const { rating, review } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res
        .status(400)
        .json({ message: "Rating must be between 1 and 5" });
    }

    const bookingResult = await db.query(
      `SELECT sb.*, s.scheduled_at 
       FROM session_bookings sb
       JOIN sessions s ON s.id = sb.session_id
       WHERE sb.session_id = $1 AND sb.client_id = $2 AND sb.status = 'booked'`,
      [req.params.id, req.user.id],
    );

    if (!bookingResult.rows.length) {
      return res.status(404).json({ message: "Booking not found" });
    }

    const booking = bookingResult.rows[0];

    if (new Date(booking.scheduled_at) > new Date()) {
      return res
        .status(400)
        .json({ message: "Cannot rate session before it occurs" });
    }

    if (booking.rating) {
      return res.status(400).json({ message: "Already rated this session" });
    }

    await db.query(
      `UPDATE session_bookings 
       SET rating = $1, review = $2, rated_at = CURRENT_TIMESTAMP
       WHERE session_id = $3 AND client_id = $4`,
      [rating, review || null, req.params.id, req.user.id],
    );

    res.json({ message: "Session rated successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};

// DELETE /api/sessions/:id/cancel - Client: Cancel booking
exports.cancelBooking = async (req, res) => {
  try {
    const bookingResult = await db.query(
      `SELECT sb.*, s.scheduled_at 
       FROM session_bookings sb
       JOIN sessions s ON s.id = sb.session_id
       WHERE sb.session_id = $1 AND sb.client_id = $2 AND sb.status = 'booked'`,
      [req.params.id, req.user.id],
    );

    if (!bookingResult.rows.length) {
      return res.status(404).json({ message: "Booking not found" });
    }

    const booking = bookingResult.rows[0];

    if (new Date(booking.scheduled_at) < new Date()) {
      return res.status(400).json({ message: "Cannot cancel past sessions" });
    }

    await db.query(
      `UPDATE session_bookings 
       SET status = 'cancelled' 
       WHERE session_id = $1 AND client_id = $2`,
      [req.params.id, req.user.id],
    );

    res.json({ message: "Booking cancelled successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};

// PATCH /api/sessions/:id - Artisan: Toggle session active status
exports.toggleActive = async (req, res) => {
  try {
    const { is_active } = req.body;

    const sessionResult = await db.query(
      "SELECT artisan_id FROM sessions WHERE id = $1",
      [req.params.id],
    );

    if (!sessionResult.rows.length) {
      return res.status(404).json({ message: "Session not found" });
    }

    if (sessionResult.rows[0].artisan_id !== req.user.id) {
      return res.status(403).json({ message: "Not your session" });
    }

    await db.query("UPDATE sessions SET is_active = $1 WHERE id = $2", [
      is_active,
      req.params.id,
    ]);

    res.json({ message: "Session updated successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};

// GET /api/sessions/upcoming - Client: Get upcoming booked sessions for home widget
exports.getUpcomingBookings = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT sb.*, 
              s.id AS session_id, 
              s.title, 
              s.scheduled_at, 
              s.duration_minutes,
              s.image_url,
              u.name AS artisan_name
       FROM session_bookings sb
       JOIN sessions s ON s.id = sb.session_id
       JOIN users u ON u.id = s.artisan_id
       WHERE sb.client_id = $1 
         AND sb.status = 'booked'
         AND s.scheduled_at > CURRENT_TIMESTAMP
       ORDER BY s.scheduled_at ASC
       LIMIT 3`,
      [req.user.id],
    );
    res.json({ upcoming: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};
