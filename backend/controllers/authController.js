const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const db = require("../config/db");

const generateToken = (user) =>
  jwt.sign(
    { id: user.id, role: user.role, name: user.name },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" },
  );

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { name, email, password, role, phone, location, craft_type, bio } =
      req.body;

    if (!name || !email || !password || !role)
      return res.status(400).json({ message: "Missing required fields" });

    if (!["client", "artisan"].includes(role))
      return res.status(400).json({ message: "Invalid role" });

    // MySQL: const [existing] = await db.query("SELECT id FROM users WHERE email = ?", [email]);
    const existingResult = await db.query(
      "SELECT id FROM users WHERE email = $1",
      [email],
    );
    if (existingResult.rows.length)
      return res.status(409).json({ message: "Email already exists" });

    const hashed = await bcrypt.hash(password, 10);
    const is_approved = role === "client" ? 1 : 0;

    // MySQL: const [result] = await db.query("INSERT INTO users (...) VALUES (?,?,?,?,?,?,?)", [...]);
    const result = await db.query(
      "INSERT INTO users (name, email, password, role, phone, location, is_approved) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id",
      [name, email, hashed, role, phone || null, location || null, is_approved],
    );
    const newUserId = result.rows[0].id;

    if (role === "artisan") {
      await db.query(
        "INSERT INTO artisan_profiles (user_id, craft_type, bio) VALUES ($1,$2,$3)",
        [newUserId, craft_type || null, bio || null],
      );
    }

    const user = { id: newUserId, name, email, role };
    res.status(201).json({
      message:
        role === "artisan"
          ? "Registration submitted, awaiting approval"
          : "Registration successful",
      token: generateToken(user),
      user: { id: user.id, name, email, role, is_approved },
    });
  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ message: "Email and password required" });

    // MySQL: const [rows] = await db.query("SELECT * FROM users WHERE email = ?", [email]);
    const result = await db.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);
    if (!result.rows.length)
      return res.status(401).json({ message: "Invalid credentials" });

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ message: "Invalid credentials" });

    if (user.role === "artisan" && !user.is_approved)
      return res.status(403).json({ message: "Account pending approval" });

    let profile = null;
    if (user.role === "artisan") {
      const profileResult = await db.query(
        "SELECT * FROM artisan_profiles WHERE user_id = $1",
        [user.id],
      );
      profile = profileResult.rows[0] || null;
    }

    res.json({
      token: generateToken(user),
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
        location: user.location,
        is_approved: user.is_approved,
        profile,
      },
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/auth/me
exports.me = async (req, res) => {
  try {
    const result = await db.query(
      "SELECT id, name, email, role, phone, location, avatar, is_approved FROM users WHERE id = $1",
      [req.user.id],
    );
    if (!result.rows.length)
      return res.status(404).json({ message: "User not found" });
    res.json({ user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// PATCH /api/auth/profile
exports.updateProfile = async (req, res) => {
  try {
    const { name, phone, location, bio, craft_type } = req.body;
    await db.query(
      "UPDATE users SET name = $1, phone = $2, location = $3 WHERE id = $4",
      [name, phone || null, location || null, req.user.id],
    );
    if (req.user.role === "artisan") {
      await db.query(
        "UPDATE artisan_profiles SET bio = $1, craft_type = $2 WHERE user_id = $3",
        [bio || null, craft_type || null, req.user.id],
      );
    }
    res.json({ message: "Profile updated" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};
