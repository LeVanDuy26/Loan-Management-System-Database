-- Seed: Sample loan applications data
-- Description: Insert realistic sample loan application data with credit scores and approval workflows

-- Insert credit scores for customers
INSERT INTO credit_scores (customer_id, score, score_date, rating, factors) VALUES
(1, 780, '2024-01-15', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "stable", "debt_to_income": 0.25}'),
(2, 720, '2024-01-16', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.35}'),
(3, 850, '2024-01-17', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "very_stable", "debt_to_income": 0.20}'),
(4, 680, '2024-01-18', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.40}'),
(5, 750, '2024-01-19', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "stable", "debt_to_income": 0.30}'),
(6, 650, '2024-01-20', 'good', '{"income_stability": "medium", "credit_history": "fair", "employment": "stable", "debt_to_income": 0.45}'),
(7, 820, '2024-01-21', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "very_stable", "debt_to_income": 0.22}'),
(8, 700, '2024-01-22', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.38}'),
(9, 580, '2024-01-23', 'fair', '{"income_stability": "low", "credit_history": "fair", "employment": "unstable", "debt_to_income": 0.50}'),
(10, 720, '2024-01-24', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.35}'),
(11, 640, '2024-01-25', 'fair', '{"income_stability": "medium", "credit_history": "fair", "employment": "stable", "debt_to_income": 0.48}'),
(12, 690, '2024-01-26', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.42}'),
(13, 600, '2024-01-27', 'fair', '{"income_stability": "low", "credit_history": "fair", "employment": "unstable", "debt_to_income": 0.52}'),
(14, 760, '2024-01-28', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "stable", "debt_to_income": 0.28}'),
(15, 620, '2024-01-29', 'fair', '{"income_stability": "medium", "credit_history": "fair", "employment": "stable", "debt_to_income": 0.50}'),
(16, 710, '2024-01-30', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.36}'),
(17, 590, '2024-02-01', 'fair', '{"income_stability": "low", "credit_history": "poor", "employment": "unstable", "debt_to_income": 0.55}'),
(18, 730, '2024-02-02', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.33}'),
(19, 800, '2024-02-03', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "very_stable", "debt_to_income": 0.24}'),
(20, 670, '2024-02-04', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.40}');

