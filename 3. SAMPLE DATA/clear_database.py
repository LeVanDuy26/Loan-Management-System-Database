#!/usr/bin/env python3
"""
Script Xóa Sạch Dữ Liệu Trong Cơ Sở Dữ Liệu Quản Lý Khoản Vay
Xóa dữ liệu ở tất cả các bảng theo đúng trình tự khóa ngoại hoặc tắt khóa ngoại tạm thời.
"""

import mysql.connector
import sys

# Cấu hình kết nối cơ sở dữ liệu
config = {
    'user': 'root',
    'password': '26052004',  # Sử dụng mật khẩu của bạn
    'host': 'localhost',
    'port': 3306,
    'database': 'loan_management',
    'use_pure': True
}

def clear_database():
    print("=" * 60)
    print("Bắt đầu xóa sạch dữ liệu trong cơ sở dữ liệu loan_management...")
    print("=" * 60)
    
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        
        # 1. Tắt kiểm tra khóa ngoại tạm thời để tránh lỗi ràng buộc
        print("1. Tắt kiểm tra ràng buộc khóa ngoại...")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
        
        # Danh sách các bảng cần xóa (xóa tất cả 12 bảng chính)
        tables = [
            'payment_schedules',
            'interest_rate_schedules',
            'approval_workflows',
            'credit_scores',
            'guarantors',
            'collaterals',
            'collections',
            'repayments',
            'disbursements',
            'loan_contracts',
            'loan_applications',
            'customers'
        ]
        
        # 2. Thực hiện TRUNCATE từng bảng để xóa sạch dữ liệu và reset AUTO_INCREMENT
        print("2. Đang xóa dữ liệu trong các bảng...")
        for table in tables:
            try:
                cursor.execute(f"TRUNCATE TABLE {table};")
                print(f"  ✓ Đã xóa sạch bảng: {table}")
            except mysql.connector.Error as err:
                # Nếu bảng chưa tồn tại hoặc lỗi khác, ta in cảnh báo
                print(f"  ⚠ Không thể truncate bảng {table}: {err}")
        
        # 3. Bật lại kiểm tra khóa ngoại
        print("3. Bật lại kiểm tra ràng buộc khóa ngoại...")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")
        
        conn.commit()
        cursor.close()
        conn.close()
        
        print("=" * 60)
        print("✓ Đã xóa toàn bộ dữ liệu thành công!")
        print("=" * 60)
        
    except mysql.connector.Error as e:
        print(f"✗ Lỗi kết nối cơ sở dữ liệu: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Lỗi hệ thống: {e}")
        sys.exit(1)

if __name__ == '__main__':
    # Hỏi xác nhận trước khi xóa để tránh thao tác nhầm trên database thật
    confirm = input("CẢNH BÁO: Hành động này sẽ xóa SẠCH TOÀN BỘ dữ liệu trong database.\nBạn có chắc chắn muốn tiếp tục? (y/n): ")
    if confirm.lower() == 'y' or confirm.lower() == 'yes':
        clear_database()
    else:
        print("Đã hủy thao tác xóa dữ liệu.")
