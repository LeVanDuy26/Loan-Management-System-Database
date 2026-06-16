-- ============================================================================
-- Migration: Tạo bảng interest_rate_schedules (Lịch lãi suất)
-- Mô tả: Bảng quản lý lãi suất cho từng hợp đồng vay, hỗ trợ cả 2 loại:
--         1) Lãi suất CỐ ĐỊNH (fixed): Lãi suất không đổi suốt kỳ hạn vay
--            → Chỉ cần 1 bản ghi cho suốt vòng đời hợp đồng
--         2) Lãi suất THẢ NỔI (floating): Lãi suất thay đổi theo thị trường
--            → Có nhiều bản ghi, mỗi bản ghi là 1 giai đoạn lãi suất
--            → Công thức: rate = base_rate + spread
--              Ví dụ: Lãi suất cơ bản ngân hàng 8% + spread 2% = 10%
--         Chỉ có MỘT lãi suất 'active' tại mỗi thời điểm cho mỗi hợp đồng
--         (trigger sẽ tự động đặt lãi suất cũ thành 'expired' khi thêm mới)
-- Phụ thuộc: Bảng loan_contracts (phải tạo trước)
-- Thứ tự chạy: 11/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS interest_rate_schedules (
    -- === KHÓA CHÍNH ===
    schedule_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - HỢP ĐỒNG VAY ===
    -- Liên kết lịch lãi suất với hợp đồng vay
    -- Quan hệ 1:N - Một hợp đồng có thể có nhiều lịch lãi suất
    -- (đặc biệt với lãi suất thả nổi, lãi suất thay đổi theo từng giai đoạn)
    contract_id BIGINT UNSIGNED NOT NULL,

    -- === NGÀY HIỆU LỰC ===
    -- Ngày bắt đầu áp dụng mức lãi suất này
    -- Trigger sẽ kiểm tra: effective_date >= disbursement_date của hợp đồng
    -- NOT NULL: Mỗi mức lãi suất phải có ngày bắt đầu rõ ràng
    effective_date DATE NOT NULL,

    -- === LÃI SUẤT THỰC TẾ ÁP DỤNG ===
    -- Lãi suất năm (%) được áp dụng trong giai đoạn này
    -- Với fixed rate: rate là giá trị cố định (ví dụ: 12.5%)
    -- Với floating rate: rate = base_rate + spread (ví dụ: 8% + 2% = 10%)
    -- DECIMAL(5,2): Phạm vi 0.00% đến 999.99%
    rate DECIMAL(5, 2) NOT NULL,

    -- === LOẠI LÃI SUẤT ===
    --   'fixed'    : Cố định - lãi suất không thay đổi (an toàn cho khách hàng)
    --   'floating' : Thả nổi - lãi suất biến động theo thị trường 
    --                (có thể tăng hoặc giảm, rủi ro hơn nhưng thường thấp hơn lúc đầu)
    -- DEFAULT 'fixed': Mặc định là lãi suất cố định
    rate_type ENUM('fixed', 'floating') NOT NULL DEFAULT 'fixed',

    -- === LÃI SUẤT CƠ BẢN (chỉ dùng cho floating) ===
    -- Lãi suất tham chiếu từ ngân hàng nhà nước hoặc thị trường liên ngân hàng
    -- Ví dụ: Lãi suất cơ bản NHNN = 8%/năm
    -- NULL nếu là fixed rate (không cần base_rate)
    -- CHECK constraint: Nếu floating → base_rate PHẢI có giá trị
    base_rate DECIMAL(5, 2),

    -- === BIÊN ĐỘ LÃI SUẤT (chỉ dùng cho floating) ===
    -- Phần chênh lệch cộng thêm vào base_rate
    -- Ví dụ: spread = 2% → rate = base_rate + 2%
    -- Spread thường cố định cho suốt hợp đồng, chỉ base_rate thay đổi
    -- Có thể âm (hiếm) hoặc dương
    spread DECIMAL(5, 2),

    -- === PHƯƠNG PHÁP TÍNH LÃI ===
    -- Mô tả cách thức tính lãi suất
    -- Ví dụ: 'simple_interest' (lãi đơn), 'compound_interest' (lãi kép),
    --         'reducing_balance' (dư nợ giảm dần)
    calculation_method VARCHAR(100),

    -- === TRẠNG THÁI LỊCH LÃI SUẤT ===
    --   'active'  : Đang áp dụng - mức lãi suất hiện tại
    --   'expired' : Đã hết hạn - mức lãi suất cũ (chỉ lưu lịch sử)
    -- DEFAULT 'active': Lãi suất mới thêm mặc định ở trạng thái đang áp dụng
    -- Trigger sẽ tự động đặt lãi suất cũ thành 'expired' khi thêm mới
    status ENUM('active', 'expired') DEFAULT 'active',

    -- === DẤU THỜI GIAN ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (schedule_id),
    KEY idx_contract_id (contract_id),
    -- Chỉ mục cho ngày hiệu lực: Tìm lãi suất áp dụng tại 1 thời điểm
    KEY idx_effective_date (effective_date),
    -- Chỉ mục cho loại lãi suất: Lọc theo fixed/floating
    KEY idx_rate_type (rate_type),
    KEY idx_status (status),
    -- Chỉ mục kết hợp: Tìm lãi suất đang active của 1 hợp đồng
    -- Truy vấn rất phổ biến: "Lãi suất hiện tại của hợp đồng X là bao nhiêu?"
    KEY idx_contract_status (contract_id, status),
    KEY idx_created_at (created_at),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    -- Liên kết với hợp đồng vay
    -- ON DELETE CASCADE: Nếu xóa hợp đồng → xóa luôn lịch lãi suất
    --   → Dùng CASCADE vì lịch lãi suất không tồn tại độc lập
    CONSTRAINT fk_interest_rate_schedules_contract 
        FOREIGN KEY (contract_id) 
        REFERENCES loan_contracts(contract_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Lãi suất thực tế phải hợp lệ (0-100%)
    CONSTRAINT chk_rate_valid 
        CHECK (rate >= 0 AND rate <= 100),
    
    -- Lãi suất cơ bản hợp lệ nếu có (0-100%), cho phép NULL
    CONSTRAINT chk_base_rate_valid 
        CHECK (base_rate IS NULL OR (base_rate >= 0 AND base_rate <= 100)),
    
    -- Biên độ lãi suất hợp lệ nếu có (-100 đến 100%), cho phép NULL
    -- Âm: spread giảm lãi suất (ưu đãi đặc biệt)
    -- Dương: spread tăng thêm lãi suất (bình thường)
    CONSTRAINT chk_spread_valid 
        CHECK (spread IS NULL OR (spread >= -100 AND spread <= 100)),
    
    -- Ràng buộc NGHIỆP VỤ QUAN TRỌNG:
    -- Nếu loại lãi suất là 'floating' → base_rate KHÔNG ĐƯỢC NULL
    -- (Lãi suất thả nổi PHẢI có lãi suất cơ bản để tính toán)
    -- Nếu loại là 'fixed' → base_rate có thể NULL (không cần)
    CONSTRAINT chk_floating_rate_has_base 
        CHECK (rate_type = 'fixed' OR (rate_type = 'floating' AND base_rate IS NOT NULL))

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

