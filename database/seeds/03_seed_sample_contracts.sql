-- Seed: Sample loan contracts data
-- Description: Insert realistic sample loan contract data with disbursements, payment schedules, collaterals, guarantors, repayments, and collections

-- Insert loan contracts
INSERT INTO loan_contracts (application_id, contract_number, principal_amount, interest_rate, term_months, disbursement_date, maturity_date, first_payment_date, payment_frequency, status, signed_at) VALUES
(1, 'CONTRACT-20240116-000001', 50000000, 12.5, 24, '2024-01-20', '2026-01-20', '2024-02-20', 'monthly', 'active', '2024-01-16 15:00:00'),
(2, 'CONTRACT-20240117-000002', 100000000, 13.0, 36, '2024-01-22', '2027-01-22', '2024-02-22', 'monthly', 'active', '2024-01-17 16:30:00'),
(3, 'CONTRACT-20240118-000003', 200000000, 11.5, 48, '2024-01-25', '2028-01-25', '2024-02-25', 'monthly', 'active', '2024-01-18 11:00:00'),
(4, 'CONTRACT-20240119-000004', 75000000, 12.0, 30, '2024-01-23', '2026-07-23', '2024-02-23', 'monthly', 'active', '2024-01-19 16:00:00'),
(5, 'CONTRACT-20240120-000005', 150000000, 12.8, 36, '2024-01-26', '2027-01-26', '2024-02-26', 'monthly', 'active', '2024-01-20 12:00:00'),
(7, 'CONTRACT-20240122-000006', 250000000, 10.5, 60, '2024-01-28', '2029-01-28', '2024-02-28', 'monthly', 'active', '2024-01-22 14:00:00'),
(8, 'CONTRACT-20240123-000007', 80000000, 13.2, 24, '2024-01-25', '2026-01-25', '2024-02-25', 'monthly', 'active', '2024-01-23 15:00:00'),
(10, 'CONTRACT-20240125-000008', 120000000, 12.3, 36, '2024-01-30', '2027-01-30', '2024-02-29', 'monthly', 'active', '2024-01-25 11:00:00'),
(12, 'CONTRACT-20240127-000009', 90000000, 13.5, 30, '2024-02-01', '2026-08-01', '2024-03-01', 'monthly', 'active', '2024-01-27 16:00:00'),
(14, 'CONTRACT-20240129-000010', 180000000, 11.0, 48, '2024-02-05', '2028-02-05', '2024-03-05', 'monthly', 'active', '2024-01-29 12:00:00'),
(16, 'CONTRACT-20240131-000011', 110000000, 12.7, 36, '2024-02-06', '2027-02-06', '2024-03-06', 'monthly', 'active', '2024-01-31 15:00:00'),
(18, 'CONTRACT-20240203-000012', 95000000, 13.1, 30, '2024-02-08', '2026-08-08', '2024-03-08', 'monthly', 'active', '2024-02-03 11:00:00'),
(19, 'CONTRACT-20240204-000013', 300000000, 10.0, 60, '2024-02-10', '2029-02-10', '2024-03-10', 'monthly', 'active', '2024-02-04 13:00:00'),
(20, 'CONTRACT-20240205-000014', 85000000, 13.3, 30, '2024-02-12', '2026-08-12', '2024-03-12', 'monthly', 'active', '2024-02-05 14:00:00');

