const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const env = require("../config/env");
const Owner = require("../models/Owner");

let io = null;

function serializeOrder(order) {
  return {
    _id: order._id,
    orderNumber: order.orderNumber,
    customer: order.customer,
    items: order.items,
    pricing: order.pricing,
    payment: order.payment,
    totalAmount: order.totalAmount,
    status: order.status,
    notification: order.notification,
    createdAt: order.createdAt,
    updatedAt: order.updatedAt
  };
}

function initRealtime(server) {
  io = new Server(server, {
    cors: {
      origin: env.corsOrigin === "*" ? true : env.corsOrigin,
      credentials: true
    }
  });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;

      if (!token) {
        return next(new Error("Missing auth token"));
      }

      const payload = jwt.verify(token, env.jwtSecret);
      const owner = await Owner.findById(payload.ownerId).select("shopId isActive");

      if (!owner || !owner.isActive) {
        return next(new Error("Owner not found"));
      }

      socket.ownerId = String(owner._id);
      socket.shopId = String(owner.shopId);
      return next();
    } catch (_error) {
      return next(new Error("Invalid auth token"));
    }
  });

  io.on("connection", (socket) => {
    socket.join(`shop:${socket.shopId}`);
    socket.emit("connected", {
      shopId: socket.shopId
    });
  });

  console.log("Realtime server initialized");
  return io;
}

function emitNewOrder(order) {
  if (!io) {
    return;
  }

  io.to(`shop:${order.shopId}`).emit("order:new", serializeOrder(order));
}

function emitOrderUpdated(order) {
  if (!io) {
    return;
  }

  io.to(`shop:${order.shopId}`).emit("order:updated", serializeOrder(order));
}

module.exports = {
  initRealtime,
  emitNewOrder,
  emitOrderUpdated
};
