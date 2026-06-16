-- ============================================================================
-- Migration: Tạo bảng loan_contracts (Hợp đồng vay)
-- Mô tả: Bảng lưu trữ thông tin hợp đồng vay sau khi đơn xin vay được phê duyệt.
--         Mỗi đơn vay (loan_application) đã duyệt sẽ tạo ra MỘT hợp đồng (1:1).
--         Hợp đồng chứa các thông tin chính thức: số tiền gốc, lãi suất, kỳ hạn,
--         ngày giải ngân, ngày đáo hạn, tần suất trả nợ.
--         Đây là bảng trung tâm liên kết với hầu hết các bảng khác trong hệ thống.
-- Phụ thuộc: Bảng loan_applications (phải tạo trước)
-- Thứ tự chạy: 3/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS loan_contracts (
    -- === KHÓA CHÍNH ===
    -- Mã định danh duy nhất cho mỗi hợp đồng vay
    contract_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - ĐƠN VAY GỐC ===
    -- Liên kết hợp đồng với đơn xin vay đã được phê duyệt
    -- Quan hệ 1:1 - Mỗi đơn vay approved chỉ tạo ra một hợp đồng
    application_id BIGINT UNSIGNED NOT NULL,

    -- === MÃ HỢP ĐỒNG (Business Key) ===
    -- Số hợp đồng theo định dạng nghiệp vụ (ví dụ: 'CONTRACT-20240116-000001')
    -- Được tự động tạo bằng trigger nếu không cung cấp
    -- Đây là mã mà khách hàng và nhân viên sẽ sử dụng để tra cứu
    contract_number VARCHAR(50) NOT NULL,

    -- === SỐ TIỀN GỐC (Principal Amount) ===
    -- Số tiền gốc chính thức của khoản vay trong hợp đồng
    -- LƯU Ý: principal_amount CÓ THỂ KHÁC VỚI loan_amount trong đơn vay
    --   → Ngân hàng có thể điều chỉnh số tiền sau khi thẩm định
    --   → Ví dụ: Khách xin vay 500 triệu nhưng hợp đồng chỉ duyệt 480 triệu
    -- DECIMAL(15,2): Đảm bảo độ chính xác tuyệt đối cho tiền tệ
    principal_amount DECIMAL(15, 2) NOT NULL,

    -- === LÃI SUẤT (Interest Rate) ===
    -- Lãi suất năm của khoản vay (đơn vị: %)
    -- DECIMAL(5,2): Tối đa 5 chữ số, 2 thập phân → phạm vi 0.00% đến 999.99%
    -- Ví dụ: 12.50 nghĩa là lãi suất 12.5%/năm
    -- CHECK constraint đảm bảo giá trị trong khoảng 0-100%
    interest_rate DECIMAL(5, 2) NOT NULL,

    -- === KỲ HẠN VAY ===
    -- Thời gian vay tính bằng tháng (ví dụ: 24 tháng = 2 năm)
    -- Là kỳ hạn chính thức trong hợp đồng, có thể khác với requested_term_months
    term_months INT UNSIGNED NOT NULL,

    -- === NGÀY GIẢI NGÂN ===
    -- Ngày tiền được chuyển vào tài khoản khách hàng
    -- Đây là mốc bắt đầu tính lãi và tính ngày đáo hạn
    -- Có thể NULL nếu hợp đồng đã ký nhưng chưa giải ngân
    disbursement_date DATE,

    -- === NGÀY ĐÁO HẠN ===
    -- Ngày kết thúc khoản vay, khách hàng phải trả hết nợ trước ngày này
    -- Được tự động tính bằng trigger: disbursement_date + term_months
    -- Ví dụ: Giải ngân 20/01/2024, kỳ hạn 24 tháng → đáo hạn 20/01/2026
    maturity_date DATE,

    -- === NGÀY TRẢ NỢ ĐẦU TIÊN ===
    -- Ngày khách hàng bắt đầu trả kỳ đầu tiên
    -- Thường là 1 tháng sau ngày giải ngân
    first_payment_date DATE,

    -- === TẦN SUẤT TRẢ NỢ ===
    -- Quy định khách hàng trả nợ theo chu kỳ nào:
    --   'monthly'   : Hàng tháng (phổ biến nhất)
    --   'quarterly' : Hàng quý (3 tháng/lần)
    --   'annually'  : Hàng năm
    -- DEFAULT 'monthly': Mặc định trả hàng tháng (phù hợp đa số khoản vay cá nhân)
    payment_frequency ENUM('monthly', 'quarterly', 'annually') DEFAULT 'monthly',

    -- === TRẠNG THÁI HỢP ĐỒNG ===
    -- Quản lý vòng đời (lifecycle) của hợp đồng vay:
    --   'active'     : Đang hoạt động - khoản vay đang trong thời gian trả nợ
    --   'closed'     : Đã đóng - khách hàng đã trả hết nợ, hợp đồng kết thúc
    --   'defaulted'  : Vỡ nợ - khách hàng không trả được nợ quá thời hạn cho phép
    --   'written_off': Xóa nợ - ngân hàng ghi nhận khoản nợ không thu hồi được
    --                  (vẫn có thể theo dõi và thu hồi sau này)
    -- DEFAULT 'active': Hợp đồng mới tạo mặc định ở trạng thái hoạt động
    status ENUM('active', 'closed', 'defaulted', 'written_off') DEFAULT 'active',

    -- === NGÀY KÝ HỢP ĐỒNG ===
    -- Thời điểm khách hàng và ngân hàng ký kết hợp đồng chính thức
    -- NULL nếu hợp đồng được tạo nhưng chưa ký
    signed_at TIMESTAMP NULL DEFAULT NULL,

    -- === DẤU THỜI GIAN HỆ THỐNG ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (contract_id),

    -- Mã hợp đồng phải duy nhất trong toàn hệ thống
    UNIQUE KEY uk_contract_number (contract_number),

    -- Chỉ mục cho application_id: Tăng tốc JOIN với bảng loan_applications
    KEY idx_application_id (application_id),

    -- Chỉ mục cho trạng thái: Lọc hợp đồng theo status (rất hay sử dụng)
    KEY idx_status (status),

    -- Chỉ mục cho ngày giải ngân: Lọc/sắp xếp theo thời gian giải ngân
    KEY idx_disbursement_date (disbursement_date),

    -- Chỉ mục cho ngày đáo hạn: Tìm các hợp đồng sắp đáo hạn
    KEY idx_maturity_date (maturity_date),

    -- Chỉ mục cho ngày tạo bản ghi
    KEY idx_created_at (created_at),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    -- Liên kết hợp đồng với đơn xin vay gốc
    -- ON DELETE RESTRICT: KHÔNG cho xóa đơn vay nếu đã có hợp đồng
    --   → Đảm bảo mọi hợp đồng đều có thể truy ngược về đơn vay gốc
    -- ON UPDATE CASCADE: Cập nhật application_id nếu bảng cha thay đổi
    CONSTRAINT fk_loan_contracts_application 
        FOREIGN KEY (application_id) 
        REFERENCES loan_applications(application_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Số tiền gốc phải lớn hơn 0
    CONSTRAINT chk_principal_amount_positive 
        CHECK (principal_amount > 0),
    
    -- Lãi suất phải trong khoảng 0% đến 100%
    -- (lãi suất 0% có thể xảy ra trong chương trình ưu đãi đặc biệt)
    CONSTRAINT chk_interest_rate_valid 
        CHECK (interest_rate >= 0 AND interest_rate <= 100),
    
    -- Kỳ hạn vay phải lớn hơn 0 tháng
    CONSTRAINT chk_contract_term_months_positive 
        CHECK (term_months > 0)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TRIGGER: Tự động tạo mã hợp đồng và tính ngày đáo hạn
-- ============================================================================
-- Mục đích: 
--   1) Tự động sinh contract_number nếu không cung cấp
--      Format: 'CONTRACT-YYYYMMDD-NNNNNN'
--   2) Tự động tính maturity_date (ngày đáo hạn) nếu không cung cấp
--      Công thức: maturity_date = disbursement_date + term_months tháng
-- Loại trigger: BEFORE INSERT
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_generate_contract_number
BEFORE INSERT ON loan_contracts
FOR EACH ROW
BEGIN
    -- Tự động tạo mã hợp đồng nếu chưa có
    IF NEW.contract_number IS NULL OR NEW.contract_number = '' THEN
        SET NEW.contract_number = CONCAT('CONTRACT-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(LAST_INSERT_ID() + 1, 6, '0'));
    END IF;
    
    -- Tự động tính ngày đáo hạn nếu chưa có
    -- Điều kiện: maturity_date chưa được set VÀ đã có ngày giải ngân VÀ kỳ hạn > 0
    -- DATE_ADD(..., INTERVAL N MONTH): Cộng thêm N tháng vào ngày giải ngân
    IF NEW.maturity_date IS NULL AND NEW.disbursement_date IS NOT NULL AND NEW.term_months > 0 THEN
        SET NEW.maturity_date = DATE_ADD(NEW.disbursement_date, INTERVAL NEW.term_months MONTH);
    END IF;
END//
DELIMITER ;

