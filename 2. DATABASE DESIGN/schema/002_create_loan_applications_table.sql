-- ============================================================================
-- Migration: Tạo bảng loan_applications (Đơn xin vay)
-- Mô tả: Bảng lưu trữ tất cả đơn xin vay của khách hàng.
--         Mỗi đơn vay đại diện cho một yêu cầu vay tiền, trải qua các trạng thái
--         từ "chờ duyệt" đến "được duyệt", "bị từ chối" hoặc "đã hủy".
--         Chỉ đơn nào có status = 'approved' mới được phép tạo hợp đồng vay.
-- Phụ thuộc: Bảng customers (phải tạo trước)
-- Thứ tự chạy: 2/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS loan_applications (
    -- === KHÓA CHÍNH ===
    -- Mã định danh duy nhất cho mỗi đơn xin vay
    application_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

-- === KHÓA NGOẠI - KHÁCH HÀNG ===
-- Liên kết đơn vay với khách hàng đã nộp đơn
-- Một khách hàng (customer) có thể nộp nhiều đơn vay (quan hệ 1:N)
customer_id BIGINT UNSIGNED NOT NULL,

-- === MÃ ĐƠN VAY (Business Key) ===
-- Mã đơn vay theo định dạng nghiệp vụ (ví dụ: 'APP-20240115-000001')
-- Được tự động tạo bằng trigger nếu không cung cấp khi INSERT
-- NOT NULL + UNIQUE: Mỗi đơn vay phải có mã riêng biệt
application_number VARCHAR(50) NOT NULL,

-- === SỐ TIỀN VAY YÊU CẦU ===
-- Số tiền mà khách hàng muốn vay (đơn vị: VNĐ)
-- DECIMAL(15,2): Tối đa 15 chữ số, 2 chữ số thập phân
--   → Hỗ trợ số tiền lên đến 9,999,999,999,999.99 (gần 10 nghìn tỷ)
--   → Dùng DECIMAL thay vì FLOAT/DOUBLE để đảm bảo độ chính xác tuyệt đối cho tiền tệ
-- NOT NULL: Bắt buộc phải có số tiền vay
loan_amount DECIMAL(15, 2) NOT NULL,

-- === KỲ HẠN VAY YÊU CẦU ===
-- Số tháng mà khách hàng muốn vay (ví dụ: 12, 24, 36, 48, 60 tháng)
-- INT UNSIGNED: Số nguyên không âm
-- NOT NULL: Bắt buộc phải có kỳ hạn
requested_term_months INT UNSIGNED NOT NULL,

-- === MỤC ĐÍCH VAY ===
-- Lý do/mục đích vay tiền (ví dụ: 'Mua nhà', 'Kinh doanh', 'Mua xe ô tô')
-- VARCHAR(500): Cho phép mô tả chi tiết mục đích vay
-- Không bắt buộc nhưng thường được yêu cầu trong thẩm định
purpose VARCHAR(500),

-- === TRẠNG THÁI ĐƠN VAY ===
-- Quản lý vòng đời (lifecycle) của đơn xin vay:
--   'pending'   : Chờ xử lý - đơn vừa được nộp, đang chờ thẩm định
--   'approved'  : Đã duyệt - đơn được chấp thuận, có thể tạo hợp đồng
--   'rejected'  : Bị từ chối - đơn không đáp ứng điều kiện vay
--   'cancelled' : Đã hủy - khách hàng hoặc hệ thống hủy đơn
-- DEFAULT 'pending': Đơn mới tạo mặc định ở trạng thái chờ xử lý
-- Quy tắc nghiệp vụ: Chỉ đơn 'approved' mới được chuyển thành hợp đồng (contract)
status ENUM(
    'pending',
    'approved',
    'rejected',
    'cancelled'
) DEFAULT 'pending',

-- === CÁC MỐC THỜI GIAN QUAN TRỌNG ===
-- Thời điểm nộp đơn: Tự động gán khi khách hàng submit đơn vay
submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
-- Thời điểm duyệt đơn: Chỉ có giá trị khi status = 'approved'
-- NULL DEFAULT NULL: Mặc định là NULL (chưa được duyệt)
approved_at TIMESTAMP NULL DEFAULT NULL,
-- Thời điểm từ chối: Chỉ có giá trị khi status = 'rejected'
rejected_at TIMESTAMP NULL DEFAULT NULL,

-- === GHI CHÚ PHÊ DUYỆT ===
-- Ghi chú của người phê duyệt (lý do duyệt/từ chối, điều kiện kèm theo)
-- TEXT: Cho phép ghi chú dài, chi tiết
-- Ví dụ: 'Phê duyệt với điều kiện có người bảo lãnh'
approval_notes TEXT,

-- === DẤU THỜI GIAN HỆ THỐNG ===
-- Thời điểm tạo bản ghi trong database
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
-- Thời điểm cập nhật lần cuối (tự động cập nhật khi có thay đổi)
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

-- ============================================================================
-- RÀNG BUỘC VÀ CHỈ MỤC
-- ============================================================================

-- Khóa chính
PRIMARY KEY (application_id),

-- Mã đơn vay phải là duy nhất trong toàn hệ thống
UNIQUE KEY uk_application_number (application_number),

-- Chỉ mục cho customer_id: Tăng tốc truy vấn tìm đơn vay theo khách hàng
-- (ví dụ: "Hiển thị tất cả đơn vay của khách hàng X")
KEY idx_customer_id (customer_id),

-- Chỉ mục cho trạng thái: Tăng tốc lọc đơn theo status
-- (ví dụ: "Lấy tất cả đơn đang chờ duyệt" - rất hay được dùng)
KEY idx_status (status),

-- Chỉ mục cho ngày nộp đơn: Tăng tốc sắp xếp và lọc theo thời gian nộp
KEY idx_submitted_at (submitted_at),

-- Chỉ mục cho ngày tạo bản ghi
KEY idx_created_at (created_at),

-- ============================================================================
-- RÀNG BUỘC KHÓA NGOẠI (Foreign Key Constraints)
-- ============================================================================

-- Liên kết đơn vay với khách hàng đã nộp đơn
-- ON DELETE RESTRICT: KHÔNG cho phép xóa khách hàng nếu vẫn còn đơn vay
--   → Bảo vệ tính toàn vẹn dữ liệu: không để đơn vay "mồ côi" (orphan records)
-- ON UPDATE CASCADE: Nếu customer_id thay đổi (hiếm khi), tự động cập nhật ở đây
CONSTRAINT fk_loan_applications_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,

-- ============================================================================
-- RÀNG BUỘC KIỂM TRA (Check Constraints)
-- ============================================================================

-- Số tiền vay phải lớn hơn 0 (không cho phép vay 0 đồng hoặc số âm)
CONSTRAINT chk_loan_amount_positive CHECK (loan_amount > 0),

-- Kỳ hạn vay phải lớn hơn 0 tháng (phải vay ít nhất 1 tháng)

CONSTRAINT chk_term_months_positive 
        CHECK (requested_term_months > 0)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TRIGGER: Tự động tạo mã đơn vay (application_number)
-- ============================================================================
-- Mục đích: Nếu đơn vay được thêm mà không có mã đơn (NULL hoặc rỗng),
--           trigger sẽ tự động sinh mã theo định dạng: 'APP-YYYYMMDD-NNNNNN'
--           Ví dụ: 'APP-20240115-000001'
-- Loại trigger: BEFORE INSERT - chạy TRƯỚC khi dữ liệu được ghi vào bảng
-- FOR EACH ROW: Áp dụng cho từng dòng dữ liệu được thêm
-- ============================================================================
DELIMITER / /

CREATE TRIGGER trg_generate_application_number
BEFORE INSERT ON loan_applications
FOR EACH ROW
BEGIN
    -- Kiểm tra nếu application_number không được cung cấp hoặc là chuỗi rỗng
    IF NEW.application_number IS NULL OR NEW.application_number = '' THEN
        -- Tạo mã tự động theo format: APP-YYYYMMDD-NNNNNN
        -- CONCAT: Nối các chuỗi lại với nhau
        -- DATE_FORMAT(NOW(), '%Y%m%d'): Lấy ngày hiện tại theo định dạng YYYYMMDD
        -- LPAD(..., 6, '0'): Đệm số thứ tự bằng số 0 bên trái cho đủ 6 chữ số
        -- LAST_INSERT_ID() + 1: Lấy ID tiếp theo (có thể không chính xác 100% khi concurrent)
        SET NEW.application_number = CONCAT('APP-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(LAST_INSERT_ID() + 1, 6, '0'));
    END IF;
END//

DELIMITER;