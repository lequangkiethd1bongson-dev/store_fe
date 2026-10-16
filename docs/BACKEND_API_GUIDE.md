# TÀI LIỆU HƯỚNG DẪN XÂY DỰNG BACKEND API (JAVA / SPRING BOOT)
> Dành cho thành viên phụ trách Backend dự án **ShoppingSmartMart4 (SSM4)**  
> Phiên bản đồng bộ phân quyền **Khách hàng (Customer)** & **Nhân viên (Staff)**

---

## 1. Trình Tự Triển Khai Phía Frontend (Tham Chiếu)

Theo sơ đồ quy chuẩn của dự án:

| Bước | Tệp mã nguồn | Công việc phía Frontend | Yêu cầu đối ứng Backend |
|---|---|---|---|
| **1** | `lib/core/constants/api_constants.dart` | Khai báo địa chỉ API Java & các endpoint | Cung cấp base URL `http://<ip>:8080/api` |
| **2** | `lib/core/network/api_client.dart` | Tạo chức năng gửi HTTP request | Phản hồi đúng Content-Type, UTF-8, HTTP code |
| **3** | `lib/models/product.dart` | Ánh xạ JSON thành đối tượng Product | Chuẩn hóa tên trường JSON theo chuẩn camelCase |
| **4** | `lib/services/product_service.dart` | Gọi API và nhận danh sách sản phẩm | Cung cấp các endpoint GET sản phẩm |
| **5** | `lib/state/store_controller.dart` | Gọi Service, cập nhật danh sách và trạng thái tải | Đảm bảo hiệu năng & tính toàn vẹn dữ liệu |
| **6** | `lib/screens/home_screen.dart` | Gọi tải dữ liệu khi mở màn hình, giữ nguyên UI | Tương thích dữ liệu hiển thị trên HomeScreen |
| **7** | `lib/main.dart` | Cấu hình quản lý trạng thái gốc | Không cần can thiệp Backend |

---

## 2. Thiết Kế Phân Quyền (RBAC: Customer vs Staff)

Hệ thống SSM4 chia làm **2 vai trò (Role)** rõ ràng:

```
                      ┌─────────────────────────────────────────┐
                      │             POST /auth/login            │
                      └────────────────────┬────────────────────┘
                                           │
                        Trả về JWT Token + role người dùng
                                           │
                 ┌─────────────────────────┴─────────────────────────┐
                 ▼                                                   ▼
       【 ROLE: CUSTOMER 】                                  【 ROLE: STAFF 】
  - Giao diện mua sắm khách hàng                       - Giao diện nhân viên (StaffWorkspace)
  - Xem sản phẩm, tìm kiếm, lọc                        - 1. Sơ đồ kệ hàng (9 kệ, 4 tầng/kệ)
  - Thêm giỏ hàng, đặt hàng (COD/Bank)                 - 2. Kho dự trữ & nhập kho
  - Xem lịch sử đơn hàng cá nhân                       - 3. Chuyển hàng từ kho lên tầng kệ
  - BỊ CHẶN (403) nếu gọi /api/staff/**                - 4. Quét mã POS bán lẻ tại quầy
                                                       - 5. Điểm danh / Chấm công ca làm
```

