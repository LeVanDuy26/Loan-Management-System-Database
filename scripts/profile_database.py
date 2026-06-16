#!/usr/bin/env python3
"""
Script Đo Lường Hiệu Suất Cơ Sở Dữ Liệu
Đo lường thời gian chạy của các truy vấn (queries) quan trọng 
và cung cấp các chỉ số hiệu suất chi tiết.
"""

import mysql.connector
import time
import sys

# Cấu hình kết nối cơ sở dữ liệu - CẦN CẬP NHẬT CÁC GIÁ TRỊ NÀY CHO PHÙ HỢP
config = {
    'user': 'root',
    'password': '26052004',  # CẬP NHẬT MẬT KHẨU TẠI ĐÂY
    'host': 'localhost',
    'database': 'loan_management',
    'use_pure': True
} 

def explain_query(query, name):
    """Hàm phân tích câu truy vấn (sử dụng lệnh EXPLAIN của MySQL)"""
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        
        # Chạy EXPLAIN để xem kế hoạch thực thi (execution plan)
        cursor.execute(f"EXPLAIN {query}")
        results = cursor.fetchall()
        
        print(f"\n{name} - Bảng phân tích EXPLAIN:")
        print("-" * 60)
        if results:
            # In ra tiêu đề các cột
            columns = [desc[0] for desc in cursor.description]
            print("  " + " | ".join(columns))
            print("  " + "-" * 60)
            # In ra các dòng dữ liệu giải thích
            for row in results:
                print("  " + " | ".join(str(val) for val in row))
        else:
            print("  Không có thông tin kế hoạch thực thi.")
        
        cursor.close()
        conn.close()
    except mysql.connector.Error as e:
        print(f"  Lỗi cơ sở dữ liệu: {e}")

def profile_query(query, name, iterations=10):
    """Hàm đo lường thời gian chạy thực tế của truy vấn (lặp lại nhiều lần)"""
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        
        times = []
        row_counts = []
        
        # Thực thi truy vấn nhiều lần (iterations) để lấy kết quả trung bình chính xác
        for i in range(iterations):
            start = time.time()
            cursor.execute(query)
            results = cursor.fetchall()
            elapsed = (time.time() - start) * 1000  # Chuyển đổi sang milliseconds (ms)
            times.append(elapsed)
            row_counts.append(len(results))
        
        cursor.close()
        conn.close()
        
        # Tính toán các chỉ số thống kê
        avg_time = sum(times) / len(times)
        min_time = min(times)
        max_time = max(times)
        avg_rows = sum(row_counts) / len(row_counts)
        
        print(f"\n{name} - Kết quả Đo lường Hiệu suất:")
        print("-" * 60)
        print(f"  Thời gian trung bình: {avg_time:.2f} ms")
        print(f"  Thời gian nhanh nhất: {min_time:.2f} ms")
        print(f"  Thời gian chậm nhất: {max_time:.2f} ms")
        print(f"  Số dòng trả về TB: {avg_rows:.0f}")
        print(f"  Số lần chạy thử: {iterations}")
        
        # Đánh giá hiệu suất truy vấn
        if avg_time < 100:
            status = "✓ XUẤT SẮC (EXCELLENT)"
        elif avg_time < 500:
            status = "✓ TỐT (GOOD)"
        elif avg_time < 2000:
            status = "⚠ CHẤP NHẬN ĐƯỢC (ACCEPTABLE)"
        else:
            status = "✗ CẦN TỐI ƯU HÓA (NEEDS OPTIMIZATION)"
        
        print(f"  Đánh giá: {status}")
        
        return {
            'name': name,
            'avg_time': avg_time,
            'min_time': min_time,
            'max_time': max_time,
            'avg_rows': avg_rows,
            'iterations': iterations,
            'status': status
        }
    except mysql.connector.Error as e:
        print(f"  Lỗi cơ sở dữ liệu: {e}")
        return None

# Danh sách các câu truy vấn quan trọng cần kiểm tra hiệu suất
queries = [
    (
        """
        SELECT 
            ps.schedule_id,
            ps.contract_id,
            ps.due_date,
            ps.outstanding_amount,
            c.contract_number,
            cu.full_name
        FROM payment_schedules ps
        INNER JOIN loan_contracts c ON ps.contract_id = c.contract_id
        INNER JOIN loan_applications la ON c.application_id = la.application_id
        INNER JOIN customers cu ON la.customer_id = cu.customer_id
        WHERE ps.due_date < CURDATE() 
          AND ps.status = 'pending' 
          AND ps.outstanding_amount > 0
        ORDER BY ps.due_date ASC
        LIMIT 100
        """,
        "Truy vấn Lịch trả nợ quá hạn (QUAN TRỌNG NHẤT)"
    ),
    (
        """
        SELECT 
            la.application_id,
            la.application_number,
            la.loan_amount,
            la.status,
            la.submitted_at,
            cs.score,
            cs.rating
        FROM loan_applications la
        LEFT JOIN credit_scores cs ON la.application_id = cs.application_id
        WHERE la.customer_id = 1
        ORDER BY la.submitted_at DESC
        """,
        "Truy vấn Hồ sơ Đơn xin vay của Khách hàng"
    ),
    (
        """
        SELECT 
            c.contract_id,
            c.contract_number,
            c.principal_amount,
            c.status,
            COUNT(ps.schedule_id) as total_installments,
            SUM(ps.outstanding_amount) as total_outstanding
        FROM loan_contracts c
        LEFT JOIN payment_schedules ps ON c.contract_id = ps.contract_id
        WHERE c.status = 'active'
          AND c.disbursement_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
        GROUP BY c.contract_id
        LIMIT 100
        """,
        "Truy vấn Hợp đồng đang hoạt động trong vòng 1 năm"
    ),
    (
        """
        SELECT * FROM customers 
        WHERE phone = '0912345678'
        """,
        "Truy vấn Tìm khách hàng theo số điện thoại"
    ),
    (
        """
        SELECT * FROM loan_applications 
        WHERE status = 'pending' 
        ORDER BY submitted_at ASC
        LIMIT 50
        """,
        "Truy vấn Đơn xin vay đang chờ xử lý"
    )
]

if __name__ == '__main__':
    print("=" * 60)
    print("Công Cụ Đo Lường Hiệu Suất Cơ Sở Dữ Liệu")
    print("=" * 60)
    
    results = []
    # Lặp qua từng câu truy vấn và thực hiện đo lường
    for query, name in queries:
        explain_query(query, name)
        result = profile_query(query, name, iterations=10)
        if result:
            results.append(result)
    
    # In ra báo cáo tóm tắt
    print("\n" + "=" * 60)
    print("Báo Cáo Tóm Tắt:")
    print("=" * 60)
    for result in results:
        print(f"{result['name']}")
        print(f"  Thời gian TB: {result['avg_time']:.2f} ms - {result['status']}")
    
    print("\n" + "=" * 60)
    print("Tiêu Chuẩn Đánh Giá Hiệu Suất:")
    print("  ✓ XUẤT SẮC: < 100 ms (Tuyệt vời)")
    print("  ✓ TỐT: < 500 ms (Phù hợp cho hầu hết truy vấn)")
    print("  ⚠ CHẤP NHẬN ĐƯỢC: < 2000 ms (Nên tối ưu nếu dùng thường xuyên)")
    print("  ✗ CẦN TỐI ƯU HÓA: >= 2000 ms (Quá chậm, bắt buộc phải index hoặc tối ưu câu lệnh)")
    print("=" * 60)
