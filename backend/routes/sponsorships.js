const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const c = require("../controllers/sponsorshipController");
const auth = require("../middleware/auth");

const storage = multer.diskStorage({
  destination: "uploads/",
  filename: (_, file, cb) =>
    cb(
      null,
      `promo_${Date.now()}_${Math.random().toString(36).slice(2)}${path.extname(file.originalname)}`,
    ),
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_, file, cb) => {
    const allowed = /jpeg|jpg|png|webp/;
    cb(null, allowed.test(file.mimetype));
  },
});

router.get("/active", c.getActive);
router.get("/my", auth(["artisan"]), c.my);
router.post(
  "/request",
  auth(["artisan"]),
  upload.array("photos", 3),
  c.request,
);

module.exports = router;
