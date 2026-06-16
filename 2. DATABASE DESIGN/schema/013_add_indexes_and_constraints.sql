-- ============================================================================
-- Migration: Thêm chỉ mục kết hợp, ràng buộc bổ sung, triggers và view báo cáo
-- Mô tả: File cuối cùng trong chuỗi migration, bổ sung:
--   1) CHỈ MỤC KẾT HỢP (Composite Indexes): Tối ưu hiệu suất cho các truy vấn
--      phổ biến nhất trong hệ thống (multi-column indexes)
--   2) TRIGGERS KIỂM TRA: Các trigger bổ sung đảm bảo tính toàn vẹn dữ liệu
--      mà CHECK constraints không thể thực hiện được (vì cần truy vấn bảng khác)
--   3) VIEW BÁO CÁO: View tổng hợp thông tin khoản vay phục vụ báo cáo
-- Phụ thuộc: TẤT CẢ 12 bảng trước phải được tạo xong
-- Thứ tự chạy: 13/13 (chạy cuối cùng)
-- ============================================================================

-- ============================================================================
-- PHẦN 1: CHỈ MỤC KẾT HỢP (COMPOSITE INDEXES)
-- ============================================================================
-- Composite Index là chỉ mục trên NHIỀU CỘT cùng lúc.
-- MySQL sử dụng composite index hiệu quả nhất khi truy vấn khớp với
-- THỨ TỰ CỘT trong index (quy tắc leftmost prefix).
-- Ví dụ: INDEX (A, B, C) sẽ hỗ trợ tốt cho:
--   WHERE A = ? (sử dụng cột A)
--   WHERE A = ? AND B = ? (sử dụng cột A, B)
--   WHERE A = ? AND B = ? AND C = ? (sử dụng tất cả)
-- NHƯNG KHÔNG tối ưu cho: WHERE B = ? AND C = ? (bỏ qua cột A)
-- ============================================================================

-- Bảng customers: Tìm khách hàng theo trạng thái, sắp xếp theo ngày tạo
-- Use case: "Lấy danh sách khách hàng active, sắp xếp từ mới nhất"
ALTER TABLE customers 
ADD INDEX idx_status_created_at (status, created_at);

-- Bảng loan_applications: Tìm đơn vay theo khách hàng VÀ trạng thái
-- Use case: "Khách hàng X có bao nhiêu đơn vay đang pending?"
ALTER TABLE loan_applications 
ADD INDEX idx_customer_status (customer_id, status);

-- Bảng loan_applications: Tìm đơn vay theo trạng thái VÀ ngày nộp
-- Use case: "Lấy tất cả đơn pending, ưu tiên đơn nộp trước"
ALTER TABLE loan_applications 
ADD INDEX idx_status_submitted_at (status, submitted_at);

-- Bảng loan_contracts: Tìm hợp đồng theo trạng thái VÀ ngày giải ngân
-- Use case: "Lấy tất cả hợp đồng active được giải ngân trong tháng này"
ALTER TABLE loan_contracts 
ADD INDEX idx_status_disbursement_date (status, disbursement_date);

-- Bảng loan_contracts: Tìm hợp đồng theo trạng thái VÀ ngày đáo hạn
-- Use case: "Lấy tất cả hợp đồng active sắp đáo hạn trong 30 ngày tới"
ALTER TABLE loan_contracts 
ADD INDEX idx_status_maturity_date (status, maturity_date);

-- Bảng disbursements: Tìm giải ngân theo hợp đồng VÀ trạng thái
-- Use case: "Tổng số tiền đã giải ngân (completed) cho hợp đồng X"
ALTER TABLE disbursements 
ADD INDEX idx_contract_status (contract_id, status);

-- Bảng repayments: Tìm khoản trả nợ theo hợp đồng, ngày hẹn VÀ trạng thái
-- Use case: "Lấy các khoản overdue của hợp đồng X, sắp xếp theo ngày hẹn"
-- Index 3 cột: Tối ưu cao cho truy vấn phức tạp
ALTER TABLE repayments 
ADD INDEX idx_contract_scheduled_status (contract_id, scheduled_date, status);

