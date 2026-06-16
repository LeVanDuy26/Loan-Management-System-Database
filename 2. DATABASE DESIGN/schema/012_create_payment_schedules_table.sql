-- ============================================================================
-- Migration: Tạo bảng payment_schedules (Lịch trả nợ)
-- Mô tả: Bảng lưu trữ lịch trả nợ định kỳ (từng kỳ trả góp) cho mỗi hợp đồng.
--         Đây là MỘT TRONG NHỮNG BẢNG QUAN TRỌNG NHẤT và ĐƯỢC QUERY NHIỀU NHẤT
--         trong toàn bộ hệ thống (hàng nghìn queries mỗi giờ).
--         
--         Mỗi hợp đồng có N kỳ trả góp (installments), mỗi kỳ bao gồm:
--           - Tiền gốc đến hạn (principal_due): Phần gốc phải trả kỳ này
--           - Tiền lãi đến hạn (interest_due): Phần lãi phải trả kỳ này
--           - Tổng phải trả (total_due = principal_due + interest_due)
--           - Số tiền đã trả (paid_amount): Khách hàng đã trả bao nhiêu
--           - Số tiền còn nợ (outstanding_amount = total_due - paid_amount)
--         
--         Triggers tự động:
--           - Tính outstanding_amount khi INSERT
--           - Cập nhật outstanding_amount và status khi UPDATE
--           - Tự động chuyển status sang 'paid' khi paid_amount >= total_due
--           - Tự động chuyển status sang 'overdue' khi quá hạn chưa trả
-- Phụ thuộc: Bảng loan_contracts (phải tạo trước)
-- Thứ tự chạy: 12/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_schedules (
    -- === KHÓA CHÍNH ===
    schedule_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - HỢP ĐỒNG VAY ===
    -- Liên kết lịch trả nợ với hợp đồng vay
    -- Quan hệ 1:N - Một hợp đồng có nhiều kỳ trả (= term_months kỳ)
    -- Ví dụ: Hợp đồng 24 tháng → 24 bản ghi payment_schedules
    contract_id BIGINT UNSIGNED NOT NULL,

    -- === SỐ KỲ TRẢ ===
    -- Thứ tự kỳ trả góp (1, 2, 3, ..., N)
    -- INT UNSIGNED: Số nguyên không âm
    -- NOT NULL: Mỗi kỳ phải có số thứ tự
    -- CHECK: installment_number > 0
    -- UNIQUE KEY: Kết hợp với contract_id → Mỗi hợp đồng chỉ có 1 kỳ số N
    installment_number INT UNSIGNED NOT NULL,

    -- === NGÀY ĐẾN HẠN ===
    -- Ngày khách hàng phải thanh toán kỳ này
    -- Là cột ĐƯỢC QUERY NHIỀU NHẤT - cần index để tối ưu hiệu suất
    -- Trigger kiểm tra: due_date >= disbursement_date
    due_date DATE NOT NULL,

    -- === SỐ TIỀN GỐC ĐẾN HẠN ===
    -- Phần tiền gốc phải trả trong kỳ này
    -- Những kỳ đầu: principal_due THẤP hơn (trả nhiều lãi hơn)
    -- Những kỳ cuối: principal_due CAO hơn (trả ít lãi hơn)
    -- → Đây là đặc điểm của phương pháp trả góp đều (equal installment / amortization)
    principal_due DECIMAL(15, 2) NOT NULL DEFAULT 0,

    -- === SỐ TIỀN LÃI ĐẾN HẠN ===
    -- Phần tiền lãi phải trả trong kỳ này
    -- Tính dựa trên: dư nợ gốc còn lại × lãi suất tháng
    -- Giảm dần qua các kỳ vì dư nợ gốc giảm dần
    interest_due DECIMAL(15, 2) NOT NULL DEFAULT 0,

    -- === TỔNG SỐ TIỀN PHẢI TRẢ ===
    -- total_due = principal_due + interest_due
    -- CHECK constraint đảm bảo tính nhất quán
    total_due DECIMAL(15, 2) NOT NULL,

    -- === SỐ TIỀN ĐÃ TRẢ ===
    -- Số tiền khách hàng đã thanh toán cho kỳ này
    -- DEFAULT 0: Ban đầu chưa trả gì
    -- Khi paid_amount >= total_due → trigger tự động chuyển status = 'paid'
    paid_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,

    -- === SỐ TIỀN CÒN NỢ ===
    -- outstanding_amount = total_due - paid_amount
    -- Được tự động tính bằng trigger (BEFORE INSERT và BEFORE UPDATE)
    -- Khi = 0: Kỳ này đã trả xong
    -- Khi > 0: Vẫn còn nợ
    outstanding_amount DECIMAL(15, 2) NOT NULL,

    -- === TRẠNG THÁI KỲ TRẢ ===
    -- Quản lý trạng thái từng kỳ trả góp:
    --   'pending' : Chưa đến hạn - đang chờ đến ngày due_date
    --   'paid'    : Đã trả - khách hàng đã thanh toán đủ
    --   'overdue' : Quá hạn - đã qua due_date mà chưa trả (hoặc trả chưa đủ)
    --               → Đây là trạng thái được theo dõi sát nhất bởi bộ phận thu hồi
    --   'waived'  : Được miễn - ngân hàng miễn giảm cho kỳ này 
    --               (trong trường hợp cơ cấu lại nợ / restructuring)
    -- DEFAULT 'pending': Kỳ trả mới tạo mặc định ở trạng thái chưa đến hạn
    -- Trigger tự động cập nhật status dựa trên paid_amount và due_date
    status ENUM('pending', 'paid', 'overdue', 'waived') DEFAULT 'pending',

    -- === DẤU THỜI GIAN ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Thời điểm thanh toán xong kỳ này (trigger tự set khi paid_amount >= total_due)
    paid_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (schedule_id),
    KEY idx_contract_id (contract_id),
    -- Chỉ mục cho số kỳ trả: Sắp xếp các kỳ theo thứ tự
    KEY idx_installment_number (installment_number),
    -- Chỉ mục cho ngày đến hạn: CỰC KỲ QUAN TRỌNG cho hiệu suất
    -- Được query liên tục để tìm: "Hôm nay có bao nhiêu kỳ đến hạn?"
    KEY idx_due_date (due_date),
    KEY idx_status (status),
    -- Chỉ mục kết hợp: contract_id + status
    -- Tối ưu truy vấn: "Lấy tất cả kỳ overdue của hợp đồng X"
    KEY idx_contract_status (contract_id, status),
    -- Chỉ mục kết hợp: contract_id + due_date  
    -- Tối ưu truy vấn: "Kỳ trả tiếp theo của hợp đồng X là khi nào?"
    KEY idx_contract_due_date (contract_id, due_date),
    KEY idx_created_at (created_at),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    -- Liên kết với hợp đồng vay
    -- ON DELETE CASCADE: Xóa hợp đồng → xóa luôn tất cả lịch trả nợ
    --   → Lịch trả nợ không có ý nghĩa nếu không có hợp đồng
    CONSTRAINT fk_payment_schedules_contract 
        FOREIGN KEY (contract_id) 
        REFERENCES loan_contracts(contract_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Tất cả các giá trị tiền phải không âm (>= 0)
    CONSTRAINT chk_payment_amounts_non_negative 
        CHECK (principal_due >= 0 AND interest_due >= 0 AND total_due >= 0 AND paid_amount >= 0 AND outstanding_amount >= 0),
    
    -- Ràng buộc TOÁN HỌC: Tổng phải trả = gốc + lãi
    -- Đảm bảo tính nhất quán giữa 3 cột
    CONSTRAINT chk_total_due_equals_sum 
        CHECK (total_due = principal_due + interest_due),
    
    -- Ràng buộc TOÁN HỌC: Số tiền còn nợ = tổng phải trả - đã trả
    -- Đảm bảo outstanding_amount luôn chính xác
    CONSTRAINT chk_outstanding_equals_due_minus_paid 
        CHECK (outstanding_amount = total_due - paid_amount),
    
    -- Số kỳ trả phải lớn hơn 0
    CONSTRAINT chk_installment_number_positive 
        CHECK (installment_number > 0),
    
    -- Ràng buộc UNIQUE kết hợp: Mỗi hợp đồng chỉ có 1 kỳ thứ N
    -- Ví dụ: Hợp đồng 1 không thể có 2 kỳ số 5
    UNIQUE KEY uk_contract_installment (contract_id, installment_number)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TRIGGER 1: Tự động tính outstanding_amount khi thêm kỳ trả mới
-- ============================================================================
-- Mục đích: Khi INSERT bản ghi mới, tự động tính:
--           outstanding_amount = total_due - paid_amount
-- Đảm bảo giá trị outstanding_amount luôn chính xác ngay từ lúc tạo
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_calculate_outstanding_amount
BEFORE INSERT ON payment_schedules
FOR EACH ROW
BEGIN
    -- Tự động tính số tiền còn nợ = tổng phải trả - đã trả
    SET NEW.outstanding_amount = NEW.total_due - NEW.paid_amount;
END//
DELIMITER ;

-- ============================================================================
-- TRIGGER 2: Tự động cập nhật outstanding_amount và status khi UPDATE
-- ============================================================================
-- Mục đích: Khi khách hàng thanh toán (UPDATE paid_amount), trigger sẽ:
--   1) Tính lại outstanding_amount = total_due - paid_amount
--   2) Tự động chuyển status sang 'paid' nếu paid_amount >= total_due
--      → Đồng thời ghi nhận paid_at (thời điểm trả xong)
--   3) Tự động chuyển status sang 'overdue' nếu:
--      → Chưa trả (paid_amount = 0) VÀ đã quá ngày đến hạn (due_date < hôm nay)
-- Đây là trigger QUAN TRỌNG NHẤT vì nó tự động hóa việc quản lý trạng thái
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_update_outstanding_amount
BEFORE UPDATE ON payment_schedules
FOR EACH ROW
BEGIN
    -- Bước 1: Tính lại số tiền còn nợ
    SET NEW.outstanding_amount = NEW.total_due - NEW.paid_amount;
    
    -- Bước 2: Tự động cập nhật trạng thái dựa trên số tiền đã trả
    -- Nếu đã trả đủ hoặc hơn → chuyển status sang 'paid'
    IF NEW.paid_amount >= NEW.total_due THEN
        SET NEW.status = 'paid';
        -- Ghi nhận thời điểm trả xong (nếu chưa có)
        IF NEW.paid_at IS NULL THEN
            SET NEW.paid_at = CURRENT_TIMESTAMP;
        END IF;
    -- Nếu chưa trả gì VÀ đã quá hạn → chuyển status sang 'overdue'
    ELSEIF NEW.paid_amount = 0 AND NEW.due_date < CURDATE() THEN
        SET NEW.status = 'overdue';
    END IF;
END//
DELIMITER ;

