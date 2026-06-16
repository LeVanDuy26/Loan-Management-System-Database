#!/usr/bin/env python3
"""
Script Giám Sát Sức Khỏe Cơ Sở Dữ Liệu
Theo dõi các chỉ số sức khỏe của DB và cung cấp báo cáo trạng thái.
"""

import mysql.connector
from datetime import datetime
import sys

# Cấu hình kết nối cơ sở dữ liệu - CẦN CẬP NHẬT CÁC GIÁ TRỊ NÀY CHO PHÙ HỢP
config = {
    'user': 'root',
    'password': '26052004',  # CẬP NHẬT MẬT KHẨU TẠI ĐÂY
    'host': 'localhost',
    'database': 'loan_management',
    'use_pure': True
}

def get_status_value(cursor, status_name):
    """Hàm lấy giá trị của một biến trạng thái hệ thống (SHOW STATUS)"""
    cursor.execute(f"SHOW STATUS LIKE '{status_name}'")
    result = cursor.fetchone()
    return int(result[1]) if result else 0

def get_variable_value(cursor, var_name):
    """Hàm lấy giá trị của một biến cấu hình (SHOW VARIABLES)"""
    cursor.execute(f"SHOW VARIABLES LIKE '{var_name}'")
    result = cursor.fetchone()
    return result[1] if result else None

def monitor_database():
    """Hàm theo dõi và in báo cáo sức khỏe của cơ sở dữ liệu"""
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        
        print("=" * 60)
        print("Báo Cáo Sức Khỏe Cơ Sở Dữ Liệu")
        print(f"Thời gian: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        
        # 1. Các chỉ số về kết nối (Connection metrics)
        print("\n[Các Chỉ Số Kết Nối]")
        print("-" * 60)
        connections = get_status_value(cursor, 'Threads_connected') # Số kết nối hiện tại
        max_connections = get_variable_value(cursor, 'max_connections') # Giới hạn số kết nối tối đa
        connection_usage = (connections / int(max_connections)) * 100 if max_connections else 0
        print(f"Số kết nối đang hoạt động: {connections} / {max_connections} (Mức sử dụng: {connection_usage:.1f}%)")
        
        # 2. Các chỉ số về truy vấn (Query metrics)
        print("\n[Các Chỉ Số Truy Vấn (Query)]")
        print("-" * 60)
        total_queries = get_status_value(cursor, 'Questions') # Tổng số câu truy vấn đã thực hiện
        slow_queries = get_status_value(cursor, 'Slow_queries') # Số lượng câu truy vấn chậm (slow queries)
        slow_query_ratio = (slow_queries / total_queries * 100) if total_queries > 0 else 0
        print(f"Tổng số truy vấn: {total_queries:,}")
        print(f"Truy vấn chậm (Slow Queries): {slow_queries:,} (Tỷ lệ: {slow_query_ratio:.2f}%)")
        
        # 3. Kích thước các bảng (Table sizes)
        print("\n[Kích Thước Bảng (Top 10 lớn nhất)]")
        print("-" * 60)
        # Truy vấn thông tin dung lượng bảng từ information_schema
        cursor.execute("""
            SELECT 
                table_name,
                ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)',
                ROUND((data_length / 1024 / 1024), 2) AS 'Data (MB)',
                ROUND((index_length / 1024 / 1024), 2) AS 'Index (MB)',
                table_rows
            FROM information_schema.TABLES
            WHERE table_schema = 'loan_management'
            ORDER BY (data_length + index_length) DESC
            LIMIT 10
        """)
        table_sizes = cursor.fetchall()
        
        if table_sizes:
            print(f"{'Bảng':<30} {'Tổng (MB)':<12} {'Dữ liệu (MB)':<12} {'Chỉ mục (MB)':<12} {'Số dòng':<15}")
            print("-" * 60)
            for table, total_size, data_size, index_size, rows in table_sizes:
                print(f"{table:<30} {total_size:<12} {data_size:<12} {index_size:<12} {rows:<15,}")
        else:
            print("Không tìm thấy bảng nào.")
        
        # 4. Sử dụng chỉ mục (Index usage)
        print("\n[Thông Tin Các Chỉ Mục (Indexes)]")
        print("-" * 60)
        # Truy vấn danh sách các index trong database
        cursor.execute("""
            SELECT 
                table_name,
                index_name,
                seq_in_index,
                column_name,
                cardinality
            FROM information_schema.STATISTICS
            WHERE table_schema = 'loan_management'
            ORDER BY table_name, index_name, seq_in_index
            LIMIT 20
        """)
        indexes = cursor.fetchall()
        
        if indexes:
            print(f"{'Bảng':<25} {'Chỉ Mục (Index)':<25} {'Cột':<20} {'Độ phân tán (Cardinality)':<15}")
            print("-" * 60)
            for table, index, seq, column, cardinality in indexes:
                print(f"{table:<25} {index:<25} {column:<20} {cardinality:<15,}")
        else:
            print("Không tìm thấy chỉ mục nào.")
        
        # 5. Các chỉ số về hiệu suất InnoDB (Performance metrics)
        print("\n[Chỉ Số Hiệu Suất (InnoDB Buffer Pool)]")
        print("-" * 60)
        innodb_buffer_pool_size = get_variable_value(cursor, 'innodb_buffer_pool_size')
        innodb_buffer_pool_reads = get_status_value(cursor, 'Innodb_buffer_pool_reads')
        innodb_buffer_pool_read_requests = get_status_value(cursor, 'Innodb_buffer_pool_read_requests')
        
        if innodb_buffer_pool_size:
            buffer_pool_size_mb = int(innodb_buffer_pool_size) / 1024 / 1024
            print(f"Kích thước bộ đệm InnoDB (Buffer Pool Size): {buffer_pool_size_mb:.0f} MB")
        
        # Tính tỷ lệ hit ratio - tỷ lệ dữ liệu được đọc trực tiếp từ RAM thay vì ổ cứng
        if innodb_buffer_pool_read_requests > 0:
            hit_ratio = (1 - (innodb_buffer_pool_reads / innodb_buffer_pool_read_requests)) * 100
            print(f"Tỷ lệ Cache Hit của Buffer Pool: {hit_ratio:.2f}%")
            if hit_ratio < 95:
                print("  ⚠ CẢNH BÁO: Tỷ lệ hit ratio thấp - nên cân nhắc tăng dung lượng buffer pool (innodb_buffer_pool_size)")
        
        # 6. Đánh giá trạng thái tổng thể (Health status)
        print("\n[Đánh Giá Trạng Thái Tổng Thể]")
        print("-" * 60)
        issues = []
        
        if connection_usage > 80:
            issues.append("Mức sử dụng kết nối đang ở mức cao (>80%).")
        
        if slow_query_ratio > 1:
            issues.append("Tỷ lệ truy vấn chậm khá cao (>1%).")
        
        if innodb_buffer_pool_read_requests > 0:
            hit_ratio = (1 - (innodb_buffer_pool_reads / innodb_buffer_pool_read_requests)) * 100
            if hit_ratio < 95:
                issues.append("Tỷ lệ cache hit bộ đệm InnoDB thấp (<95%).")
        
        if issues:
            print("⚠ PHÁT HIỆN CÁC VẤN ĐỀ SAU:")
            for issue in issues:
                print(f"  - {issue}")
        else:
            print("✓ Hệ thống ổn định. Tất cả các chỉ số đều trong mức cho phép.")
        
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 60)
        
    except mysql.connector.Error as e:
        print(f"Lỗi cơ sở dữ liệu: {e}")
        sys.exit(1)

if __name__ == '__main__':
    monitor_database()