-- Bảng repayments: Tìm khoản trả theo trạng thái VÀ ngày trả thực tế
-- Use case: "Lấy tất cả khoản đã trả (paid) trong tháng này"
ALTER TABLE repayments 
ADD INDEX idx_status_actual_payment_date (status, actual_payment_date);

-- Bảng collections: Tìm hoạt động thu hồi theo hợp đồng, trạng thái VÀ ngày
-- Use case: "Lấy tất cả case thu hồi đang open của hợp đồng X"
ALTER TABLE collections 
ADD INDEX idx_contract_status_date (contract_id, status, collection_date);

-- Bảng payment_schedules: Tìm kỳ trả theo ngày đến hạn VÀ trạng thái
-- Use case QUAN TRỌNG NHẤT: "Lấy tất cả kỳ overdue (chưa trả) hôm nay"
-- → Query này chạy hàng nghìn lần/ngày, PHẢI có index tối ưu
ALTER TABLE payment_schedules 
ADD INDEX idx_due_date_status (due_date, status);

-- Bảng credit_scores: Tìm điểm tín dụng mới nhất của khách hàng
-- Use case: "Điểm tín dụng gần nhất của khách hàng X"
-- DESC: Sắp xếp ngày đánh giá giảm dần → lấy bản ghi mới nhất nhanh hơn
ALTER TABLE credit_scores 
ADD INDEX idx_customer_score_date (customer_id, score_date DESC);

-- Bảng approval_workflows: Tìm bước phê duyệt theo đơn, cấp VÀ trạng thái
-- Use case: "Đơn vay X đang chờ duyệt ở level mấy?"
ALTER TABLE approval_workflows 
ADD INDEX idx_application_level_status (application_id, approver_level, status);

-- Bảng interest_rate_schedules: Tìm lãi suất đang active theo hợp đồng
-- Use case: "Lãi suất hiện tại áp dụng cho hợp đồng X"
-- DESC: Lấy lãi suất mới nhất (effective_date gần nhất)
ALTER TABLE interest_rate_schedules 
ADD INDEX idx_contract_effective_status (contract_id, effective_date DESC, status);

-- ============================================================================
-- PHẦN 2: TRIGGERS KIỂM TRA BỔ SUNG
-- ============================================================================
-- Trong MySQL 8.0, CHECK constraints KHÔNG thể sử dụng hàm không xác định
-- (non-deterministic) như CURDATE(), NOW(), hoặc tham chiếu bảng khác.
-- Do đó, ta dùng TRIGGER để thực hiện các kiểm tra này.
-- ============================================================================