-- Insert loan applications
INSERT INTO loan_applications (customer_id, application_number, loan_amount, requested_term_months, purpose, status, submitted_at, approved_at, rejected_at, approval_notes) VALUES
(1, 'APP-20240115-000001', 50000000, 24, 'Mua xe máy', 'approved', '2024-01-15 09:00:00', '2024-01-16 14:30:00', NULL, 'Đơn được phê duyệt dựa trên điểm tín dụng tốt'),
(2, 'APP-20240116-000002', 100000000, 36, 'Sửa chữa nhà', 'approved', '2024-01-16 10:15:00', '2024-01-17 16:00:00', NULL, 'Phê duyệt với điều kiện có người bảo lãnh'),
(3, 'APP-20240117-000003', 200000000, 48, 'Kinh doanh', 'approved', '2024-01-17 11:30:00', '2024-01-18 10:00:00', NULL, 'Đơn được phê duyệt nhanh do điểm tín dụng xuất sắc'),
(4, 'APP-20240118-000004', 75000000, 30, 'Mua đồ nội thất', 'approved', '2024-01-18 08:45:00', '2024-01-19 15:20:00', NULL, 'Phê duyệt với lãi suất ưu đãi'),
(5, 'APP-20240119-000005', 150000000, 36, 'Đầu tư', 'approved', '2024-01-19 13:20:00', '2024-01-20 11:45:00', NULL, 'Đơn được phê duyệt'),
(6, 'APP-20240120-000006', 30000000, 12, 'Chi tiêu cá nhân', 'pending', '2024-01-20 14:00:00', NULL, NULL, NULL),
(7, 'APP-20240121-000007', 250000000, 60, 'Mua nhà', 'approved', '2024-01-21 09:30:00', '2024-01-22 13:00:00', NULL, 'Phê duyệt với tài sản thế chấp'),
(8, 'APP-20240122-000008', 80000000, 24, 'Học phí', 'approved', '2024-01-22 10:45:00', '2024-01-23 14:30:00', NULL, 'Đơn được phê duyệt'),
(9, 'APP-20240123-000009', 50000000, 18, 'Chi tiêu cá nhân', 'rejected', '2024-01-23 11:15:00', NULL, '2024-01-24 09:00:00', 'Điểm tín dụng không đủ yêu cầu'),
(10, 'APP-20240124-000010', 120000000, 36, 'Kinh doanh', 'approved', '2024-01-24 12:00:00', '2024-01-25 10:30:00', NULL, 'Phê duyệt với điều kiện'),
(11, 'APP-20240125-000011', 40000000, 24, 'Sửa chữa xe', 'pending', '2024-01-25 13:30:00', NULL, NULL, NULL),
(12, 'APP-20240126-000012', 90000000, 30, 'Mua thiết bị', 'approved', '2024-01-26 08:20:00', '2024-01-27 15:00:00', NULL, 'Đơn được phê duyệt'),
(13, 'APP-20240127-000013', 60000000, 24, 'Chi tiêu cá nhân', 'rejected', '2024-01-27 14:15:00', NULL, '2024-01-28 10:00:00', 'Thu nhập không ổn định'),
(14, 'APP-20240128-000014', 180000000, 48, 'Mua xe ô tô', 'approved', '2024-01-28 09:45:00', '2024-01-29 11:20:00', NULL, 'Phê duyệt với tài sản thế chấp'),
(15, 'APP-20240129-000015', 35000000, 18, 'Chi tiêu cá nhân', 'pending', '2024-01-29 10:30:00', NULL, NULL, NULL),
(16, 'APP-20240130-000016', 110000000, 36, 'Kinh doanh', 'approved', '2024-01-30 11:00:00', '2024-01-31 14:00:00', NULL, 'Đơn được phê duyệt'),
(17, 'APP-20240201-000017', 70000000, 24, 'Chi tiêu cá nhân', 'rejected', '2024-02-01 12:45:00', NULL, '2024-02-02 09:30:00', 'Lịch sử tín dụng kém'),
(18, 'APP-20240202-000018', 95000000, 30, 'Sửa chữa nhà', 'approved', '2024-02-02 13:15:00', '2024-02-03 10:45:00', NULL, 'Phê duyệt với người bảo lãnh'),
(19, 'APP-20240203-000019', 300000000, 60, 'Mua nhà', 'approved', '2024-02-03 08:00:00', '2024-02-04 12:00:00', NULL, 'Phê duyệt với tài sản thế chấp và người bảo lãnh'),
(20, 'APP-20240204-000020', 85000000, 30, 'Đầu tư', 'approved', '2024-02-04 09:30:00', '2024-02-05 13:30:00', NULL, 'Đơn được phê duyệt'),
(21, 'APP-20240205-000021', 55000000, 24, 'Chi tiêu cá nhân', 'pending', '2024-02-05 10:00:00', NULL, NULL, NULL),
(22, 'APP-20240206-000022', 130000000, 36, 'Kinh doanh', 'pending', '2024-02-06 11:15:00', NULL, NULL, NULL),
(23, 'APP-20240207-000023', 45000000, 18, 'Chi tiêu cá nhân', 'pending', '2024-02-07 12:30:00', NULL, NULL, NULL),
(24, 'APP-20240208-000024', 160000000, 48, 'Mua xe ô tô', 'pending', '2024-02-08 13:45:00', NULL, NULL, NULL),
(25, 'APP-20240209-000025', 65000000, 24, 'Sửa chữa nhà', 'pending', '2024-02-09 14:00:00', NULL, NULL, NULL);

