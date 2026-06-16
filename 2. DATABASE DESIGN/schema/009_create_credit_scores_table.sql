-- ============================================================================
-- Migration: Tạo bảng credit_scores (Điểm tín dụng)
-- Mô tả: Bảng lưu trữ kết quả đánh giá tín dụng (credit scoring) của khách hàng.
--         Điểm tín dụng phản ánh khả năng trả nợ và mức độ rủi ro của khách hàng.
--         Hệ thống sử dụng thang điểm 0-1000 với 4 mức xếp hạng:
--           - Excellent (Xuất sắc): >= 750 điểm → Duyệt nhanh, lãi suất thấp
--           - Good (Tốt): 650-749 điểm → Duyệt bình thường
--           - Fair (Trung bình): 550-649 điểm → Cần xem xét thêm, có thể yêu cầu thế chấp
--           - Poor (Kém): < 550 điểm → Khả năng bị từ chối cao
--         Điểm tín dụng CÓ THỜI HẠN (thường 30 ngày), sau đó cần đánh giá lại.
--         Các yếu tố đánh giá được lưu trong cột JSON (linh hoạt thay đổi).
-- Phụ thuộc: Bảng customers VÀ loan_applications (phải tạo trước)
-- Thứ tự chạy: 9/13
-- ============================================================================

CREATE TABLE IF NOT EXISTS credit_scores (
    -- === KHÓA CHÍNH ===
    credit_score_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- === KHÓA NGOẠI - KHÁCH HÀNG ===
    -- Liên kết điểm tín dụng với khách hàng
    -- Quan hệ 1:N - Một khách hàng có nhiều điểm tín dụng theo thời gian
    -- (lưu lịch sử để theo dõi xu hướng tín dụng)
    -- NOT NULL: Mỗi điểm tín dụng phải thuộc về một khách hàng cụ thể
    customer_id BIGINT UNSIGNED NOT NULL,

    -- === KHÓA NGOẠI - ĐƠN VAY (tùy chọn) ===
    -- Liên kết điểm tín dụng với đơn xin vay cụ thể (nếu có)
    -- NULL: Cho phép NULL vì điểm tín dụng có thể là đánh giá tổng quát
    --       (không gắn với đơn vay nào cụ thể, chỉ là periodic assessment)
    -- Khi gắn với đơn vay: Biết điểm tín dụng tại thời điểm đánh giá đơn đó
    application_id BIGINT UNSIGNED NULL,

    -- === ĐIỂM TÍN DỤNG ===
    -- Giá trị điểm tín dụng, thang điểm 0-1000
    -- INT UNSIGNED: Số nguyên không âm
    -- NOT NULL: Bắt buộc phải có điểm
    -- CHECK constraint đảm bảo điểm trong khoảng 0-1000
    score INT UNSIGNED NOT NULL,

    -- === NGÀY ĐÁNH GIÁ ===
    -- Ngày thực hiện đánh giá tín dụng
    -- Quan trọng vì điểm tín dụng CÓ THỜI HẠN (thường 30 ngày)
    -- Nếu quá hạn, hệ thống yêu cầu đánh giá lại (re-assessment)
    score_date DATE NOT NULL,

    -- === XẾP HẠNG TÍN DỤNG ===
    -- Mức xếp hạng tương ứng với điểm tín dụng:
    --   'excellent' : Xuất sắc (score >= 750) → Rủi ro rất thấp
    --   'good'      : Tốt (650 <= score < 750) → Rủi ro thấp
    --   'fair'      : Trung bình (550 <= score < 650) → Rủi ro trung bình
    --   'poor'      : Kém (score < 550) → Rủi ro cao
    -- NOT NULL: Bắt buộc phải có xếp hạng
    -- CHECK constraint đảm bảo rating PHẢI KHỚP với score
    rating ENUM('excellent', 'good', 'fair', 'poor') NOT NULL,

    -- === CÁC YẾU TỐ ĐÁNH GIÁ (JSON) ===
    -- Lưu trữ các yếu tố ảnh hưởng đến điểm tín dụng dưới dạng JSON
    -- Sử dụng JSON thay vì cột riêng vì các yếu tố có thể THAY ĐỔI 
    -- tùy theo chính sách của ngân hàng (linh hoạt, không cần ALTER TABLE)
    -- Ví dụ:
    -- {
    --   "income_stability": "high",        -- Mức độ ổn định thu nhập
    --   "credit_history": "excellent",     -- Lịch sử tín dụng
    --   "employment": "stable",            -- Tình trạng việc làm
    --   "debt_to_income": 0.25             -- Tỷ lệ nợ/thu nhập (25%)
    -- }
    factors JSON,

    -- === DẤU THỜI GIAN ===
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ============================================================================
    -- RÀNG BUỘC VÀ CHỈ MỤC
    -- ============================================================================

    PRIMARY KEY (credit_score_id),
    -- Chỉ mục cho customer_id: Tìm lịch sử điểm tín dụng của 1 khách hàng
    KEY idx_customer_id (customer_id),
    -- Chỉ mục cho application_id: Tìm điểm tín dụng gắn với 1 đơn vay cụ thể
    KEY idx_application_id (application_id),
    -- Chỉ mục cho điểm: Lọc/sắp xếp theo điểm tín dụng
    KEY idx_score (score),
    -- Chỉ mục cho xếp hạng: Lọc theo mức xếp hạng
    -- (ví dụ: "Lấy tất cả khách hàng có xếp hạng 'poor'" để cảnh báo)
    KEY idx_rating (rating),
    -- Chỉ mục cho ngày đánh giá: Lọc/sắp xếp theo thời gian
    KEY idx_score_date (score_date),
    KEY idx_created_at (created_at),
    
    -- ============================================================================
    -- RÀNG BUỘC KHÓA NGOẠI
    -- ============================================================================

    -- Liên kết với khách hàng
    -- ON DELETE RESTRICT: KHÔNG cho xóa khách hàng nếu có lịch sử điểm tín dụng
    CONSTRAINT fk_credit_scores_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- Liên kết với đơn vay (tùy chọn)
    -- ON DELETE SET NULL: Nếu đơn vay bị xóa, giữ lại điểm tín dụng nhưng đặt 
    --   application_id = NULL (vì điểm tín dụng vẫn có giá trị lịch sử)
    -- → Khác với các FK khác dùng RESTRICT, ở đây dùng SET NULL vì
    --   điểm tín dụng có thể tồn tại độc lập với đơn vay
    CONSTRAINT fk_credit_scores_application 
        FOREIGN KEY (application_id) 
        REFERENCES loan_applications(application_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    
    -- ============================================================================
    -- RÀNG BUỘC KIỂM TRA
    -- ============================================================================

    -- Điểm tín dụng phải trong khoảng 0-1000
    CONSTRAINT chk_score_range 
        CHECK (score >= 0 AND score <= 1000),
    
    -- Ràng buộc QUAN TRỌNG: Xếp hạng (rating) PHẢI KHỚP với điểm (score)
    -- Đảm bảo tính nhất quán giữa 2 cột, tránh sai sót khi nhập liệu
    -- Ví dụ: Không thể có score = 400 mà rating = 'excellent'
    --   - excellent: score >= 750
    --   - good:      650 <= score < 750
    --   - fair:      550 <= score < 650
    --   - poor:      score < 550
    CONSTRAINT chk_rating_match_score 
        CHECK (
            (rating = 'excellent' AND score >= 750) OR
            (rating = 'good' AND score >= 650 AND score < 750) OR
            (rating = 'fair' AND score >= 550 AND score < 650) OR
            (rating = 'poor' AND score < 550)
        )

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

