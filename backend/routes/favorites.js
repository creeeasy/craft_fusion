const express = require("express");
const router = express.Router();
const c = require("../controllers/favoritesController");
const auth = require("../middleware/auth");

router.use(auth(["client"]));

router.get("/", c.getAll);
router.get("/ids", c.getIds);
router.post("/:productId", c.toggle);

module.exports = router;
