const express = require("express");
const router = express.Router();
const c = require("../controllers/adminController");
const artisanCtrl = require("../controllers/artisanController");
const authMiddleware = require("../middleware/auth");

router.use(authMiddleware(["admin"]));

router.get("/dashboard", c.dashboard);
router.get("/artisans", c.getArtisans);
router.patch("/artisans/:id/approve", c.approveArtisan);
router.patch("/artisans/:id/badge", artisanCtrl.assignBadge);
router.get("/sponsorships", c.getSponsorships);
router.patch("/sponsorships/:id", c.reviewSponsorship);
router.get("/revenue", c.revenue);
router.patch("/products/:id/toggle", c.toggleProduct);
module.exports = router;
