const connectDb = require("../config/db");
const Shop = require("../models/Shop");
const Product = require("../models/Product");
const slugify = require("../utils/slugify");
const buildShopUrl = require("../utils/shopUrl");

async function seed() {
  await connectDb();

  const name = "Aman General Store";
  const slug = slugify(name);
  const qrUrl = buildShopUrl(slug);

  const shop = await Shop.findOneAndUpdate(
    { slug },
    {
      name,
      slug,
      ownerName: "Aman",
      phone: "919876543210",
      whatsappNumber: "919876543210",
      address: "Market Road",
      qrUrl,
      isActive: true
    },
    {
      upsert: true,
      new: true,
      setDefaultsOnInsert: true
    }
  );

  const products = [
    { name: "Samosa", price: 15, category: "Snacks", sortOrder: 1 },
    { name: "Tea", price: 10, category: "Drinks", sortOrder: 2 },
    { name: "Cold Drink", price: 40, category: "Drinks", sortOrder: 3 }
  ];

  for (const product of products) {
    await Product.findOneAndUpdate(
      { shopId: shop._id, name: product.name },
      { ...product, shopId: shop._id, isAvailable: true },
      { upsert: true, setDefaultsOnInsert: true }
    );
  }

  console.log("Seed completed");
  console.log(`Shop URL: ${qrUrl}`);
  process.exit(0);
}

seed().catch((error) => {
  console.error(error);
  process.exit(1);
});