-- Insert credit scores linked to applications
INSERT INTO credit_scores (customer_id, application_id, score, score_date, rating, factors) VALUES
(1, 1, 780, '2024-01-15', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "stable", "debt_to_income": 0.25}'),
(2, 2, 720, '2024-01-16', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.35}'),
(3, 3, 850, '2024-01-17', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "very_stable", "debt_to_income": 0.20}'),
(4, 4, 680, '2024-01-18', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.40}'),
(5, 5, 750, '2024-01-19', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "stable", "debt_to_income": 0.30}'),
(6, 6, 650, '2024-01-20', 'good', '{"income_stability": "medium", "credit_history": "fair", "employment": "stable", "debt_to_income": 0.45}'),
(7, 7, 820, '2024-01-21', 'excellent', '{"income_stability": "high", "credit_history": "excellent", "employment": "very_stable", "debt_to_income": 0.22}'),
(8, 8, 700, '2024-01-22', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.38}'),
(9, 9, 580, '2024-01-23', 'fair', '{"income_stability": "low", "credit_history": "fair", "employment": "unstable", "debt_to_income": 0.50}'),
(10, 10, 720, '2024-01-24', 'good', '{"income_stability": "medium", "credit_history": "good", "employment": "stable", "debt_to_income": 0.35}');

-- Insert approval workflows
INSERT INTO approval_workflows (application_id, approver_level, approver_id, approver_name, action, comments, action_date, status) VALUES
(1, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'approve', 'Đơn đáp ứng đủ điều kiện', '2024-01-16 14:30:00', 'approved'),
(2, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'request_info', 'Cần thêm thông tin người bảo lãnh', '2024-01-16 15:00:00', 'pending'),
(2, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'approve', 'Đã có đủ thông tin', '2024-01-17 16:00:00', 'approved'),
(3, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'approve', 'Đơn được phê duyệt nhanh', '2024-01-18 10:00:00', 'approved'),
(4, 1, 'APP002', 'Trần Thị Xét Duyệt', 'approve', 'Phê duyệt với lãi suất ưu đãi', '2024-01-19 15:20:00', 'approved'),
(5, 1, 'APP002', 'Trần Thị Xét Duyệt', 'approve', 'Đơn được phê duyệt', '2024-01-20 11:45:00', 'approved'),
(7, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'approve', 'Phê duyệt với tài sản thế chấp', '2024-01-22 13:00:00', 'approved'),
(8, 1, 'APP002', 'Trần Thị Xét Duyệt', 'approve', 'Đơn được phê duyệt', '2024-01-23 14:30:00', 'approved'),
(9, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'reject', 'Điểm tín dụng không đủ', '2024-01-24 09:00:00', 'rejected'),
(10, 1, 'APP002', 'Trần Thị Xét Duyệt', 'approve', 'Phê duyệt với điều kiện', '2024-01-25 10:30:00', 'approved'),
(12, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'approve', 'Đơn được phê duyệt', '2024-01-27 15:00:00', 'approved'),
(13, 1, 'APP002', 'Trần Thị Xét Duyệt', 'reject', 'Thu nhập không ổn định', '2024-01-28 10:00:00', 'rejected'),
(14, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'approve', 'Phê duyệt với tài sản thế chấp', '2024-01-29 11:20:00', 'approved'),
(16, 1, 'APP002', 'Trần Thị Xét Duyệt', 'approve', 'Đơn được phê duyệt', '2024-01-31 14:00:00', 'approved'),
(17, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'reject', 'Lịch sử tín dụng kém', '2024-02-02 09:30:00', 'rejected'),
(18, 1, 'APP002', 'Trần Thị Xét Duyệt', 'approve', 'Phê duyệt với người bảo lãnh', '2024-02-03 10:45:00', 'approved'),
(19, 1, 'APP001', 'Nguyễn Văn Phê Duyệt', 'approve', 'Phê duyệt với tài sản thế chấp và người bảo lãnh', '2024-02-04 12:00:00', 'approved'),
(20, 1, 'APP002', 'Trần Thị Xét Duyệt', 'approve', 'Đơn được phê duyệt', '2024-02-05 13:30:00', 'approved');

