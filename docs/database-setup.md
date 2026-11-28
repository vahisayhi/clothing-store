# Clothing Store - Hướng dẫn cài đặt cơ sở dữ liệu

## 1. Yêu cầu môi trường

- PostgreSQL 17 (đã kiểm thử trên phiên bản 17.12) và pgAdmin 4.
- Node.js 24 và npm (đã kiểm thử với Node.js 24.22.1).
- Prisma CLI 7.10.1, chạy thông qua npm mà không cần thay đổi các thư viện của Backend.
- Có quyền truy cập repository và các file Database trên branch `feature/database` (hoặc branch đã tích hợp sau khi review).

Chạy các lệnh trong PowerShell tại thư mục gốc của dự án. Nếu PowerShell chặn chạy script npm, sử dụng `npm.cmd` và `npx.cmd` như hướng dẫn bên dưới.

## 2. Cấu trúc các file Database

```text
backend/prisma/
  schema.prisma
  prisma.config.mjs
  migrations/
    20261128113247_init/migration.sql
    migration_lock.toml
  seed.sql
```

Tài liệu thiết kế và sơ đồ ERD nằm trong `docs/database-design.md` và `docs/erd.png`.

## 3. Tạo Database trên máy cá nhân

Khởi động PostgreSQL. Trong pgAdmin, kết nối với server trên máy và tạo Database có tên `clothing_store`. Thông tin kết nối dùng khi phát triển trên máy cá nhân: host `localhost`, port `5432`, schema `public`.

Thiết lập chuỗi kết nối trong phiên PowerShell hiện tại. Khi Terminal yêu cầu mật khẩu, nhập mật khẩu PostgreSQL của máy mình:

```powershell
$pw = Read-Host "PostgreSQL password" -AsSecureString
$encoded = [uri]::EscapeDataString([System.Net.NetworkCredential]::new("", $pw).Password)
$env:DATABASE_URL = "postgresql://postgres:${encoded}@localhost:5432/clothing_store?schema=public"
```

Ví dụ này sử dụng tài khoản quản trị `postgres` trên máy cá nhân chỉ để thiết lập Database. Khi sử dụng ngoài môi trường phát triển cục bộ, cần dùng mật khẩu mạnh và tài khoản ứng dụng được giới hạn quyền phù hợp. Khi mở Terminal mới, phải thiết lập lại biến môi trường. Tuyệt đối không commit mật khẩu hoặc chuỗi kết nối thật lên GitHub. Khi tích hợp ứng dụng, người phụ trách Backend cần cấu hình `DATABASE_URL` trong file `.env` cục bộ của Backend (đã được loại khỏi Git), còn `.env.example` chỉ chứa giá trị minh họa.

Ví dụ định dạng chuỗi kết nối (chỉ là giá trị minh họa):

```text
postgresql://USERNAME:PASSWORD@localhost:5432/clothing_store?schema=public
```

## 4. Kiểm tra schema và chạy Migration

```powershell
npx.cmd --yes --package=prisma@7.10.1 prisma validate --config=backend/prisma/prisma.config.mjs
npx.cmd --yes --package=prisma@7.10.1 prisma migrate deploy --config=backend/prisma/prisma.config.mjs
npx.cmd --yes --package=prisma@7.10.1 prisma migrate status --config=backend/prisma/prisma.config.mjs
```

Migration đầu tiên tạo 10 bảng nghiệp vụ cùng các ràng buộc trong PostgreSQL. Prisma cũng tự tạo bảng kỹ thuật `_prisma_migrations` để quản lý lịch sử Migration. Không sửa Migration đầu tiên sau khi đã áp dụng; nếu cần thay đổi cấu trúc sau này, hãy tạo Migration mới. Khi thay đổi schema, cần giữ lại các ràng buộc CHECK và các chỉ mục duy nhất có điều kiện đã bổ sung bằng SQL.

## 5. Thêm dữ liệu mẫu (Seed Data)

Chạy lệnh sau một lần trên Database phát triển đang trống dữ liệu nghiệp vụ, sau khi đã áp dụng Migration:

```powershell
npx.cmd --yes --package=prisma@7.10.1 prisma db execute --file=backend/prisma/seed.sql --config=backend/prisma/prisma.config.mjs
```

File seed không cho phép ghi đè dữ liệu nghiệp vụ đã tồn tại. Không chạy file này trên môi trường production. Đường dẫn ảnh sản phẩm chỉ là URL minh họa. Tài khoản demo chứa mật khẩu đã băm bằng bcrypt, không lưu mật khẩu dạng văn bản thuần; việc đăng nhập bằng các tài khoản này chưa được kiểm thử. Khi chức năng xác thực sẵn sàng, sử dụng chức năng đăng ký của Backend hoặc quy trình tạo tài khoản kiểm thử đã được thống nhất để kiểm thử đăng nhập.

| Bảng | Số bản ghi dự kiến |
|---|---:|
| Roles | 3 |
| Users | 4 |
| Categories | 4 |
| Products | 8 |
| ProductImages | 8 |
| ProductVariants | 32 |
| Carts | 2 |
| CartItems | 2 |
| Orders | 1 |
| OrderItems | 2 |