-- Insert disbursements
INSERT INTO disbursements (contract_id, disbursement_number, amount, disbursement_date, disbursement_method, bank_account, transaction_reference, status, completed_at) VALUES
(1, 'DISB-20240120-000001', 50000000, '2024-01-20', 'bank_transfer', '1234567890', 'TXN001', 'completed', '2024-01-20 10:00:00'),
(2, 'DISB-20240122-000002', 100000000, '2024-01-22', 'bank_transfer', '1234567891', 'TXN002', 'completed', '2024-01-22 11:00:00'),
(3, 'DISB-20240125-000003', 200000000, '2024-01-25', 'bank_transfer', '1234567892', 'TXN003', 'completed', '2024-01-25 09:00:00'),
(4, 'DISB-20240123-000004', 75000000, '2024-01-23', 'bank_transfer', '1234567893', 'TXN004', 'completed', '2024-01-23 14:00:00'),
(5, 'DISB-20240126-000005', 150000000, '2024-01-26', 'bank_transfer', '1234567894', 'TXN005', 'completed', '2024-01-26 10:30:00'),
(6, 'DISB-20240128-000006', 250000000, '2024-01-28', 'bank_transfer', '1234567895', 'TXN006', 'completed', '2024-01-28 11:00:00'),
(7, 'DISB-20240125-000007', 80000000, '2024-01-25', 'bank_transfer', '1234567896', 'TXN007', 'completed', '2024-01-25 15:30:00'),
(8, 'DISB-20240130-000008', 120000000, '2024-01-30', 'bank_transfer', '1234567897', 'TXN008', 'completed', '2024-01-30 09:00:00'),
(9, 'DISB-20240201-000009', 90000000, '2024-02-01', 'bank_transfer', '1234567898', 'TXN009', 'completed', '2024-02-01 10:00:00'),
(10, 'DISB-20240205-000010', 180000000, '2024-02-05', 'bank_transfer', '1234567899', 'TXN010', 'completed', '2024-02-05 11:30:00'),
(11, 'DISB-20240206-000011', 110000000, '2024-02-06', 'bank_transfer', '1234567900', 'TXN011', 'completed', '2024-02-06 09:30:00'),
(12, 'DISB-20240208-000012', 95000000, '2024-02-08', 'bank_transfer', '1234567901', 'TXN012', 'completed', '2024-02-08 10:00:00'),
(13, 'DISB-20240210-000013', 300000000, '2024-02-10', 'bank_transfer', '1234567902', 'TXN013', 'completed', '2024-02-10 11:00:00'),
(14, 'DISB-20240212-000014', 85000000, '2024-02-12', 'bank_transfer', '1234567903', 'TXN014', 'completed', '2024-02-12 14:00:00');

