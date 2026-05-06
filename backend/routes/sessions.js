const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const c = require("../controllers/sessionController");
const auth = require("../middleware/auth");

// Multer config for session images
const storage = multer.diskStorage({
  destination: "uploads/",
  filename: (_, file, cb) =>
    cb(null, `session_${Date.now()}${path.extname(file.originalname)}`),
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_, file, cb) => {
    const allowed = /jpeg|jpg|png|webp/;
    cb(null, allowed.test(file.mimetype));
  },
});

// Public routes
router.get("/", c.getAll);

// Client routes
router.get("/upcoming", auth(["client"]), c.getUpcomingBookings);
router.get("/my-bookings", auth(["client"]), c.getMyBookings);
router.post("/:id/book", auth(["client"]), c.book);
router.post("/:id/rate", auth(["client"]), c.rateSession);
router.delete("/:id/cancel", auth(["client"]), c.cancelBooking);

// Artisan routes
router.get("/my", auth(["artisan"]), c.getMy);
router.post("/", auth(["artisan"]), upload.single("image"), c.create);
router.patch("/:id", auth(["artisan"]), c.toggleActive);

module.exports = router;
