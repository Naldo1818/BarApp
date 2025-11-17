# BarApp

A Flutter-based bar menu application with real-time stock tracking, cart management, and checkout functionality. This app simulates a point-of-sale system where drink items are listed under categories, users can add items to a cart, and stock quantities automatically decrease when items are added.

This project uses **Flutter**, **Sqflite**, and **Material 3** design principles.

---

## 📌 Features

### ✅ **Dynamic Menu**
- Drinks grouped under expandable categories (Beers, Ciders, Vodka, Rums, Whiskies, Soft Drinks).
- Live stock availability shown beside each item.
- "Add" button automatically disables when stock reaches zero.

### ✅ **Stock Management**
- Uses **Sqflite** to store item name, price, and stock level.
- Stock decreases when adding items to cart.
- Clearing the cart restores stock quantities.
- Database auto-created on first launch with pre-loaded stock.

### ✅ **Cart & Checkout**
- Tracks quantity and total price.
- Displays full order summary.
- Cancel or Confirm checkout.
- Confirmed orders clear the cart and show a success message.

### ✅ **UI & UX**
- Dark-themed design.
- Clean Material 3 look.
- Smooth category expansion animations.
- Real-time stock updates without app restart.



