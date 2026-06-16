-- ============================================================================
-- Migration: Tạo bảng customers (Khách hàng)
-- Mô tả: Bảng cốt lõi lưu trữ toàn bộ thông tin khách hàng trong hệ thống 
--         quản lý khoản vay. Đây là bảng gốc mà nhiều bảng khác sẽ tham chiếu
--         đến thông qua khóa ngoại (foreign key).
-- Thứ tự chạy: 1/13 (chạy đầu tiên vì không phụ thuộc bảng nào khác)
-- ============================================================================

CREATE TABLE IF NOT EXISTS customers (
    -- === KHÓA CHÍNH (Primary Key) ===
    -- Mã định danh duy nhất của khách hàng trong hệ thống
    -- BIGINT UNSIGNED: Số nguyên lớn không âm (0 đến 18,446,744,073,709,551,615)
    --   → Dùng BIGINT thay vì INT để hỗ trợ mở rộng hệ thống trong tương lai
    -- AUTO_INCREMENT: Tự động tăng giá trị mỗi khi thêm bản ghi mới
    -- NOT NULL: Không được phép để trống
    customer_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === MÃ KHÁCH HÀNG (Business Key) ===
    -- Mã khách hàng do nghiệp vụ quy định (ví dụ: 'CUST001', 'CUST002')
    -- Khác với customer_id (khóa kỹ thuật), đây là mã nghiệp vụ hiển thị cho người dùng
    -- VARCHAR(50): Chuỗi ký tự có độ dài tối đa 50 ký tự
    -- NOT NULL: Bắt buộc phải có giá trị (mỗi khách hàng phải có mã)
    customer_code VARCHAR(50) NOT NULL,

    -- === HỌ VÀ TÊN ===
    -- Tên đầy đủ của khách hàng (ví dụ: 'Nguyễn Văn An')
    -- VARCHAR(255): Tối đa 255 ký tự, đủ cho tên người Việt Nam
    full_name VARCHAR(255) NOT NULL,

    -- === SỐ CMND/CCCD ===
    -- Số Chứng minh nhân dân hoặc Căn cước công dân
    -- Đây là thông tin nhạy cảm, trong production nên được mã hóa (encryption)
    -- NOT NULL: Bắt buộc vì đây là giấy tờ xác minh danh tính khi vay
    id_number VARCHAR(50) NOT NULL,

    -- === SỐ ĐIỆN THOẠI ===
    -- Số điện thoại liên lạc chính của khách hàng
    -- VARCHAR(20): Đủ chứa số điện thoại quốc tế (ví dụ: '+84912345678')
    -- NOT NULL: Bắt buộc vì cần liên lạc khách hàng trong suốt vòng đời khoản vay
    phone VARCHAR(20) NOT NULL,

    -- === EMAIL ===
    -- Địa chỉ email của khách hàng
    -- Không bắt buộc (NULL được phép) vì không phải khách hàng nào cũng có email
    email VARCHAR(255),

    -- === ĐỊA CHỈ ===
    -- Địa chỉ cư trú hoặc liên lạc của khách hàng
    -- TEXT: Kiểu dữ liệu văn bản dài, phù hợp cho địa chỉ chi tiết
    -- Không bắt buộc (có thể bổ sung sau)
    address TEXT,

    -- === NGÀY SINH ===
    -- Ngày tháng năm sinh của khách hàng
    -- DATE: Định dạng 'YYYY-MM-DD' (ví dụ: '1990-05-15')
    -- Dùng để xác minh tuổi (phải trên 18 tuổi mới được vay)
    date_of_birth DATE,

    -- === GIỚI TÍNH ===
    -- ENUM: Chỉ cho phép 3 giá trị: 'male' (nam), 'female' (nữ), 'other' (khác)
    -- DEFAULT NULL: Mặc định là NULL nếu không cung cấp
    gender ENUM('male', 'female', 'other') DEFAULT NULL,

    -- === NGHỀ NGHIỆP ===
    -- Nghề nghiệp hiện tại của khách hàng (ví dụ: 'Kỹ sư phần mềm', 'Bác sĩ')
    -- Thông tin này ảnh hưởng đến đánh giá khả năng trả nợ (creditworthiness)
    occupation VARCHAR(255),

    -- === TRẠNG THÁI KHÁCH HÀNG ===
    -- Quản lý trạng thái hoạt động của khách hàng trong hệ thống:
    --   'active'      : Đang hoạt động bình thường, có thể tạo đơn vay mới
    --   'inactive'    : Tạm ngưng hoạt động (ví dụ: không giao dịch lâu)
    --   'blacklisted' : Bị đưa vào danh sách đen (ví dụ: nợ xấu, gian lận)
    --                   → Khách hàng blacklisted KHÔNG được phép tạo đơn vay mới
    -- DEFAULT 'active': Khách hàng mới tạo mặc định ở trạng thái hoạt động
    status ENUM('active', 'inactive', 'blacklisted') DEFAULT 'active',

    -- === DẤU THỜI GIAN (Timestamps) ===
    -- Thời điểm tạo bản ghi, tự động gán khi INSERT
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Thời điểm cập nhật lần cuối, tự động cập nhật khi UPDATE
    -- ON UPDATE CURRENT_TIMESTAMP: MySQL tự động gán thời gian hiện tại khi có thay đổi
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC (Constraints & Indexes)
    -- ============================================================================

    -- Khóa chính: Đảm bảo mỗi customer_id là duy nhất và không NULL
    PRIMARY KEY (customer_id),

    -- Ràng buộc UNIQUE cho mã khách hàng: Không cho phép 2 khách hàng có cùng mã
    -- 'uk_' là tiền tố đặt tên theo quy ước cho Unique Key
    UNIQUE KEY uk_customer_code (customer_code),

    -- Ràng buộc UNIQUE cho số CMND/CCCD: Mỗi số định danh cá nhân chỉ thuộc về 1 người
    UNIQUE KEY uk_id_number (id_number),

    -- Chỉ mục (Index) cho số điện thoại: Tăng tốc tìm kiếm khách hàng theo SĐT
    -- 'idx_' là tiền tố đặt tên theo quy ước cho Index
    KEY idx_phone (phone),

    -- Chỉ mục cho email: Tăng tốc tìm kiếm khách hàng theo email
    KEY idx_email (email),

    -- Chỉ mục cho trạng thái: Tăng tốc lọc khách hàng theo status
    -- (ví dụ: SELECT * FROM customers WHERE status = 'active')
    KEY idx_status (status),

    -- Chỉ mục cho ngày tạo: Tăng tốc sắp xếp và lọc theo thời gian tạo
    KEY idx_created_at (created_at)

-- ============================================================================
-- CẤU HÌNH BẢNG
-- ============================================================================
-- ENGINE=InnoDB       : Sử dụng engine InnoDB hỗ trợ transaction, foreign key, row-level locking
-- DEFAULT CHARSET     : utf8mb4 hỗ trợ đầy đủ Unicode (bao gồm emoji và tiếng Việt có dấu)
-- COLLATE             : utf8mb4_unicode_ci cho phép so sánh chuỗi không phân biệt hoa/thường
--                       và hỗ trợ sắp xếp đúng cho tiếng Việt
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

