-- ============================================================================
-- Migration: Tạo bảng approval_workflows (Quy trình phê duyệt)
-- Mô tả: Bảng lưu trữ toàn bộ lịch sử quy trình phê duyệt đa cấp cho đơn vay.
--         Hệ thống phê duyệt nhiều cấp (multi-level approval) hoạt động như sau:
--           Level 1: Chuyên viên tín dụng → Xem xét hồ sơ, đánh giá ban đầu
--           Level 2: Trưởng nhóm thẩm định → Kiểm tra lại, yêu cầu bổ sung nếu cần
--           Level 3: Giám đốc chi nhánh → Phê duyệt cuối cùng (cho khoản vay lớn)
--         Mỗi cấp có thể: Duyệt (approve), Từ chối (reject), hoặc Yêu cầu thêm thông tin
--         Toàn bộ hành động được lưu lại để kiểm toán (audit trail).
-- Phụ thuộc: Bảng loan_applications (phải tạo trước)
-- Thứ tự chạy: 10/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS approval_workflows (
    -- === KHÓA CHÍNH ===
    workflow_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - ĐƠN VAY ===
    -- Liên kết bước phê duyệt với đơn xin vay
    -- Quan hệ 1:N - Một đơn vay có nhiều bước phê duyệt (nhiều levels, nhiều lần action)
    application_id BIGINT UNSIGNED NOT NULL,

    -- === CẤP ĐỘ PHÊ DUYỆT ===
    -- Thứ tự cấp phê duyệt (1 = cấp thấp nhất, tăng dần)
    --   Level 1: Chuyên viên tín dụng (xử lý tất cả đơn)
    --   Level 2: Trưởng nhóm thẩm định (khoản vay > 100 triệu)
    --   Level 3: Giám đốc chi nhánh (khoản vay > 300 triệu)
    -- INT UNSIGNED: Số nguyên không âm
    -- NOT NULL: Mỗi bước phải có level rõ ràng
    -- CHECK: Level phải > 0
    approver_level INT UNSIGNED NOT NULL,

    -- === MÃ NGƯỜI PHÊ DUYỆT ===
    -- Mã nhân viên của người thực hiện phê duyệt
    -- Ví dụ: 'APP001', 'MGR002'
    -- Có thể NULL nếu chưa được gán người phê duyệt
    approver_id VARCHAR(100),

    -- === TÊN NGƯỜI PHÊ DUYỆT ===
    -- Tên đầy đủ của người phê duyệt
    -- NOT NULL: Bắt buộc để kiểm toán (phải biết ai đã duyệt/từ chối)
    approver_name VARCHAR(255) NOT NULL,

    -- === HÀNH ĐỘNG PHÊ DUYỆT ===
    -- Hành động mà người phê duyệt thực hiện:
    --   'approve'      : Phê duyệt - đồng ý chuyển sang bước tiếp theo
    --   'reject'       : Từ chối - đơn vay bị từ chối tại cấp này
    --   'request_info' : Yêu cầu thêm thông tin - cần khách hàng bổ sung giấy tờ
    --                    (đơn quay lại trạng thái chờ, không bị từ chối)
    -- NOT NULL: Mỗi bản ghi phải có hành động cụ thể
    action ENUM('approve', 'reject', 'request_info') NOT NULL,

    -- === GHI CHÚ/NHẬN XÉT ===
    -- Nhận xét của người phê duyệt khi thực hiện hành động
    -- Ví dụ: 'Đơn đáp ứng đủ điều kiện', 'Cần bổ sung sao kê 6 tháng'
    -- TEXT: Cho phép ghi chú dài, chi tiết
    comments TEXT,

    -- === NGÀY THỰC HIỆN HÀNH ĐỘNG ===
    -- Thời điểm người phê duyệt ra quyết định
    -- NOT NULL + DEFAULT: Mặc định là thời điểm hiện tại
    action_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- === TRẠNG THÁI BƯỚC PHÊ DUYỆT ===
    -- Trạng thái hiện tại của bước phê duyệt này:
    --   'pending'  : Đang chờ - bước này chưa được xử lý
    --   'approved' : Đã duyệt - người phê duyệt đã đồng ý
    --   'rejected' : Đã từ chối - người phê duyệt đã từ chối
    -- DEFAULT 'pending': Bước phê duyệt mới tạo mặc định ở trạng thái chờ
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',

    -- === DẤU THỜI GIAN ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (workflow_id),
    -- Chỉ mục cho application_id: Tìm lịch sử phê duyệt của 1 đơn vay
    KEY idx_application_id (application_id),
    -- Chỉ mục cho cấp phê duyệt: Lọc theo level
    KEY idx_approver_level (approver_level),
    KEY idx_status (status),
    -- Chỉ mục cho ngày hành động: Sắp xếp theo thời gian
    KEY idx_action_date (action_date),
    -- Chỉ mục kết hợp: Tìm các bước đang chờ (pending) của 1 đơn vay
    -- Rất hữu ích cho truy vấn: "Đơn vay X đang chờ ai duyệt?"
    KEY idx_application_status (application_id, status),
    KEY idx_created_at (created_at),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    -- Liên kết với đơn xin vay
    -- ON DELETE CASCADE: Nếu xóa đơn vay → xóa luôn lịch sử phê duyệt
    --   → Dùng CASCADE (thay vì RESTRICT) vì workflow chỉ có ý nghĩa khi có đơn vay
    --   → Lịch sử phê duyệt không tồn tại độc lập
    CONSTRAINT fk_approval_workflows_application 
        FOREIGN KEY (application_id) 
        REFERENCES loan_applications(application_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Cấp phê duyệt phải lớn hơn 0 (ít nhất level 1)
    CONSTRAINT chk_approver_level_positive 
        CHECK (approver_level > 0)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

