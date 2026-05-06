-- Users table (shared: client, artisan, admin)
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'client' CHECK (role IN ('client', 'artisan', 'admin')),
  phone VARCHAR(20),
  location VARCHAR(100),
  avatar VARCHAR(255),
  is_approved SMALLINT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Artisan profiles
CREATE TABLE IF NOT EXISTS artisan_profiles (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,
  bio TEXT,
  craft_type VARCHAR(100),
  badge VARCHAR(10) DEFAULT 'new' CHECK (badge IN ('new', 'silver', 'gold')),
  is_sponsored SMALLINT DEFAULT 0,
  sponsored_until TIMESTAMP,
  total_sales INTEGER DEFAULT 0,
  avg_rating DECIMAL(3,2) DEFAULT 0.00,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Categories
CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  name_ar VARCHAR(100),
  icon VARCHAR(50)
);

-- Products / listings
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  artisan_id INTEGER NOT NULL,
  category_id INTEGER,
  title VARCHAR(200) NOT NULL,
  title_ar VARCHAR(200),
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  stock INTEGER DEFAULT 1,
  image VARCHAR(255),
  is_active SMALLINT DEFAULT 1,
  total_orders INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (artisan_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  client_id INTEGER NOT NULL,
  artisan_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  quantity INTEGER DEFAULT 1,
  total_price DECIMAL(10,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (client_id) REFERENCES users(id),
  FOREIGN KEY (artisan_id) REFERENCES users(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Reviews / ratings
CREATE TABLE IF NOT EXISTS reviews (
  id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL UNIQUE,
  client_id INTEGER NOT NULL,
  artisan_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (client_id) REFERENCES users(id),
  FOREIGN KEY (artisan_id) REFERENCES users(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Learning sessions
CREATE TABLE IF NOT EXISTS sessions (
  id SERIAL PRIMARY KEY,
  artisan_id INTEGER NOT NULL,
  category_id INTEGER,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  max_participants INTEGER DEFAULT 5,
  scheduled_at TIMESTAMP,
  is_active SMALLINT DEFAULT 1,
  image_url VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (artisan_id) REFERENCES users(id),
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Session bookings
CREATE TABLE IF NOT EXISTS session_bookings (
  id SERIAL PRIMARY KEY,
  session_id INTEGER NOT NULL,
  client_id INTEGER NOT NULL,
  status VARCHAR(20) DEFAULT 'booked' CHECK (status IN ('booked', 'attended', 'cancelled')),
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  review TEXT,
  rated_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES sessions(id),
  FOREIGN KEY (client_id) REFERENCES users(id)
);

-- Sponsorship requests
CREATE TABLE IF NOT EXISTS sponsorships (
  id SERIAL PRIMARY KEY,
  artisan_id INTEGER NOT NULL,
  duration_days INTEGER NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  package VARCHAR(20) CHECK (package IN ('bronze', 'silver', 'gold')),
  promo_title VARCHAR(255),
  promo_message TEXT,
  product_id INTEGER,
  photo_1 VARCHAR(255),
  photo_2 VARCHAR(255),
  photo_3 VARCHAR(255),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reject_reason TEXT,
  requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP,
  reviewed_by INTEGER,
  FOREIGN KEY (artisan_id) REFERENCES users(id),
  FOREIGN KEY (reviewed_by) REFERENCES users(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Favorites table
CREATE TABLE IF NOT EXISTS favorites (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, product_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Seed categories (static data)
INSERT INTO categories (name, name_ar, icon) VALUES
('Pottery', 'فخار وطين', '🏺'),
('Candles', 'شموع', '🕯️'),
('Handmade Flowers', 'ورود يدوية', '🌸'),
('Mirror Design', 'تصميم مرايا', '🪞'),
('Textiles', 'نسيج', '🧵'),
('Woodwork', 'نجارة', '🪵')
ON CONFLICT (name) DO NOTHING;