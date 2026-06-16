-- ============================================================================
-- Migration: Tạo bảng disbursements (Giải ngân)
-- Mô tả: Bảng lưu trữ các giao dịch giải ngân tiền cho hợp đồng vay.
--         Một hợp đồng có thể có NHIỀU lần giải ngân (partial disbursement).
--         Ví dụ: Vay xây nhà có thể giải ngân theo tiến độ xây dựng
--           - Lần 1: 200 triệu khi hoàn thiện móng
--           - Lần 2: 150 triệu khi xây tường  
--           - Lần 3: 130 triệu khi hoàn thiện mái
--         Quy tắc quan trọng: Tổng giải ngân KHÔNG được vượt quá số tiền gốc (principal_amount)
-- Phụ thuộc: Bảng loan_contracts (phải tạo trước)
-- Thứ tự chạy: 4/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS disbursements (
    -- === KHÓA CHÍNH ===
    -- Mã định danh duy nhất cho mỗi giao dịch giải ngân
    disbursement_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - HỢP ĐỒNG VAY ===
    -- Liên kết giao dịch giải ngân với hợp đồng vay
    -- Quan hệ 1:N - Một hợp đồng có thể có nhiều lần giải ngân
    contract_id BIGINT UNSIGNED NOT NULL,

    -- === MÃ GIẢI NGÂN (Business Key) ===
    -- Mã giao dịch giải ngân (ví dụ: 'DISB-20240120-000001')
    -- Được tự động tạo bằng trigger nếu không cung cấp
    disbursement_number VARCHAR(50) NOT NULL,

    -- === SỐ TIỀN GIẢI NGÂN ===
    -- Số tiền được giải ngân trong lần này
    -- Trigger sẽ kiểm tra: tổng tất cả giải ngân <= principal_amount
    amount DECIMAL(15, 2) NOT NULL,

    -- === NGÀY GIẢI NGÂN ===
    -- Ngày thực hiện giao dịch giải ngân
    -- NOT NULL: Mỗi giao dịch giải ngân phải có ngày cụ thể
    -- Trigger sẽ kiểm tra: ngày giải ngân không được ở tương lai
    disbursement_date DATE NOT NULL,

    -- === PHƯƠNG THỨC GIẢI NGÂN ===
    -- Cách thức chuyển tiền cho khách hàng:
    --   'bank_transfer' : Chuyển khoản ngân hàng (phổ biến nhất, an toàn)
    --   'cash'          : Tiền mặt (ít dùng, chỉ cho khoản nhỏ)
    --   'check'         : Séc ngân hàng
    --   'other'         : Phương thức khác
    -- DEFAULT 'bank_transfer': Mặc định chuyển khoản
    disbursement_method ENUM('bank_transfer', 'cash', 'check', 'other') DEFAULT 'bank_transfer',

    -- === SỐ TÀI KHOẢN NGÂN HÀNG ===
    -- Số tài khoản nhận tiền giải ngân của khách hàng
    -- Thông tin nhạy cảm, trong production nên được mã hóa
    bank_account VARCHAR(100),

    -- === MÃ GIAO DỊCH THAM CHIẾU ===
    -- Mã tham chiếu từ hệ thống ngân hàng core (core banking system)
    -- Dùng để đối chiếu, kiểm toán giữa hai hệ thống
    transaction_reference VARCHAR(100),

    -- === TRẠNG THÁI GIẢI NGÂN ===
    -- Quản lý trạng thái của giao dịch giải ngân:
    --   'pending'   : Đang chờ xử lý - giao dịch đã tạo nhưng chưa thực hiện
    --   'completed' : Thành công - tiền đã chuyển đến tài khoản khách hàng
    --   'failed'    : Thất bại - giao dịch gặp lỗi (tài khoản đóng, lỗi hệ thống)
    --   'cancelled' : Đã hủy - giao dịch bị hủy trước khi thực hiện
    -- DEFAULT 'pending': Giao dịch mới tạo mặc định ở trạng thái chờ
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',

    -- === DẤU THỜI GIAN ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Thời điểm giải ngân hoàn tất (chỉ có giá trị khi status = 'completed')
    completed_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (disbursement_id),
    -- Mã giải ngân phải duy nhất
    UNIQUE KEY uk_disbursement_number (disbursement_number),
    -- Chỉ mục cho contract_id: Tăng tốc tìm các lần giải ngân của 1 hợp đồng
    KEY idx_contract_id (contract_id),
    -- Chỉ mục cho trạng thái
    KEY idx_status (status),
    -- Chỉ mục cho ngày giải ngân
    KEY idx_disbursement_date (disbursement_date),
    KEY idx_created_at (created_at),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    -- Liên kết với hợp đồng vay
    -- ON DELETE RESTRICT: KHÔNG cho xóa hợp đồng nếu đã có giải ngân
    CONSTRAINT fk_disbursements_contract 
        FOREIGN KEY (contract_id) 
        REFERENCES loan_contracts(contract_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Số tiền giải ngân phải lớn hơn 0
    CONSTRAINT chk_disbursement_amount_positive 
        CHECK (amount > 0)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TRIGGER 1: Tự động tạo mã giải ngân
-- ============================================================================
-- Mục đích: Sinh mã disbursement_number tự động nếu không cung cấp
-- Format: 'DISB-YYYYMMDD-NNNNNN'
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_generate_disbursement_number
BEFORE INSERT ON disbursements
FOR EACH ROW
BEGIN
    IF NEW.disbursement_number IS NULL OR NEW.disbursement_number = '' THEN
        SET NEW.disbursement_number = CONCAT('DISB-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(LAST_INSERT_ID() + 1, 6, '0'));
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- TRIGGER 2: Kiểm tra tổng giải ngân không vượt quá số tiền gốc
-- ============================================================================
-- Mục đích: Đảm bảo quy tắc nghiệp vụ quan trọng nhất của giải ngân:
--           TỔNG SỐ TIỀN ĐÃ GIẢI NGÂN + SỐ TIỀN GIẢI NGÂN MỚI <= TIỀN GỐC HỢP ĐỒNG
-- Ví dụ: Hợp đồng 480 triệu, đã giải ngân 200 triệu
--         → Lần giải ngân mới tối đa chỉ được 280 triệu
-- Nếu vi phạm: Trigger sẽ ném lỗi SQLSTATE '45000' và ROLLBACK giao dịch
-- LƯU Ý: Chỉ tính các giải ngân có status = 'completed' (đã hoàn tất)
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_validate_disbursement_amount
BEFORE INSERT ON disbursements
FOR EACH ROW
BEGIN
    -- Biến lưu số tiền gốc của hợp đồng
    DECLARE contract_principal DECIMAL(15, 2);
    -- Biến lưu tổng số tiền đã giải ngân thành công trước đó
    DECLARE total_disbursed DECIMAL(15, 2);
    
    -- Lấy số tiền gốc (principal_amount) từ bảng loan_contracts
    SELECT principal_amount INTO contract_principal
    FROM loan_contracts
    WHERE contract_id = NEW.contract_id;
    
    -- Tính tổng số tiền đã giải ngân THÀNH CÔNG cho hợp đồng này
    -- COALESCE(..., 0): Trả về 0 nếu chưa có giải ngân nào (tránh NULL)
    -- Chỉ tính các giải ngân có status = 'completed'
    SELECT COALESCE(SUM(amount), 0) INTO total_disbursed
    FROM disbursements
    WHERE contract_id = NEW.contract_id AND status = 'completed';
    
    -- Kiểm tra: tổng đã giải ngân + lần giải ngân mới có vượt quá tiền gốc không?
    IF (total_disbursed + NEW.amount) > contract_principal THEN
        -- Nếu vượt quá → Ném lỗi và hủy giao dịch INSERT
        -- SQLSTATE '45000': Mã lỗi do người dùng tự định nghĩa
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Total disbursement amount cannot exceed contract principal amount';
    END IF;
END//
DELIMITER ;