### 2.1. Quy định phản hồi Đăng nhập / Đăng ký
Khi người dùng đăng nhập (`POST /api/auth/login`), Backend **bắt buộc** trả về trường `role` trong đối tượng `user`:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "U001",
    "name": "Nguyễn Văn Bán Hàng",
    "email": "staff01@ssm.com",
    "phone": "0912345678",
    "role": "STAFF"  // Hoặc "CUSTOMER" cho khách hàng
  }
}
```

### 2.2. Bảo mật Spring Security
```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                // Công khai: Xem sản phẩm, danh mục, đăng nhập/đăng ký
                .requestMatchers("/api/auth/**", "/api/products/**", "/api/categories/**").permitAll()
                // Khách hàng & Nhân viên: Đơn hàng, tài khoản cá nhân
                .requestMatchers("/api/orders/**", "/api/users/me/**").authenticated()
                // BẮT BUỘC QUYỀN NHÂN VIÊN: Toàn bộ phân hệ /api/staff/**
                .requestMatchers("/api/staff/**").hasRole("STAFF")
                .anyRequest().authenticated()
            );
        return http.build();
    }
}
```

---

## 3. Danh Sách Endpoint Cần Xây Dựng

### 🛒 Phân hệ 1: Sản phẩm & Danh mục (Công khai)

| Phương thức | Endpoint | Mô tả |
|---|---|---|
| `GET` | `/api/products` | Lấy danh sách sản phẩm (hỗ trợ `?category=` và `?keyword=`) |
| `GET` | `/api/products/{id}` | Lấy chi tiết 1 sản phẩm |
| `GET` | `/api/products/barcode/{barcode}` | Quét barcode tìm sản phẩm (dùng cho cả Khách & Nhân viên) |
| `GET` | `/api/categories` | Lấy danh mục kèm số lượng sản phẩm |

**Cấu trúc JSON Sản phẩm chuẩn**:
```json
{
  "id": "milk",
  "name": "Sữa tươi Vinamilk 1L",
  "price": 36500,
  "oldPrice": 42000,
  "importPrice": 30000,
  "barcode": "8938501001001",
  "rating": 4.9,
  "category": "Sữa & trứng",
  "brand": "VINAMILK",
  "packageSize": "1 lít",
  "imageUrl": "https://images.unsplash.com/photo-1596633605700-1efc9b49e277?auto=format&fit=crop&w=700&q=85",
  "description": "Sữa tươi 100% từ trang trại đạt chuẩn quốc tế...",
  "stock": 48
}
```

---

### 📦 Phân hệ 2: Đơn hàng Khách hàng (ROLE: CUSTOMER)

| Phương thức | Endpoint | Mô tả |
|---|---|---|
| `POST` | `/api/orders` | Đặt đơn hàng mới từ giỏ |
| `GET` | `/api/orders` | Lấy lịch sử đơn của tài khoản đang đăng nhập |
| `GET` | `/api/orders/{id}` | Chi tiết đơn |
| `PATCH` | `/api/orders/{id}/cancel` | Hủy đơn khi đang ở trạng thái 'Chờ xác nhận' |

---

### 🏢 Phân hệ 3: Nghiệp vụ Nhân viên siêu thị (ROLE: STAFF)

> Phân hệ này ánh xạ trực tiếp từ `StaffController` và `StaffWorkspace` trong ứng dụng di động.

#### 1. Sơ đồ kệ hàng (`GET /api/staff/shelves`)
- Hệ thống có 9 kệ:
  - Dãy A: `A1` (Sữa & chế phẩm - sức chứa 120), `A2` (Nước giải khát - 100), `A3` (Bánh kẹo - 100)
  - Dãy B: `B1` (Gia vị - 80), `B2` (Đồ khô - 100), `B3` (Chăm sóc nhà - 80)
  - Dãy C: `C1` (Thực phẩm lạnh - 80), `C2` (Hàng mới về - 80), `C3` (Kho dự trữ - 100)
- **Mỗi kệ có 4 tầng (tier 1 đến 4)**.
- **Quy tắc**: Mỗi tầng chỉ chứa **duy nhất 1 loại sản phẩm**.
- **Response mẫu**:
  ```json
  [
    {
      "code": "A1",
      "category": "Sữa & chế phẩm",
      "capacity": 120,
      "fillPercent": 24,
      "tiers": [
        { "tier": 1, "productId": "milk", "productName": "Sữa tươi Vinamilk 1L", "quantity": 24 },
        { "tier": 2, "productId": "eggs", "productName": "Trứng gà tươi 10 quả", "quantity": 5 },
        { "tier": 3, "productId": null, "quantity": 0 },
        { "tier": 4, "productId": null, "quantity": 0 }
      ]
    }
  ]
  ```

#### 2. Tồn kho dự trữ (`GET /api/staff/warehouse`)
- Trả về số lượng từng sản phẩm đang lưu trong kho phía sau (chưa đưa lên kệ).
  ```json
  [
    { "productId": "milk", "productName": "Sữa tươi Vinamilk 1L", "quantity": 24 },
    { "productId": "apple", "productName": "Táo Envy Mỹ 1kg", "quantity": 18 }
  ]
  ```

#### 3. Tiếp nhận hàng nhập kho (`POST /api/staff/stock-receipts`)
- Ghi nhận kiện hàng mới nhập về kho dự trữ.
- **Request Body**:
  ```json
  {
    "productId": "milk",
    "quantity": 20
  }
  ```
- **Xử lý Backend**: Cộng `quantity` vào kho dự trữ của `productId`, lưu lịch sử phiếu nhập `stock_receipts`.

#### 4. Chuyển hàng từ kho lên tầng kệ (`POST /api/staff/shelf-moves`)
- **Request Body**:
  ```json
  {
    "shelfCode": "A1",
    "tier": 3,
    "productId": "milk",
    "quantity": 6
  }
  ```
- **Ràng buộc nghiệp vụ quan trọng (Validation)**:
  1. `quantity` phải > 0.
  2. Số lượng trong kho dự trữ phải >= `quantity`. Nếu không đủ trả `400 Bad Request: "Kho chỉ còn X sản phẩm này."`
  3. Tầng `tier` của kệ `shelfCode` **không được chứa sản phẩm khác** loại đang chuyển lên. Nếu đã có sản phẩm khác, trả `400 Bad Request: "Tầng 3 của kệ A1 đã chứa sản phẩm khác."`
  4. Nếu hợp lệ: Trừ tồn kho dự trữ, cộng vào tầng kệ tương ứng.

#### 5. Bán hàng tại quầy POS (`POST /api/staff/sales`)
- Nhân viên quét mã vạch sản phẩm thanh toán trực tiếp cho khách tại quầy thu ngân.
- **Request Body**:
  ```json
  {
    "lines": [
      { "productId": "milk", "quantity": 2, "price": 36500 }
    ],
    "total": 73000
  }
  ```
- **Xử lý Backend**:
  1. Kiểm tra tổng số lượng sản phẩm trên các kệ có đủ để xuất không.
  2. Trừ tồn trực tiếp trên các tầng kệ đang chứa sản phẩm đó.
  3. Tạo hóa đơn với mã định dạng: `SSM-YYYYMM-XXXX` (VD: `SSM-202610-0001`).
  4. Trả về thông tin hóa đơn hoàn tất.

#### 6. Chấm công nhân viên (`POST /api/staff/attendance`)
- **Request Body**:
  ```json
  {
    "type": "CHECK_IN", // hoặc "CHECK_OUT"
    "timestamp": "2026-10-16T08:00:00"
  }
  ```

---

## 4. Thiết Kế Cơ Sở Dữ Liệu Quan Hệ (SQL DDL)

Backend developer có thể chạy trực tiếp kịch bản SQL này trên MySQL hoặc PostgreSQL:

```sql
-- 1. Bảng người dùng & phân quyền
CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER', -- 'CUSTOMER' hoặc 'STAFF'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng sản phẩm
CREATE TABLE products (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    selling_price BIGINT NOT NULL,      -- Giá bán (price)
    old_price BIGINT,                   -- Giá gốc (oldPrice)
    import_price BIGINT,                -- Giá nhập (importPrice)
    barcode VARCHAR(50) UNIQUE,
    rating DOUBLE DEFAULT 5.0,
    category VARCHAR(100) NOT NULL,
    image_url TEXT,
    brand VARCHAR(100),
    package_size VARCHAR(50),
    description TEXT,
    quantity INT DEFAULT 0              -- Tổng tồn (kho + kệ)
);

