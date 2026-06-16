# Hệ thống Database Quản lý Cho vay

Hệ thống cơ sở dữ liệu MySQL để quản lý toàn bộ vòng đời của khoản vay, từ đơn xin vay ban đầu đến khi hoàn tất trả nợ hoặc thu hồi.

## Tính năng

- **Quản lý khách hàng**: Lưu trữ thông tin khách hàng và lịch sử giao dịch
- **Đơn xin vay**: Quản lý đơn xin vay với quy trình phê duyệt đa cấp
- **Hợp đồng vay**: Quản lý hợp đồng vay với lãi suất linh hoạt (cố định/thả nổi)
- **Giải ngân**: Theo dõi các giao dịch giải ngân
- **Trả nợ**: Quản lý lịch trả nợ và các khoản thanh toán
- **Thu hồi**: Theo dõi hoạt động thu hồi nợ quá hạn
- **Tài sản thế chấp**: Quản lý tài sản đảm bảo
- **Người bảo lãnh**: Quản lý thông tin người bảo lãnh
- **Đánh giá tín dụng**: Hệ thống điểm tín dụng với các yếu tố đánh giá
- **Quy trình phê duyệt**: Quy trình phê duyệt đa cấp với lịch sử đầy đủ

## Yêu cầu hệ thống

- MySQL 8.0 trở lên
- Quyền tạo database, tables, triggers, và views

## Cấu trúc thư mục

```
oltp-db-engineering/
├── database/
│   ├── schema/              # Schema definitions (nếu có)
│   ├── schema/              # Schema SQL scripts (run in order)
│   │   ├── 001_create_customers_table.sql
│   │   ├── 002_create_loan_applications_table.sql
│   │   ├── 003_create_loan_contracts_table.sql
│   │   ├── 004_create_disbursements_table.sql
│   │   ├── 005_create_repayments_table.sql
│   │   ├── 006_create_collections_table.sql
│   │   ├── 007_create_collaterals_table.sql
│   │   ├── 008_create_guarantors_table.sql
│   │   ├── 009_create_credit_scores_table.sql
│   │   ├── 010_create_approval_workflows_table.sql
│   │   ├── 011_create_interest_rate_schedules_table.sql
│   │   ├── 012_create_payment_schedules_table.sql
│   │   └── 013_add_indexes_and_constraints.sql
│   └── seeds/               # Sample data
│       ├── 01_seed_customers.sql
│       ├── 02_seed_sample_applications.sql
│       └── 03_seed_sample_contracts.sql
└── docs/                    # Documentation
    ├── database_design.md
    └── entity_relationship_diagram.md
```

## Hướng dẫn Setup

> **Lưu ý**: Đây là hướng dẫn setup nhanh. Để triển khai trên production, vui lòng tham khảo [Deployment Guide](docs/deployment_guide.md) để có hướng dẫn chi tiết về cài đặt MySQL, cấu hình bảo mật, backup, và monitoring.

### 1. Tạo Database

```sql
CREATE DATABASE loan_management CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE loan_management;
```

### 2. Chạy Migrations

Chạy các file migration theo thứ tự số:

```bash
# Cách 1: Sử dụng MySQL command line
mysql -u your_username -p loan_management < database/schema/001_create_customers_table.sql
mysql -u your_username -p loan_management < database/schema/002_create_loan_applications_table.sql
mysql -u your_username -p loan_management < database/schema/003_create_loan_contracts_table.sql
mysql -u your_username -p loan_management < database/schema/004_create_disbursements_table.sql
mysql -u your_username -p loan_management < database/schema/005_create_repayments_table.sql
mysql -u your_username -p loan_management < database/schema/006_create_collections_table.sql
mysql -u your_username -p loan_management < database/schema/007_create_collaterals_table.sql
mysql -u your_username -p loan_management < database/schema/008_create_guarantors_table.sql
mysql -u your_username -p loan_management < database/schema/009_create_credit_scores_table.sql
mysql -u your_username -p loan_management < database/schema/010_create_approval_workflows_table.sql
mysql -u your_username -p loan_management < database/schema/011_create_interest_rate_schedules_table.sql
mysql -u your_username -p loan_management < database/schema/012_create_payment_schedules_table.sql
mysql -u your_username -p loan_management < database/schema/013_add_indexes_and_constraints.sql
```