-- ============================================================================
-- TRIGGER: Ngày giải ngân không được ở tương lai (INSERT)
-- ============================================================================
-- Mục đích: Đảm bảo disbursement_date <= ngày hiện tại
-- Lý do: Không thể ghi nhận giải ngân cho ngày chưa đến
-- Áp dụng khi INSERT bản ghi mới
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_disbursement_date_not_future_bi
BEFORE INSERT ON disbursements
FOR EACH ROW
BEGIN
    -- CURDATE(): Trả về ngày hiện tại (không có giờ)
    IF NEW.disbursement_date > CURDATE() THEN
        -- SIGNAL SQLSTATE '45000': Ném lỗi do người dùng tự định nghĩa
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'disbursement_date cannot be in the future';
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- TRIGGER: Ngày giải ngân không được ở tương lai (UPDATE)
-- ============================================================================
-- Mục đích: Tương tự trigger trên nhưng áp dụng khi UPDATE bản ghi
-- Cần trigger riêng vì MySQL không cho phép gộp INSERT và UPDATE trong 1 trigger
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_disbursement_date_not_future_bu
BEFORE UPDATE ON disbursements
FOR EACH ROW
BEGIN
    IF NEW.disbursement_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'disbursement_date cannot be in the future';
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- TRIGGER: Ngày hẹn trả nợ không được trước ngày giải ngân
-- ============================================================================
-- Mục đích: Đảm bảo repayments.scheduled_date >= loan_contracts.disbursement_date
-- Lý do: Không thể có lịch trả nợ trước khi khoản vay được giải ngân
-- Ví dụ: Giải ngân ngày 15/01 → Lịch trả sớm nhất là 15/01 (hoặc sau đó)
-- LƯU Ý: CHECK constraint không thể tham chiếu bảng khác, nên dùng trigger
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_validate_repayment_scheduled_date
BEFORE INSERT ON repayments
FOR EACH ROW
BEGIN
    -- Biến lưu ngày giải ngân của hợp đồng
    DECLARE contract_disbursement_date DATE;
    
    -- Lấy ngày giải ngân từ bảng loan_contracts
    SELECT disbursement_date INTO contract_disbursement_date
    FROM loan_contracts
    WHERE contract_id = NEW.contract_id;
    
    -- Nếu hợp đồng đã có ngày giải ngân VÀ ngày hẹn trả < ngày giải ngân → lỗi
    IF contract_disbursement_date IS NOT NULL AND NEW.scheduled_date < contract_disbursement_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Repayment scheduled_date cannot be before contract disbursement_date';
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- TRIGGER: Ngày đến hạn kỳ trả không được trước ngày giải ngân
-- ============================================================================
-- Mục đích: Tương tự trigger trên nhưng cho bảng payment_schedules
-- Đảm bảo: payment_schedules.due_date >= loan_contracts.disbursement_date
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_validate_payment_schedule_due_date
BEFORE INSERT ON payment_schedules
FOR EACH ROW
BEGIN
    DECLARE contract_disbursement_date DATE;
    
    SELECT disbursement_date INTO contract_disbursement_date
    FROM loan_contracts
    WHERE contract_id = NEW.contract_id;
    
    IF contract_disbursement_date IS NOT NULL AND NEW.due_date < contract_disbursement_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment schedule due_date cannot be before contract disbursement_date';
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- TRIGGER: Ngày hiệu lực lãi suất không được trước ngày giải ngân
-- ============================================================================
-- Mục đích: Đảm bảo interest_rate_schedules.effective_date >= disbursement_date
-- Lý do: Lãi suất chỉ có ý nghĩa sau khi khoản vay được giải ngân
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_validate_interest_rate_effective_date
BEFORE INSERT ON interest_rate_schedules
FOR EACH ROW
BEGIN
    DECLARE contract_disbursement_date DATE;
    
    SELECT disbursement_date INTO contract_disbursement_date
    FROM loan_contracts
    WHERE contract_id = NEW.contract_id;
    
    IF contract_disbursement_date IS NOT NULL AND NEW.effective_date < contract_disbursement_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Interest rate schedule effective_date cannot be before contract disbursement_date';
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- TRIGGER: Tự động hết hạn lãi suất cũ khi thêm lãi suất mới
-- ============================================================================
-- Mục đích: Đảm bảo MỖI HỢP ĐỒNG CHỈ CÓ 1 LỊCH LÃI SUẤT ACTIVE tại mỗi thời điểm
-- Khi thêm lãi suất mới với status = 'active':
--   → Tự động chuyển tất cả lãi suất cũ (active) thành 'expired'
-- Ví dụ: Lãi suất thả nổi điều chỉnh từ 10% lên 11%
--   → Lãi suất 10% (cũ) → expired
--   → Lãi suất 11% (mới) → active
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_prevent_overlapping_interest_rates
BEFORE INSERT ON interest_rate_schedules
FOR EACH ROW
BEGIN
    -- Nếu lãi suất mới có status = 'active'
    IF NEW.status = 'active' THEN
        -- Chuyển tất cả lãi suất active hiện tại của hợp đồng này thành expired
        UPDATE interest_rate_schedules
        SET status = 'expired'
        WHERE contract_id = NEW.contract_id
          AND status = 'active';
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- TRIGGER: Tự động cập nhật trạng thái hợp đồng dựa trên lịch trả nợ
-- ============================================================================
-- Mục đích: Khi kỳ trả nợ (payment_schedules) thay đổi, tự động cập nhật
--           trạng thái của hợp đồng (loan_contracts):
--   1) Nếu TỔNG outstanding = 0 (tất cả kỳ đã trả hết)
--      → Hợp đồng chuyển sang 'closed' (đã đóng - hoàn tất tất toán)
--   2) Nếu CÓ kỳ nào overdue (quá hạn)
--      → Hợp đồng chuyển sang 'defaulted' (vỡ nợ)
-- Loại: AFTER UPDATE - chạy SAU khi payment_schedules được cập nhật
-- LƯU Ý: Chỉ cập nhật nếu hợp đồng đang ở trạng thái 'active'
--         (không cập nhật nếu đã 'closed' hoặc 'written_off')
-- ============================================================================
DELIMITER //
CREATE TRIGGER trg_update_contract_status_from_payments
AFTER UPDATE ON payment_schedules
FOR EACH ROW
BEGIN
    -- Biến lưu tổng số tiền còn nợ của toàn bộ hợp đồng
    DECLARE total_outstanding DECIMAL(15, 2);
    -- Biến đếm số kỳ đang quá hạn
    DECLARE overdue_count INT;
    
    -- Tính tổng outstanding và đếm số kỳ overdue cho hợp đồng này
    -- COALESCE(..., 0): Trả về 0 nếu NULL (không có dữ liệu)
    -- COUNT(CASE WHEN ... THEN 1 END): Đếm có điều kiện (chỉ đếm kỳ overdue)
    SELECT 
        COALESCE(SUM(outstanding_amount), 0),
        COUNT(CASE WHEN status = 'overdue' THEN 1 END)
    INTO total_outstanding, overdue_count
    FROM payment_schedules
    WHERE contract_id = NEW.contract_id;
    
    -- Logic cập nhật trạng thái hợp đồng:
    IF total_outstanding = 0 THEN
        -- Trường hợp 1: Tổng nợ = 0 → Khách hàng đã trả hết → Đóng hợp đồng
        UPDATE loan_contracts
        SET status = 'closed'
        WHERE contract_id = NEW.contract_id AND status = 'active';
    ELSEIF overdue_count > 0 THEN
        -- Trường hợp 2: Có kỳ quá hạn → Hợp đồng bị đánh dấu vỡ nợ
        UPDATE loan_contracts
        SET status = 'defaulted'
        WHERE contract_id = NEW.contract_id AND status = 'active';
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- PHẦN 3: VIEW BÁO CÁO TỔNG HỢP (REPORTING VIEW)
-- ============================================================================
-- VIEW là một "bảng ảo" (virtual table) dựa trên kết quả của câu truy vấn.
-- Không lưu dữ liệu thực, mà tính toán khi được gọi.
-- Ưu điểm: Đơn giản hóa truy vấn phức tạp, tái sử dụng, bảo mật
-- ============================================================================