-- Insert interest rate schedules
INSERT INTO interest_rate_schedules (contract_id, effective_date, rate, rate_type, base_rate, spread, calculation_method, status) VALUES
(1, '2024-01-20', 12.5, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(2, '2024-01-22', 13.0, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(3, '2024-01-25', 11.5, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(4, '2024-01-23', 12.0, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(5, '2024-01-26', 12.8, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(6, '2024-01-28', 10.5, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(7, '2024-01-25', 13.2, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(8, '2024-01-30', 12.3, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(9, '2024-02-01', 13.5, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(10, '2024-02-05', 11.0, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(11, '2024-02-06', 12.7, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(12, '2024-02-08', 13.1, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(13, '2024-02-10', 10.0, 'fixed', NULL, NULL, 'simple_interest', 'active'),
(14, '2024-02-12', 13.3, 'fixed', NULL, NULL, 'simple_interest', 'active');

-- Insert payment schedules (first 6 months for each contract)
INSERT INTO payment_schedules (contract_id, installment_number, due_date, principal_due, interest_due, total_due, paid_amount, outstanding_amount, status) VALUES
-- Contract 1 (50M, 24 months, 12.5%)
(1, 1, '2024-02-20', 1958333, 520833, 2479166, 2479166, 0, 'paid'),
(1, 2, '2024-03-20', 1978724, 500244, 2478968, 2478968, 0, 'paid'),
(1, 3, '2024-04-20', 1999333, 479635, 2478968, 2478968, 0, 'paid'),
(1, 4, '2024-05-20', 2020058, 458911, 2478969, 2478969, 0, 'paid'),
(1, 5, '2024-06-20', 2040900, 438069, 2478969, 2478969, 0, 'paid'),
(1, 6, '2024-07-20', 2061860, 417108, 2478968, 0, 2478968, 'pending'),

-- Contract 2 (100M, 36 months, 13.0%)
(2, 1, '2024-02-22', 2527778, 1083333, 3611111, 3611111, 0, 'paid'),
(2, 2, '2024-03-22', 2555153, 1055958, 3611111, 3611111, 0, 'paid'),
(2, 3, '2024-04-22', 2582734, 1028377, 3611111, 3611111, 0, 'paid'),
(2, 4, '2024-05-22', 2610523, 1000588, 3611111, 3611111, 0, 'paid'),
(2, 5, '2024-06-22', 2638521, 972590, 3611111, 3611111, 0, 'paid'),
(2, 6, '2024-07-22', 2666730, 944381, 3611111, 0, 3611111, 'pending'),

-- Contract 3 (200M, 48 months, 11.5%)
(3, 1, '2024-02-25', 3958333, 1916667, 5875000, 5875000, 0, 'paid'),
(3, 2, '2024-03-25', 3996302, 1878698, 5875000, 5875000, 0, 'paid'),
(3, 3, '2024-04-25', 4034533, 1840467, 5875000, 5875000, 0, 'paid'),
(3, 4, '2024-05-25', 4073028, 1801972, 5875000, 5875000, 0, 'paid'),
(3, 5, '2024-06-25', 4111790, 1763210, 5875000, 5875000, 0, 'paid'),
(3, 6, '2024-07-25', 4150821, 1724179, 5875000, 0, 5875000, 'pending'),

-- Contract 4 (75M, 30 months, 12.0%)
(4, 1, '2024-02-23', 2333333, 750000, 3083333, 3083333, 0, 'paid'),
(4, 2, '2024-03-23', 2356667, 726667, 3083334, 3083334, 0, 'paid'),
(4, 3, '2024-04-23', 2380133, 703201, 3083334, 3083334, 0, 'paid'),
(4, 4, '2024-05-23', 2403733, 679601, 3083334, 3083334, 0, 'paid'),
(4, 5, '2024-06-23', 2427467, 655867, 3083334, 3083334, 0, 'paid'),
(4, 6, '2024-07-23', 2451333, 632001, 3083334, 0, 3083334, 'pending'),

-- Contract 5 (150M, 36 months, 12.8%)
(5, 1, '2024-02-26', 3791667, 1600000, 5391667, 5391667, 0, 'paid'),
(5, 2, '2024-03-26', 3832153, 1559514, 5391667, 5391667, 0, 'paid'),
(5, 3, '2024-04-26', 3872859, 1518808, 5391667, 5391667, 0, 'paid'),
(5, 4, '2024-05-26', 3913786, 1477881, 5391667, 5391667, 0, 'paid'),
(5, 5, '2024-06-26', 3954935, 1436732, 5391667, 5391667, 0, 'paid'),
(5, 6, '2024-07-26', 3996308, 1395359, 5391667, 0, 5391667, 'pending');

-- Insert collaterals
INSERT INTO collaterals (contract_id, collateral_type, description, estimated_value, appraised_value, ownership_document, location, status) VALUES
(3, 'real_estate', 'Căn hộ chung cư tại Quận 1', 250000000, 280000000, 'Sổ đỏ số 12345', '123 Đường Nguyễn Huệ, Quận 1, TP.HCM', 'active'),
(6, 'real_estate', 'Nhà phố tại Quận 3', 300000000, 320000000, 'Sổ đỏ số 67890', '456 Đường Pasteur, Quận 3, TP.HCM', 'active'),
(10, 'vehicle', 'Xe ô tô Toyota Camry 2023', 200000000, 210000000, 'Đăng ký xe số 123ABC', 'TP.HCM', 'active'),
(13, 'real_estate', 'Biệt thự tại Quận 2', 350000000, 400000000, 'Sổ đỏ số 11111', '789 Đường Nguyễn Thị Định, Quận 2, TP.HCM', 'active'),
(13, 'deposit', 'Tiền gửi ngân hàng', 50000000, 50000000, 'Sổ tiết kiệm số 99999', 'Ngân hàng ABC', 'active');

-- Insert guarantors
INSERT INTO guarantors (contract_id, full_name, id_number, phone, email, address, relationship_with_customer, guarantee_amount, status) VALUES
(2, 'Trần Văn Bảo Lãnh', '009876543210', '0987654321', 'tranvanbaolanh@email.com', '789 Đường Lê Lợi, Quận 1, TP.HCM', 'Anh trai', 100000000, 'active'),
(7, 'Lê Thị Bảo Lãnh', '009876543211', '0987654322', 'lethibaolanh@email.com', '321 Đường Nguyễn Huệ, Quận 1, TP.HCM', 'Chị gái', 80000000, 'active'),
(12, 'Phạm Văn Bảo Lãnh', '009876543212', '0987654323', 'phamvanbaolanh@email.com', '654 Đường Pasteur, Quận 3, TP.HCM', 'Bạn thân', 95000000, 'active'),
(13, 'Hoàng Thị Bảo Lãnh', '009876543213', '0987654324', 'hoangthibaolanh@email.com', '987 Đường Điện Biên Phủ, Quận Bình Thạnh, TP.HCM', 'Vợ', 300000000, 'active'),
(13, 'Vũ Văn Bảo Lãnh', '009876543214', '0987654325', 'vuvanbaolanh@email.com', '147 Đường Cách Mạng Tháng 8, Quận 10, TP.HCM', 'Anh rể', 300000000, 'active');

-- Insert repayments (some sample repayments)
INSERT INTO repayments (contract_id, scheduled_date, actual_payment_date, principal_amount, interest_amount, penalty_amount, total_amount, payment_method, transaction_reference, status, paid_at) VALUES
(1, '2024-02-20', '2024-02-20', 1958333, 520833, 0, 2479166, 'bank_transfer', 'REP001', 'paid', '2024-02-20 10:00:00'),
(1, '2024-03-20', '2024-03-20', 1978724, 500244, 0, 2478968, 'bank_transfer', 'REP002', 'paid', '2024-03-20 09:30:00'),
(1, '2024-04-20', '2024-04-20', 1999333, 479635, 0, 2478968, 'bank_transfer', 'REP003', 'paid', '2024-04-20 11:00:00'),
(1, '2024-05-20', '2024-05-20', 2020058, 458911, 0, 2478969, 'bank_transfer', 'REP004', 'paid', '2024-05-20 10:15:00'),
(1, '2024-06-20', '2024-06-20', 2040900, 438069, 0, 2478969, 'bank_transfer', 'REP005', 'paid', '2024-06-20 09:45:00'),
(2, '2024-02-22', '2024-02-22', 2527778, 1083333, 0, 3611111, 'bank_transfer', 'REP006', 'paid', '2024-02-22 14:00:00'),
(2, '2024-03-22', '2024-03-22', 2555153, 1055958, 0, 3611111, 'bank_transfer', 'REP007', 'paid', '2024-03-22 13:30:00'),
(2, '2024-04-22', '2024-04-22', 2582734, 1028377, 0, 3611111, 'bank_transfer', 'REP008', 'paid', '2024-04-22 15:00:00'),
(2, '2024-05-22', '2024-05-22', 2610523, 1000588, 0, 3611111, 'bank_transfer', 'REP009', 'paid', '2024-05-22 14:20:00'),
(2, '2024-06-22', '2024-06-22', 2638521, 972590, 0, 3611111, 'bank_transfer', 'REP010', 'paid', '2024-06-22 13:45:00');

-- Insert collections (for demonstration - some contracts might have collection activities)
INSERT INTO collections (contract_id, collection_type, collection_date, amount_due, amount_collected, assigned_to, notes, next_action_date, status) VALUES
(1, 'reminder', '2024-07-25', 2478968, 0, 'Nhân viên thu hồi 1', 'Gửi thông báo nhắc nhở thanh toán', '2024-08-01', 'open'),
(2, 'warning', '2024-07-28', 3611111, 0, 'Nhân viên thu hồi 2', 'Cảnh báo về khoản nợ quá hạn', '2024-08-05', 'open');

