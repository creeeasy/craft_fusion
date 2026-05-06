-- Migration: Seed sessions and bookings data
-- Description: Populate sessions with test data for new database
-- Date: 2026-05-06

-- ============================================
-- 1. Insert sessions (assuming empty tables)
-- ============================================

-- Past sessions (for rating testing)
INSERT INTO sessions (artisan_id, category_id, title, description, image_url, price, duration_minutes, max_participants, scheduled_at, is_active) VALUES
(2, 1, 'ورشة الفخار للمبتدئين', 'تعلم أساسيات صناعة الفخار اليدوي من الصفر', NULL, 500.00, 120, 5, CURRENT_TIMESTAMP - INTERVAL '5 days', 1),
(3, 2, 'صناعة الشموع الطبيعية', 'تعلم صنع شموع عطرية طبيعية في المنزل', NULL, 350.00, 90, 6, CURRENT_TIMESTAMP - INTERVAL '2 days', 1);

-- Today's session (shows "اليوم" badge)
INSERT INTO sessions (artisan_id, category_id, title, description, image_url, price, duration_minutes, max_participants, scheduled_at, is_active) VALUES
(4, 3, 'تنسيق الورود اليدوية', 'تعلم تنسيق باقات الورود اليدوية للمناسبات', NULL, 300.00, 90, 8, CURRENT_TIMESTAMP, 1);

-- Upcoming sessions (this week)
INSERT INTO sessions (artisan_id, category_id, title, description, image_url, price, duration_minutes, max_participants, scheduled_at, is_active) VALUES
(5, 4, 'فن تزيين المرايا', 'ورشة متقدمة لتزيين المرايا بالزخارف التقليدية', NULL, 600.00, 150, 4, CURRENT_TIMESTAMP + INTERVAL '3 days', 1),
(2, 1, 'الخزف المعاصر', 'تقنيات حديثة في صناعة الخزف', NULL, 750.00, 180, 4, CURRENT_TIMESTAMP + INTERVAL '5 days', 1),
(3, 2, 'الشموع الملونة', 'تقنيات تلوين وتزيين الشموع', NULL, 400.00, 90, 8, CURRENT_TIMESTAMP + INTERVAL '7 days', 1);

-- Next week sessions
INSERT INTO sessions (artisan_id, category_id, title, description, image_url, price, duration_minutes, max_participants, scheduled_at, is_active) VALUES
(4, 3, 'ورود الريزن', 'صناعة ورود الريزن الشفافة', NULL, 550.00, 120, 6, CURRENT_TIMESTAMP + INTERVAL '10 days', 1),
(5, 4, 'مرايا فنية', 'تصميم مرايا بديكورات عصرية', NULL, 800.00, 150, 5, CURRENT_TIMESTAMP + INTERVAL '12 days', 1);

-- Popular sessions (higher prices, limited capacity for urgency)
INSERT INTO sessions (artisan_id, category_id, title, description, image_url, price, duration_minutes, max_participants, scheduled_at, is_active) VALUES
(2, 1, 'احتراف الفخار', 'دورة متكاملة لاحتراف صناعة الفخار', NULL, 1200.00, 240, 3, CURRENT_TIMESTAMP + INTERVAL '14 days', 1),
(5, 4, 'مرايا تراثية', 'تصاميم مرايا بالزخرفة التقليدية الجزائرية', NULL, 900.00, 180, 4, CURRENT_TIMESTAMP + INTERVAL '16 days', 1);

-- ============================================
-- 2. Insert session bookings (optional - only if you have users)
-- ============================================
-- Note: These require existing users with IDs 7 and 8
-- Skip if you don't have those users yet

-- Past session with ratings (session_id = 1)
INSERT INTO session_bookings (session_id, client_id, status, rating, review, rated_at) VALUES
(1, 7, 'booked', 5, 'جلسة رائعة! تعلمت الكثير عن الفخار', CURRENT_TIMESTAMP - INTERVAL '3 days'),
(1, 8, 'booked', 4, 'جيد جداً، أنصح بها', CURRENT_TIMESTAMP - INTERVAL '3 days');

-- Past session without rating (can rate - session_id = 2)
INSERT INTO session_bookings (session_id, client_id, status, rating, review, rated_at) VALUES
(2, 7, 'booked', NULL, NULL, NULL),
(2, 8, 'booked', NULL, NULL, NULL);

-- Today's session bookings (session_id = 3)
INSERT INTO session_bookings (session_id, client_id, status, rating, review, rated_at) VALUES
(3, 7, 'booked', NULL, NULL, NULL);

-- Upcoming session bookings
INSERT INTO session_bookings (session_id, client_id, status, rating, review, rated_at) VALUES
(4, 8, 'booked', NULL, NULL, NULL),
(5, 7, 'booked', NULL, NULL, NULL);

-- Cancelled booking (session_id = 6)
INSERT INTO session_bookings (session_id, client_id, status, rating, review, rated_at) VALUES
(6, 7, 'cancelled', NULL, NULL, NULL);

-- ============================================
-- 3. Update artisan profiles with average ratings
-- ============================================

UPDATE artisan_profiles SET avg_rating = 4.5 WHERE user_id = 2;
UPDATE artisan_profiles SET avg_rating = 4.0 WHERE user_id = 3;
UPDATE artisan_profiles SET avg_rating = 4.8 WHERE user_id = 4;
UPDATE artisan_profiles SET avg_rating = 5.0 WHERE user_id = 5;

-- ============================================
-- 4. Verify data (optional)
-- ============================================
SELECT '=== SESSIONS ===' as info;
SELECT id, artisan_id, title, price, scheduled_at, 
       CASE 
         WHEN scheduled_at < CURRENT_TIMESTAMP THEN 'past'
         WHEN DATE(scheduled_at) = CURRENT_DATE THEN 'today'
         ELSE 'upcoming'
       END as period
FROM sessions 
ORDER BY scheduled_at;

SELECT '=== BOOKINGS ===' as info;
SELECT sb.id, s.title, sb.client_id, sb.status, sb.rating, s.scheduled_at
FROM session_bookings sb
JOIN sessions s ON sb.session_id = s.id;