-- 3. Bảng kho dự trữ (Warehouse)
CREATE TABLE warehouse_stock (
    product_id VARCHAR(50) PRIMARY KEY,
    quantity INT NOT NULL DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- 4. Bảng lịch sử nhập kho (Stock Receipts)
CREATE TABLE stock_receipts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    staff_id VARCHAR(50),
    quantity INT NOT NULL,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (staff_id) REFERENCES users(id)
);

-- 5. Bảng kệ hàng (Shelves)
CREATE TABLE shelves (
    code VARCHAR(10) PRIMARY KEY,       -- 'A1', 'A2', 'B1',...
    category VARCHAR(100) NOT NULL,
    capacity INT NOT NULL DEFAULT 100
);

-- 6. Chi tiết hàng trên từng tầng kệ (Mỗi kệ có 4 tầng, mỗi tầng chỉ 1 sản phẩm)
CREATE TABLE shelf_tiers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    shelf_code VARCHAR(10) NOT NULL,
    tier INT NOT NULL CHECK (tier BETWEEN 1 AND 4),
    product_id VARCHAR(50),
    quantity INT NOT NULL DEFAULT 0,
    UNIQUE KEY uk_shelf_tier (shelf_code, tier),
    FOREIGN KEY (shelf_code) REFERENCES shelves(code) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
);

-- 7. Hóa đơn bán hàng tại quầy POS (Staff Sales)
CREATE TABLE pos_sales (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL, -- 'SSM-202610-0001'
    staff_id VARCHAR(50),
    total BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES users(id)
);

CREATE TABLE pos_sale_lines (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sale_id BIGINT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    price BIGINT NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- 8. Bảng chấm công (Attendance)
CREATE TABLE attendance (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    staff_id VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    status VARCHAR(30) DEFAULT 'Đúng giờ',
    FOREIGN KEY (staff_id) REFERENCES users(id)
);
```

---

## 5. Phân Chia Giao Diện Phía Frontend Khi Có Database

Khi Backend triển khai xong bảng `users` với cột `role`:
1. **Khách hàng (`role == "CUSTOMER"`)**:
   - Ứng dụng hiển thị 5 tab: **Trang chủ, Danh mục, Quét mã QR, Giỏ hàng, Đơn hàng**.
   - Mở Menu bên trái: **Ẩn mục "Khu vực nhân viên"**. Khách hàng không thể bấm vào để xem sơ đồ kệ hay nhập kho.
2. **Nhân viên (`role == "STAFF"`)**:
   - Khi đăng nhập tài khoản nhân viên, App sẽ hiển thị tùy chọn:
     - Chuyển thẳng vào **Không gian làm việc nhân viên (`StaffWorkspace`)** gồm 4 tab: Sơ đồ kệ, Kho hàng, Bán hàng POS, Chấm công.
     - Hoặc có nút gạt chuyển đổi linh hoạt giữa chế độ Mua sắm và Chế độ Nhân viên.
   - Khi thao tác xuất hóa đơn POS hoặc chuyển kệ, app sẽ gửi token kèm quyền `STAFF` lên máy chủ.
