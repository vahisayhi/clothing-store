-- Clothing Store: local development seed data.
-- Demo accounts only. Do not use this seed in production.
-- Run once on a fresh database; existing business data is never overwritten.
DO $seed$
DECLARE
    item RECORD;
    variant RECORD;
    product_id INTEGER;
    customer_id INTEGER;
    customer2_id INTEGER;
    cart_id INTEGER;
    order_id INTEGER;
BEGIN
    IF EXISTS (
        SELECT 1 FROM "Roles" UNION ALL SELECT 1 FROM "Users"
        UNION ALL SELECT 1 FROM "Categories" UNION ALL SELECT 1 FROM "Products"
        UNION ALL SELECT 1 FROM "ProductImages" UNION ALL SELECT 1 FROM "ProductVariants"
        UNION ALL SELECT 1 FROM "Carts" UNION ALL SELECT 1 FROM "CartItems"
        UNION ALL SELECT 1 FROM "Orders" UNION ALL SELECT 1 FROM "OrderItems"
    ) THEN
        RAISE EXCEPTION 'Seed requires empty business tables. Existing data was not changed.';
    END IF;

    INSERT INTO "Roles" ("name") VALUES ('ADMIN'), ('STAFF'), ('CUSTOMER');

    INSERT INTO "Users" ("fullName", "email", "roleId", "passwordHash", "updatedAt")
    SELECT u.name, u.email, r."id", u.hash, CURRENT_TIMESTAMP
    FROM (VALUES
        ('Demo Admin', 'admin@clothing.example', 'ADMIN', '$2b$12$b5QBVkqqaWeJn/IfwzcNcecr4GERgDoswkSzsnPhZsuYKJ/mswSja'),
        ('Demo Staff', 'staff@clothing.example', 'STAFF', '$2b$12$upQexgeqfdGV.k5kUnStXuFS7JFvct0x4gob0/evB6wizQ2C/991S'),
        ('Demo Customer', 'customer@clothing.example', 'CUSTOMER', '$2b$12$TNnUXHNZ4OqNWp0pX2bqueQds352toTdYzYLWI2GZavfG/8cBweZ2'),
        ('Demo Customer Two', 'customer2@clothing.example', 'CUSTOMER', '$2b$12$Mh8BpeigMo./FMLQFuG45uaLBCwlcTjlQmXrtH9.Xu6zysiO6E8Wq')
    ) AS u(name, email, role, hash)
    JOIN "Roles" r ON r."name" = u.role;

    INSERT INTO "Categories" ("name", "description") VALUES
        ('T-Shirts', 'Everyday cotton T-shirts'),
        ('Shirts', 'Casual and formal shirts'),
        ('Jeans', 'Denim trousers'),
        ('Jackets', 'Outerwear and jackets');

    FOR item IN SELECT * FROM (VALUES
        ('TS01', 'Basic Cotton T-Shirt', 'T-Shirts', 159000, 'Regular fit cotton T-shirt'),
        ('TS02', 'Oversized T-Shirt', 'T-Shirts', 199000, 'Relaxed fit T-shirt'),
        ('SH01', 'Oxford Shirt', 'Shirts', 299000, 'Classic long sleeve shirt'),
        ('SH02', 'Casual Shirt', 'Shirts', 259000, 'Lightweight everyday shirt'),
        ('JN01', 'Straight Jeans', 'Jeans', 399000, 'Straight leg denim'),
        ('JN02', 'Slim Jeans', 'Jeans', 429000, 'Slim fit denim'),
        ('JK01', 'Denim Jacket', 'Jackets', 499000, 'Classic denim jacket'),
        ('JK02', 'Windbreaker Jacket', 'Jackets', 459000, 'Lightweight outerwear')
    ) AS p(code, name, category, price, description)
    LOOP
        INSERT INTO "Products" ("categoryId", "name", "description", "price", "updatedAt")
        SELECT "id", item.name, item.description, item.price, CURRENT_TIMESTAMP
        FROM "Categories" WHERE "name" = item.category
        RETURNING "id" INTO product_id;

        INSERT INTO "ProductImages" ("productId", "imageUrl", "isPrimary")
        VALUES (product_id, 'https://placehold.co/600x800?text=' || item.code, true);

        FOR variant IN SELECT * FROM (VALUES
            ('M', 'Black', 20), ('L', 'Black', 15),
            ('M', 'White', 10), ('L', 'White', 0)
        ) AS v(size, color, stock)
        LOOP
            INSERT INTO "ProductVariants" ("productId", "sku", "size", "color", "stock")
            VALUES (product_id, item.code || '-' || variant.size || '-' || upper(variant.color),
                    variant.size, variant.color, variant.stock);
        END LOOP;
    END LOOP;

    SELECT "id" INTO customer_id FROM "Users" WHERE "email" = 'customer@clothing.example';
    SELECT "id" INTO customer2_id FROM "Users" WHERE "email" = 'customer2@clothing.example';

    INSERT INTO "Carts" ("userId", "updatedAt") VALUES (customer_id, CURRENT_TIMESTAMP)
    RETURNING "id" INTO cart_id;
    INSERT INTO "Carts" ("userId", "updatedAt") VALUES (customer2_id, CURRENT_TIMESTAMP);

    INSERT INTO "CartItems" ("cartId", "variantId", "quantity")
    SELECT cart_id, "id", 1 FROM "ProductVariants" WHERE "sku" = 'TS01-M-BLACK';
    INSERT INTO "CartItems" ("cartId", "variantId", "quantity")
    SELECT cart_id, "id", 2 FROM "ProductVariants" WHERE "sku" = 'JN01-L-BLACK';

    INSERT INTO "Orders" ("userId", "receiverName", "phone", "shippingAddress", "totalAmount", "status", "updatedAt")
    SELECT customer_id, 'Demo Customer', '0900000000', 'Demo address, Hanoi',
           SUM(p."price" * v.quantity), 'COMPLETED', CURRENT_TIMESTAMP
    FROM (VALUES ('SH01-M-BLACK', 1), ('TS02-L-BLACK', 2)) AS v(sku, quantity)
    JOIN "ProductVariants" pv ON pv."sku" = v.sku
    JOIN "Products" p ON p."id" = pv."productId"
    RETURNING "id" INTO order_id;

    INSERT INTO "OrderItems" ("orderId", "variantId", "productName", "size", "color", "unitPrice", "quantity")
    SELECT order_id, pv."id", p."name", pv."size", pv."color", p."price", v.quantity
    FROM (VALUES ('SH01-M-BLACK', 1), ('TS02-L-BLACK', 2)) AS v(sku, quantity)
    JOIN "ProductVariants" pv ON pv."sku" = v.sku
    JOIN "Products" p ON p."id" = pv."productId";

    UPDATE "ProductVariants" pv SET "stock" = pv."stock" - oi."quantity"
    FROM "OrderItems" oi WHERE oi."orderId" = order_id AND pv."id" = oi."variantId";
END;
$seed$;