Hoặc chạy tất cả cùng lúc:

```bash
# Cách 2: Sử dụng script
for file in database/schema/*.sql; do
    mysql -u your_username -p loan_management < "$file"
done
```

### 3. Seed Data (Tùy chọn)

Sau khi chạy migrations, bạn có thể seed dữ liệu mẫu:

```bash
mysql -u your_username -p loan_management < database/seeds/01_seed_customers.sql
mysql -u your_username -p loan_management < database/seeds/02_seed_sample_applications.sql
mysql -u your_username -p loan_management < database/seeds/03_seed_sample_contracts.sql
```

Hoặc chạy tất cả:

```bash
for file in database/seeds/*.sql; do
    mysql -u your_username -p loan_management < "$file"
done
```

## Kiểm tra Installation

Sau khi setup, bạn có thể kiểm tra bằng các query sau:

```sql
-- Kiểm tra số lượng bảng
SHOW TABLES;

-- Kiểm tra số lượng customers
SELECT COUNT(*) FROM customers;

-- Kiểm tra số lượng applications
SELECT COUNT(*) FROM loan_applications;

-- Kiểm tra số lượng contracts
SELECT COUNT(*) FROM loan_contracts;

-- Xem loan summary view
SELECT * FROM vw_loan_summary LIMIT 10;
```

## Sử dụng View

Hệ thống có một view `vw_loan_summary` để xem tổng quan về các khoản vay:

```sql
-- Xem tất cả loans với thông tin tổng hợp
SELECT * FROM vw_loan_summary;

-- Xem loans đang active
SELECT * FROM vw_loan_summary WHERE contract_status = 'active';

-- Xem loans có nợ quá hạn
SELECT * FROM vw_loan_summary WHERE overdue_installments > 0;
```

## Các Query Mẫu

### Tìm đơn vay của một khách hàng

```sql
SELECT 
    la.application_number,
    la.loan_amount,
    la.status,
    la.submitted_at,
    cs.score,
    cs.rating
FROM loan_applications la
LEFT JOIN credit_scores cs ON la.application_id = cs.application_id
WHERE la.customer_id = 1
ORDER BY la.submitted_at DESC;
```

### Xem chi tiết hợp đồng và thanh toán

```sql
SELECT 
    c.contract_number,
    c.principal_amount,
    c.interest_rate,
    c.status,
    COUNT(ps.schedule_id) as total_installments,
    SUM(ps.outstanding_amount) as total_outstanding,
    COUNT(CASE WHEN ps.status = 'overdue' THEN 1 END) as overdue_count
FROM loan_contracts c
LEFT JOIN payment_schedules ps ON c.contract_id = ps.contract_id
WHERE c.contract_id = 1
GROUP BY c.contract_id;
```

### Tìm các khoản nợ quá hạn

```sql
SELECT 
    c.contract_number,
    cu.full_name,
    ps.due_date,
    ps.outstanding_amount,
    DATEDIFF(CURDATE(), ps.due_date) as days_overdue
FROM payment_schedules ps
INNER JOIN loan_contracts c ON ps.contract_id = c.contract_id
INNER JOIN loan_applications la ON c.application_id = la.application_id
INNER JOIN customers cu ON la.customer_id = cu.customer_id
WHERE ps.status = 'overdue'
  AND ps.outstanding_amount > 0
ORDER BY ps.due_date ASC;
```

## Troubleshooting

### Lỗi Foreign Key Constraint

Nếu gặp lỗi foreign key constraint, đảm bảo:
1. Chạy migrations theo đúng thứ tự
2. Không có dữ liệu orphan trong các bảng

### Lỗi Trigger

Nếu trigger không hoạt động:
1. Kiểm tra MySQL version (cần 8.0+)
2. Kiểm tra quyền của user (cần CREATE TRIGGER privilege)

### Lỗi Character Set

Nếu gặp lỗi về character set:
1. Đảm bảo database được tạo với utf8mb4
2. Kiểm tra connection charset trong client

## Tài liệu tham khảo

- [Deployment Guide](docs/deployment_guide.md) - Hướng dẫn triển khai trên bare metal
- [Database Design](docs/database_design.md) - Chi tiết thiết kế database
- [Entity Relationship Diagram](docs/entity_relationship_diagram.md) - Mối quan hệ giữa các bảng

## License

Internal use only.

