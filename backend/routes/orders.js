const express = require("express");
const router = express.Router();
const c = require("../controllers/orderController");
const authMiddleware = require("../middleware/auth");

router.post("/", authMiddleware(["client"]), c.create);
router.get("/my", authMiddleware(["client"]), c.myOrders);
router.get("/artisan", authMiddleware(["artisan"]), c.artisanOrders);
router.patch("/:id/status", authMiddleware(["artisan"]), c.updateStatus);
router.post("/:id/review", authMiddleware(["client"]), c.review);
router.post("/:id/cancel", authMiddleware(["client"]), c.cancel);
module.exports = router;
