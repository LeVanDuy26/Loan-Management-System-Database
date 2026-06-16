-- ============================================================================
-- Migration: Tạo bảng collections (Hoạt động thu hồi nợ)
-- Mô tả: Bảng lưu trữ các hoạt động thu hồi nợ quá hạn.
--         Khi khách hàng không trả nợ đúng hạn, bộ phận thu hồi nợ (collection)
--         sẽ thực hiện các hành động theo mức độ leo thang:
--           1) Nhắc nhở (reminder): Gửi SMS/email nhắc trả nợ
--           2) Cảnh cáo (warning): Gọi điện cảnh báo
--           3) Hành động pháp lý (legal_action): Khởi kiện, thu giữ tài sản
--           4) Thương lượng (settlement): Đàm phán cơ cấu lại nợ
--         Mỗi hành động thu hồi được lưu lại đầy đủ để kiểm toán và theo dõi
-- Phụ thuộc: Bảng loan_contracts (phải tạo trước)
-- Thứ tự chạy: 6/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS collections (
    -- === KHÓA CHÍNH ===
    collection_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - HỢP ĐỒNG VAY ===
    -- Liên kết hoạt động thu hồi với hợp đồng vay có nợ quá hạn
    -- Quan hệ 1:N - Một hợp đồng có thể có nhiều hoạt động thu hồi
    contract_id BIGINT UNSIGNED NOT NULL,

    -- === LOẠI HOẠT ĐỘNG THU HỒI ===
    -- Phân loại mức độ hành động thu hồi nợ (leo thang dần):
    --   'reminder'     : Nhắc nhở nhẹ nhàng (SMS, email, thông báo app)
    --   'warning'      : Cảnh cáo (gọi điện, thư cảnh cáo chính thức)
    --   'legal_action' : Hành động pháp lý (khởi kiện, thu giữ tài sản thế chấp)
    --   'settlement'   : Thương lượng giải quyết (cơ cấu lại nợ, giảm phí phạt)
    -- NOT NULL: Mỗi hoạt động phải có loại cụ thể
    collection_type ENUM('reminder', 'warning', 'legal_action', 'settlement') NOT NULL,

    -- === NGÀY THỰC HIỆN THU HỒI ===
    -- Ngày mà hoạt động thu hồi được thực hiện
    collection_date DATE NOT NULL,

    -- === SỐ TIỀN NỢ ===
    -- Tổng số tiền nợ quá hạn tại thời điểm thu hồi
    -- DEFAULT 0: Có thể bằng 0 nếu chỉ là nhắc nhở phòng ngừa
    amount_due DECIMAL(15, 2) NOT NULL DEFAULT 0,

    -- === SỐ TIỀN ĐÃ THU ===
    -- Số tiền thực tế đã thu hồi được từ hoạt động này
    -- Ví dụ: Nợ 10 triệu, nhắc nhở xong khách trả 5 triệu → amount_collected = 5 triệu
    amount_collected DECIMAL(15, 2) NOT NULL DEFAULT 0,

    -- === NGƯỜI ĐƯỢC GIAO NHIỆM VỤ ===
    -- Tên nhân viên thu hồi nợ được giao xử lý case này
    -- Ví dụ: 'Nhân viên thu hồi 1', 'Nguyễn Thị Hương'
    assigned_to VARCHAR(255),

    -- === GHI CHÚ ===
    -- Nội dung chi tiết của hoạt động thu hồi
    -- Ví dụ: 'Khách hàng hứa sẽ trả trong 2 tuần', 'Đã gửi thư cảnh cáo lần 2'
    -- TEXT: Cho phép ghi chú dài, chi tiết
    notes TEXT,

    -- === NGÀY HÀNH ĐỘNG TIẾP THEO ===
    -- Lịch hẹn cho bước xử lý tiếp theo
    -- Ví dụ: Nhắc nhở hôm nay → nếu 7 ngày sau không trả → gọi cảnh cáo
    -- Giúp bộ phận thu hồi không bỏ sót case nào
    next_action_date DATE,

    -- === TRẠNG THÁI CASE THU HỒI ===
    -- Quản lý trạng thái của hoạt động thu hồi:
    --   'open'     : Đang xử lý - case vẫn đang được theo dõi
    --   'resolved' : Đã giải quyết - khách hàng đã trả nợ
    --   'closed'   : Đã đóng - case kết thúc (có thể là write-off hoặc đã xử lý xong)
    -- DEFAULT 'open': Case mới tạo mặc định ở trạng thái đang xử lý
    status ENUM('open', 'resolved', 'closed') DEFAULT 'open',

    -- === DẤU THỜI GIAN ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Thời điểm case được giải quyết (chỉ có giá trị khi status = 'resolved')
    resolved_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (collection_id),
    KEY idx_contract_id (contract_id),
    -- Chỉ mục cho loại thu hồi: Lọc theo loại hành động
    KEY idx_collection_type (collection_type),
    -- Chỉ mục cho ngày thu hồi: Sắp xếp theo thời gian
    KEY idx_collection_date (collection_date),
    KEY idx_status (status),
    -- Chỉ mục cho ngày hành động tiếp theo: 
    -- Rất quan trọng cho nhân viên thu hồi tìm "hôm nay cần làm gì"
    KEY idx_next_action_date (next_action_date),
    -- Chỉ mục kết hợp: Tìm các case đang mở (open) của 1 hợp đồng
    KEY idx_contract_status (contract_id, status),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    CONSTRAINT fk_collections_contract 
        FOREIGN KEY (contract_id) 
        REFERENCES loan_contracts(contract_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Số tiền nợ và số tiền đã thu không được âm
    CONSTRAINT chk_collection_amounts_non_negative 
        CHECK (amount_due >= 0 AND amount_collected >= 0),
    
    -- Số tiền đã thu KHÔNG ĐƯỢC VƯỢT QUÁ số tiền nợ
    -- (không thể thu hồi nhiều hơn số tiền khách hàng nợ)
    CONSTRAINT chk_amount_collected_not_exceed_due 
        CHECK (amount_collected <= amount_due)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

