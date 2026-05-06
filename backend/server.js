require("dotenv").config();
const express = require("express");
const cors = require("cors");
const path = require("path");

const app = express();

app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Routes
app.use("/api/auth", require("./routes/auth"));
app.use("/api/products", require("./routes/products"));
app.use("/api/orders", require("./routes/orders"));
app.use("/api/sessions", require("./routes/sessions"));
app.use("/api/sponsorships", require("./routes/sponsorships"));
app.use("/api/artisans", require("./routes/artisans"));
app.use("/api/favorites", require("./routes/favorites"));
app.use("/api/admin", require("./routes/admin"));

app.get("/api/health", (_, res) =>
  res.json({ status: "ok", app: "Naam Aya API" }),
);

app.use((_, res) => res.status(404).json({ message: "Route not found" }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () =>
  console.log(`Naam Aya API running on port ${PORT}`),
);
