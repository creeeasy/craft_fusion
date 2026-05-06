const db = require("../config/db");

// GET /api/products — browse all (with filters, sorting)
exports.getAll = async (req, res) => {
  try {
    const { category, sort, search, sponsored, artisan } = req.query;
    let query = `
      SELECT p.*, u.name AS artisan_name, u.location,
             ap.badge, ap.avg_rating, ap.is_sponsored, ap.bio,
             c.name AS category_name, c.name_ar AS category_name_ar, c.icon
      FROM products p
      JOIN users u ON p.artisan_id = u.id
      JOIN artisan_profiles ap ON ap.user_id = u.id
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.is_active = 1 AND u.is_approved = 1
    `;
    const params = [];

    if (category) {
      query += ` AND p.category_id = $${params.length + 1}`;
      params.push(category);
    }
    if (search) {
      query += ` AND (p.title ILIKE $${params.length + 1} OR p.title_ar ILIKE $${params.length + 2})`;
      params.push(`%${search}%`, `%${search}%`);
    }
    if (sponsored === "true") {
      query += ` AND ap.is_sponsored = 1`;
    }
    if (artisan) {
      query += ` AND p.artisan_id = $${params.length + 1}`;
      params.push(artisan);
    }

    // Sponsored always first, then sort
    query += " ORDER BY ap.is_sponsored DESC";
    if (sort === "rating") query += ", ap.avg_rating DESC";
    else if (sort === "popular") query += ", p.total_orders DESC";
    else if (sort === "price_asc") query += ", p.price ASC";
    else if (sort === "price_desc") query += ", p.price DESC";
    else query += ", p.created_at DESC";

    const result = await db.query(query, params);
    res.json({ products: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/products/:id
exports.getOne = async (req, res) => {
  try {
    const productResult = await db.query(
      `SELECT p.*, u.name AS artisan_name, u.location, u.avatar AS artisan_avatar,
              ap.badge, ap.avg_rating, ap.is_sponsored, ap.bio,
              c.name AS category_name, c.icon
       FROM products p
       JOIN users u ON p.artisan_id = u.id
       JOIN artisan_profiles ap ON ap.user_id = u.id
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.id = $1 AND p.is_active = 1`,
      [req.params.id],
    );
    if (!productResult.rows.length)
      return res.status(404).json({ message: "Product not found" });

    const reviewsResult = await db.query(
      `SELECT r.rating, r.comment, r.created_at, u.name AS client_name
       FROM reviews r JOIN users u ON r.client_id = u.id
       WHERE r.product_id = $1 ORDER BY r.created_at DESC LIMIT 10`,
      [req.params.id],
    );

    res.json({ product: productResult.rows[0], reviews: reviewsResult.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/products/categories
exports.getCategories = async (req, res) => {
  try {
    const categoriesResult = await db.query("SELECT * FROM categories");
    res.json({ categories: categoriesResult.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// POST /api/products — artisan creates listing
exports.create = async (req, res) => {
  try {
    const { title, title_ar, description, price, stock, category_id } =
      req.body;
    if (!title || !price)
      return res.status(400).json({ message: "Title and price required" });

    const image = req.file ? `/uploads/${req.file.filename}` : null;
    const result = await db.query(
      "INSERT INTO products (artisan_id, category_id, title, title_ar, description, price, stock, image) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id",
      [
        req.user.id,
        category_id || null,
        title,
        title_ar || null,
        description || null,
        price,
        stock || 1,
        image,
      ],
    );
    res
      .status(201)
      .json({ message: "Product created", product_id: result.rows[0].id });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// PUT /api/products/:id — artisan updates own listing
exports.update = async (req, res) => {
  try {
    const productResult = await db.query(
      "SELECT artisan_id FROM products WHERE id = $1",
      [req.params.id],
    );
    if (!productResult.rows.length)
      return res.status(404).json({ message: "Product not found" });
    if (productResult.rows[0].artisan_id !== req.user.id)
      return res.status(403).json({ message: "Not your product" });

    const {
      title,
      title_ar,
      description,
      price,
      stock,
      category_id,
      is_active,
    } = req.body;
    await db.query(
      "UPDATE products SET title=$1, title_ar=$2, description=$3, price=$4, stock=$5, category_id=$6, is_active=$7 WHERE id=$8",
      [
        title,
        title_ar,
        description,
        price,
        stock,
        category_id,
        is_active ?? 1,
        req.params.id,
      ],
    );
    res.json({ message: "Product updated" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/products/my — artisan's own listings
exports.myListings = async (req, res) => {
  try {
    const productsResult = await db.query(
      "SELECT p.*, c.name AS category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id WHERE p.artisan_id = $1 ORDER BY p.created_at DESC",
      [req.user.id],
    );
    res.json({ products: productsResult.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};