-- ============================================================================
-- VIEW: vw_loan_summary (Tổng hợp thông tin khoản vay)
-- ============================================================================
-- Mục đích: Cung cấp cái nhìn tổng quan về từng khoản vay, kết hợp dữ liệu
--           từ 5 bảng: loan_contracts, loan_applications, customers,
--           disbursements, repayments, payment_schedules
-- Thông tin bao gồm:
--   - Thông tin hợp đồng (mã, số tiền, lãi suất, kỳ hạn, trạng thái)
--   - Thông tin khách hàng (tên, SĐT)
--   - Tổng số tiền đã giải ngân (total_disbursed)
--   - Tổng số tiền đã trả (total_repaid)
--   - Tổng số tiền còn nợ (total_outstanding)
--   - Số kỳ quá hạn (overdue_installments)
-- Use cases:
--   - Báo cáo danh sách khoản vay cho lãnh đạo
--   - Dashboard tổng quan hệ thống
--   - Xuất dữ liệu cho phân tích rủi ro
-- ============================================================================
CREATE OR REPLACE VIEW vw_loan_summary AS
SELECT 
    -- Thông tin hợp đồng
    c.contract_id,                              -- Mã hợp đồng (khóa chính)
    c.contract_number,                          -- Số hợp đồng (mã nghiệp vụ)
    c.principal_amount,                         -- Số tiền gốc
    c.interest_rate,                            -- Lãi suất (%/năm)
    c.term_months,                              -- Kỳ hạn (tháng)
    c.status AS contract_status,                -- Trạng thái hợp đồng
    c.disbursement_date,                        -- Ngày giải ngân
    c.maturity_date,                            -- Ngày đáo hạn

    -- Thông tin khách hàng (JOIN qua loan_applications → customers)
    cu.customer_id,                             -- Mã khách hàng
    cu.full_name AS customer_name,              -- Tên khách hàng
    cu.phone AS customer_phone,                 -- SĐT khách hàng

    -- Tổng số tiền đã giải ngân thành công
    -- COALESCE(..., 0): Trả về 0 nếu chưa giải ngân lần nào
    -- Chỉ tính giải ngân có status = 'completed' (đã hoàn tất)
    COALESCE(SUM(d.amount), 0) AS total_disbursed,

    -- Tổng số tiền đã trả nợ
    -- Chỉ tính khoản trả có status = 'paid' (đã thanh toán)
    COALESCE(SUM(r.total_amount), 0) AS total_repaid,

    -- Tổng số tiền còn nợ (từ lịch trả nợ)
    COALESCE(SUM(ps.outstanding_amount), 0) AS total_outstanding,

    -- Số kỳ đang quá hạn
    -- COUNT(CASE WHEN ... THEN 1 END): Kỹ thuật đếm có điều kiện
    -- Cho biết hợp đồng có bao nhiêu kỳ chưa trả đang quá hạn
    COUNT(CASE WHEN ps.status = 'overdue' THEN 1 END) AS overdue_installments