## 6. Kiểm tra dữ liệu bằng pgAdmin

Mở Query Tool của Database `clothing_store` và chạy câu lệnh sau để kiểm tra số lượng bản ghi:

```sql
SELECT 'Roles' AS "Table", COUNT(*) AS "Total" FROM "Roles"
UNION ALL SELECT 'Users', COUNT(*) FROM "Users"
UNION ALL SELECT 'Categories', COUNT(*) FROM "Categories"
UNION ALL SELECT 'Products', COUNT(*) FROM "Products"
UNION ALL SELECT 'ProductImages', COUNT(*) FROM "ProductImages"
UNION ALL SELECT 'ProductVariants', COUNT(*) FROM "ProductVariants"
UNION ALL SELECT 'Carts', COUNT(*) FROM "Carts"
UNION ALL SELECT 'CartItems', COUNT(*) FROM "CartItems"
UNION ALL SELECT 'Orders', COUNT(*) FROM "Orders"
UNION ALL SELECT 'OrderItems', COUNT(*) FROM "OrderItems";
```

Kiểm tra quan hệ giữa sản phẩm, danh mục và biến thể sản phẩm:

```sql
SELECT p."name" AS "Product", c."name" AS "Category",
       v."size", v."color", v."stock", p."price"
FROM "Products" p
JOIN "Categories" c ON p."categoryId" = c."id"
JOIN "ProductVariants" v ON p."id" = v."productId"
ORDER BY p."id";
```

Kết quả dự kiến: 32 dòng.

Kiểm tra các khóa ngoại, ràng buộc giá trị số và chỉ mục duy nhất có điều kiện đã được tạo:

```sql
SELECT conrelid::regclass AS "Table", conname AS "Constraint",
       pg_get_constraintdef(oid) AS "Definition"
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace AND contype IN ('c', 'f')
UNION ALL
SELECT quote_ident(tablename)::regclass, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname IN ('Carts_active_user_key', 'ProductImages_primary_key');
```

Kết quả dự kiến trên Database mới: 18 dòng (10 khóa ngoại, 6 ràng buộc CHECK và 2 chỉ mục duy nhất có điều kiện).

## 7. Kết quả kiểm thử trên máy cá nhân

- Kiểm tra tính hợp lệ của schema Prisma: đạt.
- Kết nối Database và áp dụng Migration đầu tiên: đạt.
- Chạy Seed Data và kiểm tra số lượng bản ghi: đạt đối với cả 10 bảng.
- Truy vấn JOIN giữa sản phẩm, danh mục và biến thể: trả về 32 dòng.
- Giá sản phẩm âm, tồn kho âm và số lượng trong giỏ hàng bằng 0: đều bị PostgreSQL từ chối (3/3 bài kiểm thử đạt).
- Khóa ngoại, ràng buộc CHECK và chỉ mục duy nhất có điều kiện: đã xác nhận tồn tại bằng truy vấn danh mục hệ thống của PostgreSQL.

Đây là các kiểm thử ở cấp Database, chưa phải kiểm thử toàn bộ ứng dụng từ Frontend đến Backend và Database (end-to-end). Các trường hợp vi phạm ràng buộc riêng lẻ còn lại và các luồng xác thực, CRUD của Backend chưa được kiểm thử ở đây.

## 8. Bàn giao cho Backend

Schema Database đã sẵn sàng để review tích hợp. Người phụ trách Backend chịu trách nhiệm quản lý các thư viện của ứng dụng, tạo và tích hợp Prisma Client, xác thực, REST API, phân quyền và kiểm tra các quy tắc nghiệp vụ.

Schema hiện tại sử dụng generator `prisma-client` của Prisma 7, định dạng module ESM, mã đầu ra TypeScript và đường dẫn đầu ra tương đối `../generated/prisma`. Người phụ trách Backend cần xác nhận cách chạy và import phù hợp với Backend viết bằng JavaScript, cài đặt Prisma Client và PostgreSQL adapter tương thích, đồng thời thống nhất trước nếu cần thay đổi generator. Việc tạo Prisma Client và kết nối từ ứng dụng Backend chưa được kiểm thử. Các bước chạy Prisma CLI ở trên không yêu cầu cài đặt các thư viện ứng dụng này.

Sử dụng transaction khi đặt hàng và thay đổi tồn kho. Kiểm tra quyền sở hữu dữ liệu của khách hàng và quyền theo vai trò tại tầng ứng dụng; khóa ngoại không thay thế việc phân quyền. Không trả về mật khẩu đã băm trong phản hồi API. Khi lịch sử đơn hàng không cho phép xóa hẳn sản phẩm, hãy chuyển sản phẩm sang trạng thái ngừng hoạt động.

Phạm vi bàn giao chỉ gồm các file Database và tài liệu Database. Không thay đổi code ứng dụng Backend hoặc Frontend của các thành viên khác.
