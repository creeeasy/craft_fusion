require("dotenv").config();
const bcrypt = require("bcryptjs");
const db = require("./db");

async function seed() {
  console.log("🌱 Seeding database...");

  try {
    const password = await bcrypt.hash("password123", 10);

    // ============================================
    // 1. USERS
    // ============================================
    console.log("📝 Creating users...");
    await db.query(
      `
      INSERT INTO users (name, email, password, role, phone, location, is_approved) VALUES
      ('Admin', 'admin@naamaya.dz', $1, 'admin', NULL, NULL, 1),
      ('أمينة بن علي', 'amina@test.com', $1, 'artisan', '0551234567', 'تلمسان', 1),
      ('سارة معروف', 'sara@test.com', $1, 'artisan', '0662345678', 'وهران', 1),
      ('نور الدين قاسم', 'nour@test.com', $1, 'artisan', '0773456789', 'الجزائر', 1),
      ('ليلى حداد', 'leila@test.com', $1, 'artisan', '0664567890', 'قسنطينة', 1),
      ('يوسف بوزيد', 'youssef@test.com', $1, 'artisan', '0555678901', 'سطيف', 0),
      ('كريم العربي', 'karim@test.com', $1, 'client', '0661234567', 'تلمسان', 1),
      ('نادية سعيد', 'nadia@test.com', $1, 'client', '0772345678', 'وهران', 1)
      ON CONFLICT (email) DO NOTHING
    `,
      [password],
    );

    // Get user IDs
    const usersResult = await db.query(`SELECT id, email FROM users`);
    const getUserByEmail = (email) =>
      usersResult.rows.find((u) => u.email === email)?.id;

    const aminaId = getUserByEmail("amina@test.com");
    const saraId = getUserByEmail("sara@test.com");
    const nourId = getUserByEmail("nour@test.com");
    const leilaId = getUserByEmail("leila@test.com");
    const youssefId = getUserByEmail("youssef@test.com");
    const karimId = getUserByEmail("karim@test.com");
    const nadiaId = getUserByEmail("nadia@test.com");

    // Get category IDs
    const categoriesResult = await db.query(`SELECT id, name FROM categories`);
    const getCategoryId = (name) =>
      categoriesResult.rows.find((c) => c.name === name)?.id;

    const potteryId = getCategoryId("Pottery");
    const candlesId = getCategoryId("Candles");
    const flowersId = getCategoryId("Handmade Flowers");
    const mirrorId = getCategoryId("Mirror Design");

    // ============================================
    // 2. ARTISAN PROFILES
    // ============================================
    console.log("👨‍🎨 Creating artisan profiles...");

    const artisanProfiles = [
      [
        aminaId,
        "فخار وخزف",
        "حرفية متخصصة في الفخار التقليدي التلمساني منذ 15 سنة",
        "gold",
        4.9,
        87,
        1,
        34.8828,
        -1.3167,
      ],
      [
        saraId,
        "شموع عطرية",
        "أصنع شموع طبيعية بعطور مستوحاة من الطبيعة الجزائرية",
        "silver",
        4.6,
        43,
        0,
        35.6969,
        -0.6331,
      ],
      [
        nourId,
        "ورود يدوية",
        "أصنع باقات ورود يدوية للمناسبات والزينة",
        "new",
        4.4,
        12,
        0,
        36.7525,
        3.042,
      ],
      [
        leilaId,
        "تصميم مرايا",
        "مصممة مرايا فنية مزخرفة بأسلوب مزيج بين التراث والحداثة",
        "gold",
        5.0,
        61,
        1,
        36.365,
        6.6147,
      ],
      [
        youssefId,
        "نسيج تقليدي",
        "حرفي في النسيج التقليدي",
        "new",
        0.0,
        0,
        0,
        36.275,
        5.7367,
      ],
    ];

    for (const profile of artisanProfiles) {
      if (profile[0]) {
        await db.query(
          `
          INSERT INTO artisan_profiles (user_id, craft_type, bio, badge, avg_rating, total_sales, is_sponsored, latitude, longitude) 
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          ON CONFLICT (user_id) DO NOTHING
        `,
          profile,
        );
      }
    }

    // ============================================
    // 3. PRODUCTS
    // ============================================
    console.log("📦 Creating products...");

    const products = [
      [
        aminaId,
        potteryId,
        "Traditional Pottery Jug",
        "إبريق فخاري تقليدي",
        "إبريق مصنوع يدوياً من طين تلمسان",
        1200,
        8,
        1,
        34,
      ],
      [
        aminaId,
        potteryId,
        "Ceramic Bowl Set",
        "طقم أوعية خزفية",
        "طقم من 3 أوعية خزفية",
        2800,
        4,
        1,
        18,
      ],
      [
        aminaId,
        potteryId,
        "Clay Water Jar",
        "جرة طين للماء",
        "جرة تقليدية تحافظ على برودة الماء",
        850,
        6,
        1,
        22,
      ],
      [
        saraId,
        candlesId,
        "Lavender Scented Candle",
        "شمعة لافندر عطرية",
        "شمعة طبيعية من شمع النحل",
        450,
        20,
        1,
        15,
      ],
      [
        saraId,
        candlesId,
        "Rose & Oud Candle Set",
        "طقم شموع ورد وعود",
        "طقم من 3 شموع",
        950,
        12,
        1,
        9,
      ],
      [
        saraId,
        candlesId,
        "Cinnamon Candle",
        "شمعة القرفة والبرتقال",
        "شمعة دافئة بعطر القرفة",
        380,
        15,
        1,
        7,
      ],
      [
        nourId,
        flowersId,
        "Wedding Flower Bouquet",
        "باقة زهور عرس يدوية",
        "باقة ورود يدوية فاخرة للأعراس",
        800,
        10,
        1,
        5,
      ],
      [
        nourId,
        flowersId,
        "Home Decor Flowers",
        "زهور ديكور منزلي",
        "ترتيب زهور يدوية للديكور المنزلي",
        550,
        7,
        1,
        4,
      ],
      [
        leilaId,
        mirrorId,
        "Decorative Mirror",
        "مرآة مزخرفة يدوياً",
        "مرآة فنية مزخرفة بنقوش إسلامية",
        2500,
        3,
        1,
        21,
      ],
      [
        leilaId,
        mirrorId,
        "Small Ornamental Mirror",
        "مرآة صغيرة للزينة",
        "مرآة صغيرة أنيقة للزينة",
        950,
        8,
        1,
        14,
      ],
      [
        leilaId,
        mirrorId,
        "Mirror with Carved Frame",
        "مرآة بإطار منحوت",
        "مرآة بإطار خشبي منحوت",
        3200,
        2,
        1,
        8,
      ],
      [
        aminaId,
        potteryId,
        "Pottery Flower Vase",
        "مزهرية فخارية",
        "مزهرية أنيقة مصنوعة يدوياً",
        680,
        10,
        1,
        11,
      ],
    ];

    for (const product of products) {
      if (product[0] && product[1]) {
        await db.query(
          `
          INSERT INTO products (artisan_id, category_id, title, title_ar, description, price, stock, is_active, total_orders) 
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        `,
          product,
        );
      }
    }

    // Get product IDs
    const productTitles = [
      "Traditional Pottery Jug",
      "Clay Water Jar",
      "Lavender Scented Candle",
      "Decorative Mirror",
    ];
    const productsResult = await db.query(
      `SELECT id, title FROM products WHERE title = ANY($1::text[])`,
      [productTitles],
    );
    const productMap = {};
    productsResult.rows.forEach((p) => {
      productMap[p.title] = p.id;
    });

    // ============================================
    // 4. ORDERS
    // ============================================
    console.log("📋 Creating orders...");

    const orders = [
      [
        karimId,
        aminaId,
        productMap["Traditional Pottery Jug"],
        1,
        1200,
        "delivered",
      ],
      [karimId, aminaId, productMap["Clay Water Jar"], 2, 1700, "delivered"],
      [
        nadiaId,
        saraId,
        productMap["Lavender Scented Candle"],
        1,
        450,
        "delivered",
      ],
      [nadiaId, leilaId, productMap["Decorative Mirror"], 1, 2500, "delivered"],
      [karimId, leilaId, productMap["Decorative Mirror"], 1, 2500, "delivered"],
    ];

    for (const order of orders) {
      if (order[0] && order[1] && order[2]) {
        await db.query(
          `
          INSERT INTO orders (client_id, artisan_id, product_id, quantity, total_price, status) 
          VALUES ($1, $2, $3, $4, $5, $6)
        `,
          order,
        );
      }
    }

    // ============================================
    // 5. REVIEWS
    // ============================================
    console.log("⭐ Creating reviews...");

    const ordersResult = await db.query(
      `SELECT id, client_id, artisan_id, product_id FROM orders WHERE status = 'delivered' LIMIT 5`,
    );

    const reviewsData = [
      { rating: 5, comment: "منتج رائع، الجودة ممتازة" },
      { rating: 5, comment: "جرة ماء أصيلة وجميلة" },
      { rating: 4, comment: "رائحة جميلة جداً وتدوم طويلاً" },
      { rating: 5, comment: "مرآة خيالية، الزخارف دقيقة" },
      { rating: 5, comment: "تجاوزت توقعاتي، جودة استثنائية" },
    ];

    for (
      let i = 0;
      i < ordersResult.rows.length && i < reviewsData.length;
      i++
    ) {
      const order = ordersResult.rows[i];
      const review = reviewsData[i];
      await db.query(
        `
        INSERT INTO reviews (order_id, client_id, artisan_id, product_id, rating, comment) 
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (order_id) DO NOTHING
      `,
        [
          order.id,
          order.client_id,
          order.artisan_id,
          order.product_id,
          review.rating,
          review.comment,
        ],
      );
    }

    // ============================================
    // 6. SESSIONS
    // ============================================
    console.log("🎓 Creating sessions...");

    const future1 = new Date();
    future1.setDate(future1.getDate() + 7);
    const future2 = new Date();
    future2.setDate(future2.getDate() + 14);
    const future3 = new Date();
    future3.setDate(future3.getDate() + 10);
    const future4 = new Date();
    future4.setDate(future4.getDate() + 21);

    const sessions = [
      [
        aminaId,
        potteryId,
        "تعلم أساسيات الفخار",
        "جلسة تعليمية للمبتدئين في صناعة الفخار اليدوي",
        500,
        120,
        5,
        future1,
        1,
      ],
      [
        saraId,
        candlesId,
        "صناعة الشموع العطرية",
        "تعلم كيفية صنع شموع طبيعية في المنزل",
        350,
        90,
        6,
        future2,
        1,
      ],
      [
        nourId,
        flowersId,
        "تصنيع الورود اليدوية",
        "ورشة لتصنيع الورود والزهور اليدوية",
        300,
        90,
        8,
        future3,
        1,
      ],
      [
        leilaId,
        mirrorId,
        "فن تزيين المرايا",
        "ورشة متقدمة لتعلم تزيين المرايا",
        600,
        150,
        4,
        future4,
        1,
      ],
    ];

    for (const session of sessions) {
      if (session[0] && session[1]) {
        await db.query(
          `
          INSERT INTO sessions (artisan_id, category_id, title, description, price, duration_minutes, max_participants, scheduled_at, is_active) 
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        `,
          session,
        );
      }
    }

    // ============================================
    // 7. SPONSORSHIPS
    // ============================================
    console.log("💎 Creating sponsorships...");

    const sponsorships = [
      [aminaId, 30, 5000, "gold", "فخاريات تلمسانية أصيلة", "approved", 1],
      [leilaId, 14, 2500, "silver", "مرايا فنية بديكور عصري", "approved", 1],
      [saraId, 7, 1000, "bronze", "شموع طبيعية لهذا الموسم", "pending", null],
    ];

    for (const sponsorship of sponsorships) {
      if (sponsorship[0]) {
        await db.query(
          `
          INSERT INTO sponsorships (artisan_id, duration_days, amount, package, promo_title, status, reviewed_by, reviewed_at) 
          VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
        `,
          sponsorship,
        );
      }
    }

    // ============================================
    // 8. UPDATE STATS
    // ============================================
    console.log("📊 Updating average ratings...");
    await db.query(`
      UPDATE artisan_profiles ap
      SET avg_rating = (
        SELECT COALESCE(AVG(r.rating), 0)
        FROM reviews r WHERE r.artisan_id = ap.user_id
      )
    `);

    console.log("✨ Updating sponsored status...");
    if (aminaId && leilaId) {
      await db.query(
        `
        UPDATE artisan_profiles 
        SET is_sponsored = 1, sponsored_until = CURRENT_TIMESTAMP + INTERVAL '30 days'
        WHERE user_id IN ($1, $2)
      `,
        [aminaId, leilaId],
      );
    }

    console.log("\n✅ Seeding complete!");
    console.log("\n👤 Test accounts (password: password123):");
    console.log("   📧 Admin:   admin@naamaya.dz");
    console.log("   👥 Clients: karim@test.com  /  nadia@test.com");
    console.log(
      "   🎨 Artisans: amina@test.com  /  sara@test.com  /  nour@test.com  /  leila@test.com",
    );
    console.log("   ⏳ Pending: youssef@test.com (not approved yet)");

    process.exit(0);
  } catch (err) {
    console.error("❌ Seed error:", err.message);
    console.error(err.stack);
    process.exit(1);
  }
}

seed();
