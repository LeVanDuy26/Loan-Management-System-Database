-- ============================================================================
-- Migration: Tạo bảng repayments (Trả nợ)
-- Mô tả: Bảng lưu trữ các giao dịch trả nợ (thanh toán) của khách hàng.
--         Mỗi lần khách hàng trả tiền sẽ tạo ra một bản ghi trong bảng này.
--         Mỗi khoản thanh toán bao gồm 3 phần:
--           - Tiền gốc (principal_amount): Phần trả vào nợ gốc
--           - Tiền lãi (interest_amount): Phần trả lãi suất
--           - Tiền phạt (penalty_amount): Phí phạt trả chậm (nếu có)
--         Tổng thanh toán = tiền gốc + tiền lãi + tiền phạt
-- Phụ thuộc: Bảng loan_contracts (phải tạo trước)
-- Thứ tự chạy: 5/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS repayments (
    -- === KHÓA CHÍNH ===
    -- Mã định danh duy nhất cho mỗi giao dịch trả nợ
    repayment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - HỢP ĐỒNG VAY ===
    -- Liên kết giao dịch trả nợ với hợp đồng vay
    -- Quan hệ 1:N - Một hợp đồng có nhiều lần trả nợ (mỗi tháng 1 lần)
    contract_id BIGINT UNSIGNED NOT NULL,

    -- === NGÀY HẸN TRẢ ===
    -- Ngày dự kiến khách hàng phải trả theo lịch trả nợ
    -- Trigger sẽ kiểm tra: scheduled_date >= disbursement_date của hợp đồng
    -- NOT NULL: Mỗi khoản trả nợ phải có ngày hẹn
    scheduled_date DATE NOT NULL,

    -- === NGÀY TRẢ THỰC TẾ ===
    -- Ngày khách hàng thực sự thanh toán
    -- NULL nếu chưa thanh toán hoặc đang quá hạn
    -- So sánh actual_payment_date vs scheduled_date để biết trả đúng hạn hay trễ
    actual_payment_date DATE,

    -- === CÁC THÀNH PHẦN THANH TOÁN ===

    -- Phần tiền gốc trong lần trả này
    -- Phần này sẽ làm giảm dư nợ gốc (outstanding principal)
    -- DEFAULT 0: Mặc định là 0 (có thể chỉ trả lãi mà chưa trả gốc)
    principal_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,

    -- Phần tiền lãi trong lần trả này
    -- Tính dựa trên dư nợ gốc còn lại × lãi suất
    interest_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,

    -- Phần tiền phạt (nếu có)
    -- Phát sinh khi khách hàng trả chậm so với scheduled_date
    -- Ví dụ: Phạt 0.05%/ngày trên số tiền quá hạn
    penalty_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,

    -- Tổng số tiền phải trả = principal + interest + penalty
    -- NOT NULL: Bắt buộc phải có giá trị tổng
    total_amount DECIMAL(15, 2) NOT NULL,

    -- === PHƯƠNG THỨC THANH TOÁN ===
    -- Cách thức khách hàng trả nợ:
    --   'bank_transfer' : Chuyển khoản ngân hàng
    --   'cash'          : Tiền mặt (trả tại quầy)
    --   'check'         : Séc
    --   'online'        : Thanh toán trực tuyến (internet banking, ví điện tử)
    --   'other'         : Phương thức khác
    payment_method ENUM('bank_transfer', 'cash', 'check', 'online', 'other') DEFAULT 'bank_transfer',

    -- === MÃ GIAO DỊCH THAM CHIẾU ===
    -- Mã tham chiếu từ hệ thống thanh toán, dùng để đối chiếu
    transaction_reference VARCHAR(100),

    -- === TRẠNG THÁI THANH TOÁN ===
    -- Quản lý trạng thái của khoản thanh toán:
    --   'scheduled' : Đã lên lịch - chưa đến ngày trả
    --   'paid'      : Đã thanh toán - khách hàng đã trả thành công
    --   'overdue'   : Quá hạn - đã quá ngày hẹn mà chưa thanh toán
    --   'waived'    : Được miễn - ngân hàng quyết định miễn khoản thanh toán này
    --                 (ví dụ: trong trường hợp cơ cấu lại nợ)
    -- DEFAULT 'scheduled': Khoản trả nợ mới tạo mặc định ở trạng thái đã lên lịch
    status ENUM('scheduled', 'paid', 'overdue', 'waived') DEFAULT 'scheduled',

    -- === DẤU THỜI GIAN ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Thời điểm thanh toán thực tế (chỉ có giá trị khi status = 'paid')
    paid_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (repayment_id),
    -- Chỉ mục cho contract_id: Tìm tất cả khoản trả nợ của 1 hợp đồng
    KEY idx_contract_id (contract_id),
    -- Chỉ mục cho ngày hẹn trả: Lọc/sắp xếp theo lịch trả nợ
    KEY idx_scheduled_date (scheduled_date),
    -- Chỉ mục cho ngày trả thực tế
    KEY idx_actual_payment_date (actual_payment_date),
    -- Chỉ mục cho trạng thái: Lọc khoản trả theo status
    KEY idx_status (status),
    KEY idx_created_at (created_at),

    -- Chỉ mục kết hợp (Composite Index): contract_id + status
    -- Tối ưu cho truy vấn kiểu: "Lấy tất cả khoản overdue của hợp đồng X"
    -- MySQL sẽ sử dụng index này thay vì quét toàn bộ bảng
    KEY idx_contract_status (contract_id, status),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    -- Liên kết với hợp đồng vay
    -- ON DELETE RESTRICT: KHÔNG cho xóa hợp đồng nếu đã có giao dịch trả nợ
    CONSTRAINT fk_repayments_contract 
        FOREIGN KEY (contract_id) 
        REFERENCES loan_contracts(contract_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Các thành phần thanh toán không được âm (>= 0)
    -- Cho phép = 0 vì có thể chỉ trả lãi (principal = 0) hoặc không có phạt (penalty = 0)
    CONSTRAINT chk_repayment_amounts_non_negative 
        CHECK (principal_amount >= 0 AND interest_amount >= 0 AND penalty_amount >= 0),
    
    -- Tổng thanh toán phải lớn hơn 0 (phải trả ít nhất 1 đồng)
    CONSTRAINT chk_total_amount_positive 
        CHECK (total_amount > 0)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

