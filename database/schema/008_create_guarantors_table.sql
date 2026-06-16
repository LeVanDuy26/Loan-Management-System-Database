-- ============================================================================
-- Migration: Tạo bảng guarantors (Người bảo lãnh)
-- Mô tả: Bảng lưu trữ thông tin người bảo lãnh cho khoản vay.
--         Người bảo lãnh là người cam kết trả nợ thay khách hàng nếu khách hàng
--         không có khả năng thanh toán. Đây là "lớp bảo vệ thứ hai" sau tài sản
--         thế chấp (collateral), giúp ngân hàng phân tán rủi ro.
--         Một hợp đồng có thể có NHIỀU người bảo lãnh, mỗi người bảo lãnh
--         một phần số tiền (không nhất thiết bảo lãnh toàn bộ).
-- Phụ thuộc: Bảng loan_contracts (phải tạo trước)
-- Thứ tự chạy: 8/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS guarantors (
    -- === KHÓA CHÍNH ===
    guarantor_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - HỢP ĐỒNG VAY ===
    -- Liên kết người bảo lãnh với hợp đồng vay
    -- Quan hệ 1:N - Một hợp đồng có thể có nhiều người bảo lãnh
    -- Ví dụ: 3 người bảo lãnh, mỗi người 150 triệu cho khoản vay 480 triệu
    contract_id BIGINT UNSIGNED NOT NULL,

    -- === THÔNG TIN CÁ NHÂN CỦA NGƯỜI BẢO LÃNH ===

    -- Họ tên đầy đủ
    full_name VARCHAR(255) NOT NULL,

    -- Số CMND/CCCD - dùng để xác minh danh tính người bảo lãnh
    -- NOT NULL: Bắt buộc để xác minh tính pháp lý
    id_number VARCHAR(50) NOT NULL,

    -- Số điện thoại - liên lạc khi cần người bảo lãnh thực hiện nghĩa vụ
    phone VARCHAR(20) NOT NULL,

    -- Email (không bắt buộc)
    email VARCHAR(255),

    -- Địa chỉ (không bắt buộc nhưng nên có để liên lạc)
    address TEXT,

    -- === MỐI QUAN HỆ VỚI KHÁCH HÀNG VAY ===
    -- Mối quan hệ giữa người bảo lãnh và người vay
    -- Ví dụ: 'Bố', 'Mẹ', 'Anh trai', 'Chị gái', 'Vợ/Chồng', 'Bạn thân', 'Đồng nghiệp'
    -- Thông tin này quan trọng cho phân tích rủi ro:
    --   → Người thân thường có động lực bảo lãnh mạnh hơn
    relationship_with_customer VARCHAR(100),

    -- === SỐ TIỀN BẢO LÃNH ===
    -- Số tiền tối đa mà người bảo lãnh cam kết trả thay
    -- KHÔNG NHẤT THIẾT bằng toàn bộ khoản vay
    -- Ví dụ: Khoản vay 480 triệu, người bảo lãnh chỉ cam kết 200 triệu
    -- DECIMAL(15,2): Đảm bảo độ chính xác cho tiền tệ
    guarantee_amount DECIMAL(15, 2) NOT NULL,

    -- === TRẠNG THÁI BẢO LÃNH ===
    --   'active'   : Đang bảo lãnh - nghĩa vụ bảo lãnh còn hiệu lực
    --   'released' : Đã giải phóng - hết nghĩa vụ (khoản vay đã đóng hoặc được thay thế)
    -- DEFAULT 'active': Người bảo lãnh mới thêm mặc định ở trạng thái đang bảo lãnh
    status ENUM('active', 'released') DEFAULT 'active',

    -- === DẤU THỜI GIAN ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (guarantor_id),
    -- Chỉ mục cho contract_id: Tìm tất cả người bảo lãnh của 1 hợp đồng
    KEY idx_contract_id (contract_id),
    -- Chỉ mục cho số CMND/CCCD: Tìm kiếm/kiểm tra trùng lặp người bảo lãnh
    -- Lưu ý: Không đặt UNIQUE vì 1 người có thể bảo lãnh cho nhiều hợp đồng
    KEY idx_id_number (id_number),
    KEY idx_status (status),
    KEY idx_created_at (created_at),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    -- Liên kết với hợp đồng vay
    -- ON DELETE RESTRICT: KHÔNG cho xóa hợp đồng nếu có người bảo lãnh
    CONSTRAINT fk_guarantors_contract 
        FOREIGN KEY (contract_id) 
        REFERENCES loan_contracts(contract_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Số tiền bảo lãnh phải lớn hơn 0
    -- (người bảo lãnh phải cam kết ít nhất 1 đồng, không thể bảo lãnh 0 đồng)
    CONSTRAINT chk_guarantee_amount_positive 
        CHECK (guarantee_amount > 0)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

