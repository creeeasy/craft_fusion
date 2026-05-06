const express = require("express");
const router = express.Router();
const c = require("../controllers/artisanController");
const authMiddleware = require("../middleware/auth");

router.get("/map", c.getMapArtisans);
router.patch("/location", authMiddleware(["artisan"]), c.updateLocation);
router.get("/:id/reviews", c.getReviews);
module.exports = router;
