-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PENDING', 'CONFIRMED', 'SHIPPING', 'COMPLETED', 'CANCELLED');

-- CreateTable
CREATE TABLE "Roles" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(50) NOT NULL,

    CONSTRAINT "Roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Users" (
    "id" SERIAL NOT NULL,
    "roleId" INTEGER NOT NULL,
    "fullName" VARCHAR(100) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "passwordHash" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(20),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Categories" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Products" (
    "id" SERIAL NOT NULL,
    "categoryId" INTEGER NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "price" DECIMAL(12,2) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Products_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProductImages" (
    "id" SERIAL NOT NULL,
    "productId" INTEGER NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "isPrimary" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "ProductImages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProductVariants" (
    "id" SERIAL NOT NULL,
    "productId" INTEGER NOT NULL,
    "sku" VARCHAR(50) NOT NULL,
    "size" VARCHAR(20) NOT NULL,
    "color" VARCHAR(50) NOT NULL,
    "stock" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "ProductVariants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Carts" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Carts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CartItems" (
    "id" SERIAL NOT NULL,
    "cartId" INTEGER NOT NULL,
    "variantId" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,

    CONSTRAINT "CartItems_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Orders" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "receiverName" VARCHAR(100) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "shippingAddress" TEXT NOT NULL,
    "totalAmount" DECIMAL(12,2) NOT NULL,
    "status" "OrderStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrderItems" (
    "id" SERIAL NOT NULL,
    "orderId" INTEGER NOT NULL,
    "variantId" INTEGER NOT NULL,
    "productName" VARCHAR(200) NOT NULL,
    "size" VARCHAR(20) NOT NULL,
    "color" VARCHAR(50) NOT NULL,
    "unitPrice" DECIMAL(12,2) NOT NULL,
    "quantity" INTEGER NOT NULL,

    CONSTRAINT "OrderItems_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Roles_name_key" ON "Roles"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Users_email_key" ON "Users"("email");

-- CreateIndex
CREATE INDEX "Users_roleId_idx" ON "Users"("roleId");

-- CreateIndex
CREATE UNIQUE INDEX "Categories_name_key" ON "Categories"("name");

-- CreateIndex
CREATE INDEX "Products_categoryId_idx" ON "Products"("categoryId");

-- CreateIndex
CREATE INDEX "Products_name_idx" ON "Products"("name");

-- CreateIndex
CREATE INDEX "Products_price_idx" ON "Products"("price");

-- CreateIndex
CREATE INDEX "ProductImages_productId_idx" ON "ProductImages"("productId");

-- CreateIndex
CREATE UNIQUE INDEX "ProductVariants_sku_key" ON "ProductVariants"("sku");

-- CreateIndex
CREATE UNIQUE INDEX "ProductVariants_productId_size_color_key" ON "ProductVariants"("productId", "size", "color");

-- CreateIndex
CREATE INDEX "Carts_userId_idx" ON "Carts"("userId");

-- CreateIndex
CREATE INDEX "CartItems_variantId_idx" ON "CartItems"("variantId");

-- CreateIndex
CREATE UNIQUE INDEX "CartItems_cartId_variantId_key" ON "CartItems"("cartId", "variantId");

-- CreateIndex
CREATE INDEX "Orders_userId_idx" ON "Orders"("userId");

-- CreateIndex
CREATE INDEX "Orders_status_idx" ON "Orders"("status");

-- CreateIndex
CREATE INDEX "OrderItems_orderId_idx" ON "OrderItems"("orderId");

-- CreateIndex
CREATE INDEX "OrderItems_variantId_idx" ON "OrderItems"("variantId");

-- AddForeignKey
ALTER TABLE "Users" ADD CONSTRAINT "Users_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Products" ADD CONSTRAINT "Products_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProductImages" ADD CONSTRAINT "ProductImages_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProductVariants" ADD CONSTRAINT "ProductVariants_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Carts" ADD CONSTRAINT "Carts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CartItems" ADD CONSTRAINT "CartItems_cartId_fkey" FOREIGN KEY ("cartId") REFERENCES "Carts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CartItems" ADD CONSTRAINT "CartItems_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "ProductVariants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Orders" ADD CONSTRAINT "Orders_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrderItems" ADD CONSTRAINT "OrderItems_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrderItems" ADD CONSTRAINT "OrderItems_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "ProductVariants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Products"
ADD CONSTRAINT "Products_price_check"
CHECK ("price" > 0);

ALTER TABLE "ProductVariants"
ADD CONSTRAINT "ProductVariants_stock_check"
CHECK ("stock" >= 0);

ALTER TABLE "CartItems"
ADD CONSTRAINT "CartItems_quantity_check"
CHECK ("quantity" > 0);

ALTER TABLE "Orders"
ADD CONSTRAINT "Orders_totalAmount_check"
CHECK ("totalAmount" >= 0);

ALTER TABLE "OrderItems"
ADD CONSTRAINT "OrderItems_unitPrice_check"
CHECK ("unitPrice" > 0);

ALTER TABLE "OrderItems"
ADD CONSTRAINT "OrderItems_quantity_check"
CHECK ("quantity" > 0);

CREATE UNIQUE INDEX "Carts_active_user_key"
ON "Carts" ("userId")
WHERE "isActive" = true;

CREATE UNIQUE INDEX "ProductImages_primary_key"
ON "ProductImages" ("productId")
WHERE "isPrimary" = true;