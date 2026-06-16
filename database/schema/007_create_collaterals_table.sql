-- ============================================================================
-- Migration: Tạo bảng collaterals (Tài sản thế chấp / Tài sản đảm bảo)
-- Mô tả: Bảng lưu trữ thông tin tài sản đảm bảo (collateral) cho khoản vay.
--         Tài sản đảm bảo là "lớp bảo vệ" để giảm rủi ro cho ngân hàng:
--         Nếu khách hàng không trả được nợ, ngân hàng có quyền thu giữ tài sản.
--         Một hợp đồng có thể có NHIỀU tài sản thế chấp (ví dụ: vừa nhà vừa xe).
--         Các loại tài sản hỗ trợ: bất động sản, xe cộ, tiền gửi, và khác.
--         ĐÂY LÀ BẢNG TRỌNG TÂM CỦA ĐỀ TÀI: "Quản lý khoản vay có tài sản đảm bảo"
-- Phụ thuộc: Bảng loan_contracts (phải tạo trước)
-- Thứ tự chạy: 7/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS collaterals (
    -- === KHÓA CHÍNH ===
    collateral_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - HỢP ĐỒNG VAY ===
    -- Liên kết tài sản thế chấp với hợp đồng vay
    -- Quan hệ 1:N - Một hợp đồng có thể được đảm bảo bằng NHIỀU tài sản
    -- Ví dụ: Vay 480 triệu, thế chấp căn nhà 600 triệu + xe ô tô 200 triệu
    contract_id BIGINT UNSIGNED NOT NULL,

    -- === LOẠI TÀI SẢN ĐẢM BẢO ===
    -- Phân loại tài sản thế chấp:
    --   'real_estate' : Bất động sản (nhà, đất, căn hộ, biệt thự)
    --                   → Loại phổ biến nhất, giá trị cao, thanh khoản thấp hơn
    --   'vehicle'     : Phương tiện giao thông (xe ô tô, xe máy, tàu thuyền)
    --                   → Giá trị trung bình, mất giá theo thời gian (depreciation)
    --   'deposit'     : Tiền gửi tiết kiệm tại ngân hàng
    --                   → Thanh khoản cao nhất, giá trị ổn định
    --   'other'       : Tài sản khác (máy móc thiết bị, cổ phiếu, vàng, v.v.)
    -- NOT NULL: Mỗi tài sản phải có loại cụ thể
    collateral_type ENUM('real_estate', 'vehicle', 'deposit', 'other') NOT NULL,

    -- === MÔ TẢ TÀI SẢN ===
    -- Mô tả chi tiết về tài sản thế chấp
    -- Ví dụ: 'Căn hộ chung cư tại Quận 1, 70m2, 2 phòng ngủ'
    -- TEXT: Cho phép mô tả dài và chi tiết
    description TEXT,

    -- === GIÁ TRỊ ƯỚC TÍNH ===
    -- Giá trị tài sản do chủ sở hữu hoặc thị trường ước tính
    -- Ví dụ: Chủ nhà bán 600 triệu → estimated_value = 600,000,000
    -- NOT NULL: Bắt buộc phải có giá trị ước tính
    estimated_value DECIMAL(15, 2) NOT NULL,

    -- === GIÁ TRỊ THẨM ĐỊNH ===
    -- Giá trị do chuyên gia thẩm định của ngân hàng đánh giá (appraisal)
    -- THƯỜNG THẤP HƠN estimated_value vì ngân hàng tính thận trọng hơn
    -- Ví dụ: Chủ bán 600 triệu nhưng thẩm định chỉ 550 triệu
    -- NULL nếu chưa được thẩm định (sẽ cập nhật sau)
    appraised_value DECIMAL(15, 2),

    -- === GIẤY TỜ SỞ HỮU ===
    -- Thông tin giấy tờ chứng minh quyền sở hữu tài sản
    -- Ví dụ: 'Sổ đỏ số 12345', 'Đăng ký xe số 123ABC'
    -- Rất quan trọng cho tính pháp lý của tài sản đảm bảo
    ownership_document VARCHAR(500),

    -- === VỊ TRÍ TÀI SẢN ===
    -- Địa chỉ hoặc vị trí của tài sản thế chấp
    -- Ví dụ: '123 Đường Nguyễn Huệ, Quận 1, TP.HCM'
    -- Quan trọng cho bất động sản và phương tiện
    location VARCHAR(500),

    -- === TRẠNG THÁI TÀI SẢN ĐẢM BẢO ===
    -- Quản lý vòng đời của tài sản trong hệ thống:
    --   'active'   : Đang thế chấp - tài sản đang được giữ làm đảm bảo
    --                → Khách hàng không được bán/chuyển nhượng tài sản
    --   'released' : Đã giải chấp - khách hàng trả hết nợ, tài sản được trả lại
    --                → Ngân hàng trả lại sổ đỏ/giấy tờ cho khách hàng
    --   'seized'   : Bị thu giữ - ngân hàng thu giữ tài sản do khách không trả nợ
    --                → Tiến hành thanh lý (liquidation) để thu hồi vốn
    -- DEFAULT 'active': Tài sản mới thế chấp mặc định ở trạng thái đang giữ
    status ENUM('active', 'released', 'seized') DEFAULT 'active',

    -- === DẤU THỜI GIAN ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Thời điểm giải chấp (chỉ có giá trị khi status = 'released')
    released_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (collateral_id),
    -- Chỉ mục cho contract_id: Tìm tất cả tài sản thế chấp của 1 hợp đồng
    KEY idx_contract_id (contract_id),
    -- Chỉ mục cho loại tài sản: Lọc/thống kê theo loại tài sản
    KEY idx_collateral_type (collateral_type),
    KEY idx_status (status),
    KEY idx_created_at (created_at),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    -- Liên kết với hợp đồng vay
    -- ON DELETE RESTRICT: KHÔNG cho xóa hợp đồng nếu có tài sản thế chấp
    --   → Bảo vệ thông tin tài sản đảm bảo không bị mất
    CONSTRAINT fk_collaterals_contract 
        FOREIGN KEY (contract_id) 
        REFERENCES loan_contracts(contract_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Giá trị ước tính phải lớn hơn 0 (tài sản phải có giá trị)
    CONSTRAINT chk_estimated_value_positive 
        CHECK (estimated_value > 0),
    
    -- Giá trị thẩm định phải lớn hơn 0 NẾU có giá trị (cho phép NULL)
    -- NULL: Chưa được thẩm định
    -- > 0: Đã thẩm định và có giá trị hợp lệ
    CONSTRAINT chk_appraised_value_positive 
        CHECK (appraised_value IS NULL OR appraised_value > 0)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

