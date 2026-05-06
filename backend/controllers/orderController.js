const db = require("../config/db");

// POST /api/orders — client places order
exports.create = async (req, res) => {
  try {
    const { product_id, quantity = 1 } = req.body;
    if (!product_id)
      return res.status(400).json({ message: "product_id required" });

    const prodResult = await db.query(
      "SELECT p.*, u.id AS artisan_user_id FROM products p JOIN users u ON p.artisan_id = u.id WHERE p.id = $1 AND p.is_active = 1",
      [product_id],
    );
    if (!prodResult.rows.length)
      return res.status(404).json({ message: "Product not found" });

    const product = prodResult.rows[0];
    if (product.stock < quantity)
      return res.status(400).json({ message: "Insufficient stock" });

    const total = parseFloat(product.price) * quantity;

    const orderResult = await db.query(
      "INSERT INTO orders (client_id, artisan_id, product_id, quantity, total_price) VALUES ($1, $2, $3, $4, $5) RETURNING id",
      [req.user.id, product.artisan_user_id, product_id, quantity, total],
    );
    const orderId = orderResult.rows[0].id;

    await db.query(
      "UPDATE products SET stock = stock - $1, total_orders = total_orders + $2 WHERE id = $3",
      [quantity, quantity, product_id],
    );
    await db.query(
      "UPDATE artisan_profiles SET total_sales = total_sales + $1 WHERE user_id = $2",
      [quantity, product.artisan_user_id],
    );

    res.status(201).json({ message: "Order placed", order_id: orderId, total });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/orders/my — client's orders
exports.myOrders = async (req, res) => {
  try {
    const ordersResult = await db.query(
      `SELECT o.*, p.title, p.image, p.price AS unit_price, u.name AS artisan_name
       FROM orders o
       JOIN products p ON o.product_id = p.id
       JOIN users u ON o.artisan_id = u.id
       WHERE o.client_id = $1 ORDER BY o.created_at DESC`,
      [req.user.id],
    );
    res.json({ orders: ordersResult.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// GET /api/orders/artisan — artisan's incoming orders
exports.artisanOrders = async (req, res) => {
  try {
    const ordersResult = await db.query(
      `SELECT o.*, p.title, p.image, u.name AS client_name, u.phone AS client_phone
       FROM orders o
       JOIN products p ON o.product_id = p.id
       JOIN users u ON o.client_id = u.id
       WHERE o.artisan_id = $1 ORDER BY o.created_at DESC`,
      [req.user.id],
    );
    res.json({ orders: ordersResult.rows });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// PATCH /api/orders/:id/status — artisan updates order status
exports.updateStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const allowed = ["confirmed", "shipped", "delivered", "cancelled"];
    if (!allowed.includes(status))
      return res.status(400).json({ message: "Invalid status" });

    const orderResult = await db.query(
      "SELECT artisan_id FROM orders WHERE id = $1",
      [req.params.id],
    );
    if (!orderResult.rows.length)
      return res.status(404).json({ message: "Order not found" });
    if (orderResult.rows[0].artisan_id !== req.user.id)
      return res.status(403).json({ message: "Not your order" });

    await db.query("UPDATE orders SET status = $1 WHERE id = $2", [
      status,
      req.params.id,
    ]);
    res.json({ message: "Order status updated" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// POST /api/orders/:id/review
exports.review = async (req, res) => {
  try {
    const { rating, comment } = req.body;
    if (!rating || rating < 1 || rating > 5)
      return res.status(400).json({ message: "Rating 1-5 required" });

    const orderResult = await db.query(
      "SELECT * FROM orders WHERE id = $1 AND client_id = $2 AND status = $3",
      [req.params.id, req.user.id, "delivered"],
    );
    if (!orderResult.rows.length)
      return res
        .status(400)
        .json({ message: "Order not delivered or not yours" });
    const order = orderResult.rows[0];

    await db.query(
      "INSERT INTO reviews (order_id, client_id, artisan_id, product_id, rating, comment) VALUES ($1, $2, $3, $4, $5, $6)",
      [
        order.id,
        req.user.id,
        order.artisan_id,
        order.product_id,
        rating,
        comment || null,
      ],
    );

    // Recalculate avg rating
    const avgResult = await db.query(
      "SELECT AVG(rating) AS avg FROM reviews WHERE artisan_id = $1",
      [order.artisan_id],
    );
    const newAvg = parseFloat(avgResult.rows[0].avg).toFixed(2);
    await db.query(
      "UPDATE artisan_profiles SET avg_rating = $1 WHERE user_id = $2",
      [newAvg, order.artisan_id],
    );

    // Auto-assign badge
    if (newAvg >= 4.5) {
      await db.query(
        "UPDATE artisan_profiles SET badge = $1 WHERE user_id = $2",
        ["gold", order.artisan_id],
      );
    } else if (newAvg >= 3.5) {
      await db.query(
        "UPDATE artisan_profiles SET badge = $1 WHERE user_id = $2",
        ["silver", order.artisan_id],
      );
    }

    res.status(201).json({ message: "Review submitted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// POST /api/orders/:id/cancel — client cancels own pending order
exports.cancel = async (req, res) => {
  try {
    const orderResult = await db.query(
      "SELECT * FROM orders WHERE id = $1 AND client_id = $2",
      [req.params.id, req.user.id],
    );

    if (!orderResult.rows.length) {
      return res.status(404).json({ message: "Order not found" });
    }

    const order = orderResult.rows[0];
    if (order.status !== "pending") {
      return res
        .status(400)
        .json({ message: "Only pending orders can be cancelled" });
    }

    await db.query("UPDATE orders SET status = $1 WHERE id = $2", [
      "cancelled",
      req.params.id,
    ]);

    // Restore stock
    await db.query("UPDATE products SET stock = stock + $1 WHERE id = $2", [
      order.quantity,
      order.product_id,
    ]);

    res.json({ message: "Order cancelled" });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};
