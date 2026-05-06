-- Add image and category to sessions
ALTER TABLE sessions ADD COLUMN image_url VARCHAR(255) AFTER description;
ALTER TABLE sessions ADD COLUMN category_id INT AFTER artisan_id;
ALTER TABLE sessions ADD FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;

-- Add rating to session_bookings
ALTER TABLE session_bookings ADD COLUMN rating INT CHECK (rating BETWEEN 1 AND 5) AFTER status;
ALTER TABLE session_bookings ADD COLUMN review TEXT AFTER rating;
ALTER TABLE session_bookings ADD COLUMN rated_at DATETIME AFTER review;

-- Add index for upcoming queries
ALTER TABLE sessions ADD INDEX idx_scheduled_at (scheduled_at);
ALTER TABLE sessions ADD INDEX idx_is_active (is_active);