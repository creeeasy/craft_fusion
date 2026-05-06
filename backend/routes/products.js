const express = require("express");
const router = express.Router();
const c = require("../controllers/productController");
const authMiddleware = require("../middleware/auth");
const multer = require("multer");
const path = require("path");

const storage = multer.diskStorage({
  destination: "uploads/",
  filename: (_, file, cb) =>
    cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });

router.get("/", c.getAll);
router.get("/categories", c.getCategories);
router.get("/my", authMiddleware(["artisan"]), c.myListings);
router.get("/:id", c.getOne);
router.post("/", authMiddleware(["artisan"]), upload.single("image"), c.create);
router.put("/:id", authMiddleware(["artisan"]), c.update);

module.exports = router;
