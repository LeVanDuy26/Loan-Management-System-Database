# Hướng dẫn Triển khai trên Bare Metal

Hướng dẫn chi tiết để triển khai hệ thống database quản lý cho vay trên máy chủ vật lý (bare metal) không sử dụng Docker.

## Mục lục

1. [Yêu cầu Hệ thống](#yêu-cầu-hệ-thống)
2. [Cài đặt MySQL](#cài-đặt-mysql)
3. [Cấu hình MySQL](#cấu-hình-mysql)
4. [Tạo Database và User](#tạo-database-và-user)
5. [Triển khai Schema](#triển-khai-schema)
6. [Seed Dữ liệu](#seed-dữ-liệu)
7. [Cấu hình Bảo mật](#cấu-hình-bảo-mật)
8. [Backup và Restore](#backup-và-restore)
9. [Monitoring và Maintenance](#monitoring-và-maintenance)
10. [Troubleshooting](#troubleshooting)

## Yêu cầu Hệ thống

### Phần cứng tối thiểu

- **CPU**: 2 cores trở lên
- **RAM**: 4GB trở lên (khuyến nghị 8GB cho production)
- **Disk**: 
  - Tối thiểu 20GB trống
  - Khuyến nghị SSD cho production
  - IOPS tối thiểu 1000
- **Network**: Kết nối ổn định với bandwidth đủ cho ứng dụng

### Phần mềm

- **OS**: Ubuntu 20.04 LTS / Ubuntu 22.04 LTS / CentOS 7+ / RHEL 8+
- **MySQL**: 8.0 trở lên
- **Python 3.6+** (cho các script tự động hóa, tùy chọn)

## Cài đặt MySQL

### Ubuntu/Debian

```bash
# Cập nhật package list
sudo apt update

# Cài đặt MySQL Server
sudo apt install mysql-server -y

# Kiểm tra trạng thái MySQL
sudo systemctl status mysql

# Khởi động MySQL (nếu chưa chạy)
sudo systemctl start mysql
sudo systemctl enable mysql
```

### CentOS/RHEL

```bash
# Cài đặt MySQL repository
sudo yum install mysql-server -y

# Hoặc cho RHEL 8+
sudo dnf install mysql-server -y

# Khởi động MySQL
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Kiểm tra trạng thái
sudo systemctl status mysqld
```

### Cài đặt MySQL từ MySQL Repository (Khuyến nghị cho Production)

```bash
# Ubuntu/Debian
wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.24-1_all.deb
sudo apt update
sudo apt install mysql-server -y

# CentOS/RHEL
sudo yum install https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
sudo yum install mysql-server -y
```

### Thiết lập bảo mật ban đầu

```bash
# Chạy script bảo mật MySQL
sudo mysql_secure_installation
```

Trả lời các câu hỏi:
- **Validate Password Plugin**: Y (khuyến nghị)
- **Password Strength**: Chọn mức độ phù hợp (thường là 1 hoặc 2)
- **Root Password**: Đặt mật khẩu mạnh
- **Remove anonymous users**: Y
- **Disallow root login remotely**: Y (nếu không cần remote root access)
- **Remove test database**: Y
- **Reload privilege tables**: Y

## Cấu hình MySQL

### Chỉnh sửa file cấu hình

```bash
# Tìm file cấu hình MySQL
sudo find /etc -name "my.cnf" 2>/dev/null
# Hoặc
sudo find /etc -name "mysql.cnf" 2>/dev/null

# Thường nằm ở:
# Ubuntu/Debian: /etc/mysql/mysql.conf.d/mysqld.cnf
# CentOS/RHEL: /etc/my.cnf
```

### Cấu hình tối ưu cho Production

Thêm hoặc chỉnh sửa các tham số sau trong file `my.cnf` hoặc `mysqld.cnf`:

```ini
[mysqld]
# Basic Settings
port = 3306
bind-address = 127.0.0.1  # Hoặc IP của server nếu cần remote access
datadir = /var/lib/mysql
socket = /var/lib/mysql/mysql.sock

# Character Set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Performance Tuning (điều chỉnh theo RAM của server)
# Cho server 4GB RAM
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Cho server 8GB RAM trở lên
# innodb_buffer_pool_size = 4G
# innodb_log_file_size = 512M

# Connection Settings
max_connections = 200
max_connect_errors = 10000
wait_timeout = 600
interactive_timeout = 600

# Query Cache (MySQL 8.0 đã loại bỏ, bỏ qua nếu dùng 8.0+)
# query_cache_type = 1
# query_cache_size = 64M

# Logging
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2

# Binary Logging (cho replication và point-in-time recovery)
log_bin = /var/log/mysql/mysql-bin.log
binlog_expire_logs_seconds = 604800  # 7 days
max_binlog_size = 100M

# Security
local_infile = 0
```

### Tạo thư mục log nếu chưa có

```bash
sudo mkdir -p /var/log/mysql
sudo chown mysql:mysql /var/log/mysql
```

### Khởi động lại MySQL để áp dụng cấu hình

```bash
sudo systemctl restart mysql
# Hoặc
sudo systemctl restart mysqld

# Kiểm tra log để đảm bảo không có lỗi
sudo tail -f /var/log/mysql/error.log
```

## Tạo Database và User

### Đăng nhập MySQL

```bash
# Đăng nhập với root
sudo mysql -u root -p
```

### Tạo Database

```sql
-- Tạo database với character set utf8mb4
CREATE DATABASE loan_management 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- Xác nhận database đã được tạo
SHOW DATABASES;
```

### Tạo User và Phân quyền

```sql
-- Tạo user cho ứng dụng
CREATE USER 'loan_app'@'localhost' IDENTIFIED BY 'your_strong_password_here';

-- Cấp quyền đầy đủ cho database loan_management
GRANT ALL PRIVILEGES ON loan_management.* TO 'loan_app'@'localhost';

-- Nếu cần remote access (thay localhost bằng IP hoặc %)
-- CREATE USER 'loan_app'@'%' IDENTIFIED BY 'your_strong_password_here';
-- GRANT ALL PRIVILEGES ON loan_management.* TO 'loan_app'@'%';

-- Tạo user chỉ đọc cho reporting
CREATE USER 'loan_readonly'@'localhost' IDENTIFIED BY 'readonly_password_here';
GRANT SELECT ON loan_management.* TO 'loan_readonly'@'localhost';

-- Áp dụng thay đổi
FLUSH PRIVILEGES;

-- Kiểm tra quyền
SHOW GRANTS FOR 'loan_app'@'localhost';
```

### Thoát MySQL

```sql
EXIT;
```

## Triển khai Schema

### Chuẩn bị

```bash
# Di chuyển đến thư mục project
cd /path/to/oltp-db-engineering

# Đảm bảo bạn có quyền đọc các file migration
ls -la database/schema/
```

### Chạy Migrations

#### Cách 1: Chạy từng file (Khuyến nghị cho lần đầu)

```bash
# Đăng nhập MySQL
mysql -u loan_app -p loan_management

# Trong MySQL, chạy từng file:
source database/schema/001_create_customers_table.sql;
source database/schema/002_create_loan_applications_table.sql;
source database/schema/003_create_loan_contracts_table.sql;
source database/schema/004_create_disbursements_table.sql;
source database/schema/005_create_repayments_table.sql;
source database/schema/006_create_collections_table.sql;
source database/schema/007_create_collaterals_table.sql;
source database/schema/008_create_guarantors_table.sql;
source database/schema/009_create_credit_scores_table.sql;
source database/schema/010_create_approval_workflows_table.sql;
source database/schema/011_create_interest_rate_schedules_table.sql;
source database/schema/012_create_payment_schedules_table.sql;
source database/schema/013_add_indexes_and_constraints.sql;
```

#### Cách 2: Chạy từ command line

```bash
# Tạo script tự động
cat > deploy_migrations.sh << 'EOF'
#!/bin/bash

DB_USER="loan_app"
DB_NAME="loan_management"
MIGRATION_DIR="database/schema"

echo "Starting migration deployment..."

for file in $(ls $MIGRATION_DIR/*.sql | sort); do
    echo "Running: $file"
    mysql -u $DB_USER -p $DB_NAME < $file
    if [ $? -eq 0 ]; then
        echo "✓ Success: $file"
    else
        echo "✗ Failed: $file"
        exit 1
    fi
done

echo "All migrations completed successfully!"
EOF

# Cấp quyền thực thi
chmod +x deploy_migrations.sh

# Chạy script
./deploy_migrations.sh
```

### Kiểm tra Schema

```sql
-- Đăng nhập MySQL
mysql -u loan_app -p loan_management

-- Kiểm tra các bảng đã được tạo
SHOW TABLES;

-- Kiểm tra cấu trúc một bảng
DESCRIBE customers;

-- Kiểm tra indexes
SHOW INDEXES FROM loan_contracts;

-- Kiểm tra triggers
SHOW TRIGGERS;

-- Kiểm tra view
SHOW FULL TABLES WHERE Table_type = 'VIEW';
```

## Seed Dữ liệu

### Chạy Seed Scripts

```bash
# Tạo script seed
cat > seed_data.sh << 'EOF'
#!/bin/bash

DB_USER="loan_app"
DB_NAME="loan_management"
SEED_DIR="database/seeds"

echo "Starting data seeding..."

for file in $(ls $SEED_DIR/*.sql | sort); do
    echo "Seeding: $file"
    mysql -u $DB_USER -p $DB_NAME < $file
    if [ $? -eq 0 ]; then
        echo "✓ Success: $file"
    else
        echo "✗ Failed: $file"
        exit 1
    fi
done

echo "Data seeding completed!"
EOF

chmod +x seed_data.sh
./seed_data.sh
```

### Kiểm tra Dữ liệu

```sql
-- Kiểm tra số lượng records
SELECT 
    'customers' as table_name, COUNT(*) as count FROM customers
UNION ALL
SELECT 'loan_applications', COUNT(*) FROM loan_applications
UNION ALL
SELECT 'loan_contracts', COUNT(*) FROM loan_contracts
UNION ALL
SELECT 'disbursements', COUNT(*) FROM disbursements
UNION ALL
SELECT 'repayments', COUNT(*) FROM repayments;

-- Kiểm tra view
SELECT * FROM vw_loan_summary LIMIT 10;
```

## Cấu hình Bảo mật

### Firewall

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 3306/tcp
sudo ufw enable

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-service=mysql
sudo firewall-cmd --reload

# Hoặc chỉ cho phép IP cụ thể
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port protocol="tcp" port="3306" accept'
sudo firewall-cmd --reload
```

### SSL/TLS (Khuyến nghị cho Production)

```sql
-- Tạo SSL certificates (chạy với root)
-- MySQL tự tạo certificates tại /var/lib/mysql/
-- Kiểm tra SSL
SHOW VARIABLES LIKE '%ssl%';

-- Yêu cầu SSL cho user
ALTER USER 'loan_app'@'localhost' REQUIRE SSL;
FLUSH PRIVILEGES;
```

### Audit Logging

```sql
-- Cài đặt audit plugin (nếu có)
INSTALL PLUGIN audit_log SONAME 'audit_log.so';

-- Hoặc sử dụng general log (chỉ cho development)
SET GLOBAL general_log = 'ON';
SET GLOBAL general_log_file = '/var/log/mysql/general.log';
```

### Regular Security Updates

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade mysql-server

# CentOS/RHEL
sudo yum update mysql-server
```

## Backup và Restore

### Backup Script

```bash
# Tạo script backup
cat > backup_database.sh << 'EOF'
#!/bin/bash

# Cấu hình
DB_USER="loan_app"
DB_NAME="loan_management"
BACKUP_DIR="/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Tạo thư mục backup
mkdir -p $BACKUP_DIR

# Full backup
mysqldump -u $DB_USER -p \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --master-data=2 \
    $DB_NAME | gzip > $BACKUP_DIR/loan_management_$DATE.sql.gz

# Xóa backup cũ
find $BACKUP_DIR -name "loan_management_*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: loan_management_$DATE.sql.gz"
EOF

chmod +x backup_database.sh
```

### Lên lịch Backup tự động (Cron)

```bash
# Chỉnh sửa crontab
crontab -e

# Thêm dòng sau để backup hàng ngày lúc 2:00 AM
0 2 * * * /path/to/backup_database.sh >> /var/log/mysql_backup.log 2>&1
```

### Restore từ Backup

```bash
# Giải nén và restore
gunzip < /backup/mysql/loan_management_20240101_020000.sql.gz | \
    mysql -u loan_app -p loan_management

# Hoặc restore từ file không nén
mysql -u loan_app -p loan_management < backup_file.sql
```

### Point-in-Time Recovery

```bash
# 1. Restore full backup
gunzip < full_backup.sql.gz | mysql -u loan_app -p loan_management

# 2. Apply binary logs từ thời điểm backup đến thời điểm cần restore
mysqlbinlog --start-datetime="2024-01-01 02:00:00" \
            --stop-datetime="2024-01-01 10:00:00" \
            /var/log/mysql/mysql-bin.000001 | \
    mysql -u loan_app -p loan_management
```

## Monitoring và Maintenance

### Monitoring Scripts

```bash
# Tạo script kiểm tra database
cat > check_database.sh << 'EOF'
#!/bin/bash

DB_USER="loan_app"
DB_NAME="loan_management"

echo "=== Database Status ==="
mysql -u $DB_USER -p$DB_PASSWORD -e "SHOW STATUS LIKE 'Threads_connected';"
mysql -u $DB_USER -p$DB_PASSWORD -e "SHOW STATUS LIKE 'Questions';"
mysql -u $DB_USER -p$DB_PASSWORD -e "SHOW STATUS LIKE 'Slow_queries';"

echo "=== Table Sizes ==="
mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME -e "
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = '$DB_NAME'
ORDER BY (data_length + index_length) DESC;
"

echo "=== Index Usage ==="
mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME -e "
SELECT 
    table_name,
    index_name,
    seq_in_index,
    column_name
FROM information_schema.STATISTICS
WHERE table_schema = '$DB_NAME'
ORDER BY table_name, index_name, seq_in_index;
"
EOF

chmod +x check_database.sh
```

### Maintenance Tasks

```sql
-- Optimize tables định kỳ
OPTIMIZE TABLE customers;
OPTIMIZE TABLE loan_applications;
OPTIMIZE TABLE loan_contracts;

-- Analyze tables để cập nhật statistics
ANALYZE TABLE customers;
ANALYZE TABLE loan_applications;

-- Kiểm tra và sửa lỗi tables
CHECK TABLE customers;
REPAIR TABLE customers;  -- Chỉ khi cần
```

### Log Rotation

```bash
# Cấu hình logrotate cho MySQL
sudo cat > /etc/logrotate.d/mysql << 'EOF'
/var/log/mysql/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 mysql mysql
    sharedscripts
    postrotate
        /usr/bin/mysqladmin flush-logs
    endscript
}
EOF
```

## Troubleshooting

### Kiểm tra Logs

```bash
# Error log
sudo tail -f /var/log/mysql/error.log

# Slow query log
sudo tail -f /var/log/mysql/slow-query.log

# General log (nếu bật)
sudo tail -f /var/log/mysql/general.log
```

### Các vấn đề thường gặp

#### 1. MySQL không khởi động

```bash
# Kiểm tra lỗi
sudo systemctl status mysql
sudo journalctl -xe

# Kiểm tra quyền file
sudo ls -la /var/lib/mysql/
sudo chown -R mysql:mysql /var/lib/mysql/

# Kiểm tra disk space
df -h
```

#### 2. Connection refused

```bash
# Kiểm tra MySQL đang chạy
sudo systemctl status mysql

# Kiểm tra port
sudo netstat -tlnp | grep 3306

# Kiểm tra bind-address trong my.cnf
sudo grep bind-address /etc/mysql/mysql.conf.d/mysqld.cnf
```

#### 3. Out of memory

```sql
-- Kiểm tra memory usage
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW STATUS LIKE 'Innodb_buffer_pool%';

-- Giảm buffer pool size nếu cần
-- Sửa trong my.cnf và restart MySQL
```

#### 4. Slow queries

```sql
-- Bật slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- Xem slow queries
SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;

-- Explain query
EXPLAIN SELECT * FROM loan_contracts WHERE status = 'active';
```

#### 5. Foreign key constraint errors

```sql
-- Kiểm tra foreign key constraints
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'loan_management'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- Tạm thời disable foreign key checks (cẩn thận!)
SET FOREIGN_KEY_CHECKS = 0;
-- Thực hiện operations
SET FOREIGN_KEY_CHECKS = 1;
```

### Reset Root Password

```bash
# 1. Stop MySQL
sudo systemctl stop mysql

# 2. Start MySQL in safe mode
sudo mysqld_safe --skip-grant-tables &

# 3. Connect và reset password
mysql -u root
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
EXIT;

# 4. Restart MySQL bình thường
sudo systemctl restart mysql
```

## Checklist Triển khai

- [ ] Cài đặt MySQL 8.0+
- [ ] Cấu hình MySQL (my.cnf)
- [ ] Tạo database và users
- [ ] Chạy tất cả migrations
- [ ] Seed dữ liệu mẫu (nếu cần)
- [ ] Cấu hình firewall
- [ ] Thiết lập backup tự động
- [ ] Cấu hình monitoring
- [ ] Test kết nối từ ứng dụng
- [ ] Document credentials và thông tin kết nối
- [ ] Tạo runbook cho operations team

## Tài liệu Tham khảo

- [MySQL 8.0 Documentation](https://dev.mysql.com/doc/refman/8.0/en/)
- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [MySQL Security Best Practices](https://dev.mysql.com/doc/refman/8.0/en/security.html)

## Liên hệ Hỗ trợ

Nếu gặp vấn đề trong quá trình triển khai, vui lòng:
1. Kiểm tra logs theo hướng dẫn trong phần Troubleshooting
2. Tham khảo tài liệu MySQL chính thức
3. Liên hệ team Database Engineering