-- === NGUỒN DỮ LIỆU: JOIN 5 bảng ===
-- Bảng chính: loan_contracts (hợp đồng vay)
FROM loan_contracts c

-- INNER JOIN: Lấy thông tin đơn vay gốc (mỗi hợp đồng PHẢI có đơn vay)
INNER JOIN loan_applications la ON c.application_id = la.application_id

-- INNER JOIN: Lấy thông tin khách hàng (mỗi đơn vay PHẢI có khách hàng)
INNER JOIN customers cu ON la.customer_id = cu.customer_id

-- LEFT JOIN: Lấy thông tin giải ngân (hợp đồng CÓ THỂ chưa giải ngân)
-- Chỉ lấy giải ngân đã hoàn tất (status = 'completed')
LEFT JOIN disbursements d ON c.contract_id = d.contract_id AND d.status = 'completed'

-- LEFT JOIN: Lấy thông tin trả nợ (hợp đồng CÓ THỂ chưa trả kỳ nào)
-- Chỉ lấy khoản trả đã thành công (status = 'paid')
LEFT JOIN repayments r ON c.contract_id = r.contract_id AND r.status = 'paid'

-- LEFT JOIN: Lấy lịch trả nợ (hợp đồng CÓ THỂ chưa tạo lịch)
LEFT JOIN payment_schedules ps ON c.contract_id = ps.contract_id

-- GROUP BY: Nhóm kết quả theo từng hợp đồng + khách hàng
-- Cần GROUP BY vì sử dụng các hàm tổng hợp (SUM, COUNT)
GROUP BY c.contract_id, c.contract_number, c.principal_amount, c.interest_rate, 
         c.term_months, c.status, c.disbursement_date, c.maturity_date,
         cu.customer_id, cu.full_name, cu.phone;

