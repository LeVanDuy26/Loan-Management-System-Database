#!/usr/bin/env python3
"""
Script Sinh Dữ Liệu Cho Cơ Sở Dữ Liệu Quản Lý Khoản Vay
Tạo dữ liệu thử nghiệm thực tế sử dụng thư viện Faker để giả lập dữ liệu.
"""

import mysql.connector
from faker import Faker
import random
from datetime import datetime, timedelta
from decimal import Decimal
import json
import sys

# Khởi tạo Faker với ngôn ngữ Tiếng Việt để tạo tên, địa chỉ, số điện thoại chuẩn VN
fake = Faker('vi_VN')

# Cấu hình kết nối cơ sở dữ liệu - CẦN CẬP NHẬT CÁC GIÁ TRỊ NÀY CHO PHÙ HỢP VỚI MÁY CỦA BẠN
config = {
    'user': 'root',
    'password': '26052004',  # CẬP NHẬT MẬT KHẨU
    'host': 'localhost',
    'port': 3306,
    'database': 'loan_management',
    'use_pure': True
}

# Kích thước mỗi khối dữ liệu khi chèn hàng loạt (tránh quá tải bộ nhớ và timeout)
CHUNK_SIZE = 1000


def insert_in_chunks(cursor, conn, query, values, label="bản ghi"):
    """
    Hàm tiện ích: Chèn dữ liệu hàng loạt theo từng khối (chunk).
    Tránh lỗi timeout hoặc tràn bộ nhớ khi INSERT số lượng lớn (hàng chục nghìn dòng).
    
    Tham số:
        cursor: Con trỏ DB đang mở
        conn: Kết nối DB đang mở
        query: Câu lệnh INSERT SQL
        values: Danh sách tuple dữ liệu cần chèn
        label: Nhãn mô tả loại dữ liệu (dùng khi in tiến trình)
    """
    total = len(values)
    for i in range(0, total, CHUNK_SIZE):
        chunk = values[i:i + CHUNK_SIZE]
        cursor.executemany(query, chunk)
        conn.commit()
        done = min(i + CHUNK_SIZE, total)
        print(f"  Đã thêm {done}/{total} {label}...")


def generate_customers(count=1000):
    """Hàm tạo dữ liệu khách hàng mẫu"""
    print(f"Đang tạo {count} khách hàng...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    values = []
    for i in range(count):
        # Sinh mã khách hàng tự động: CUST000001...
        customer_code = f'CUST{str(i+1).zfill(6)}'
        # Sinh tên tiếng Việt ngẫu nhiên
        full_name = fake.name()
        # Sinh số thẻ căn cước (loại bỏ dấu gạch ngang nếu có)
        id_number = fake.ssn().replace('-', '')
        # Sinh số điện thoại
        phone = fake.phone_number()
        # Sinh email ngẫu nhiên
        email = fake.email()
        # Sinh địa chỉ tiếng Việt ngẫu nhiên
        address = fake.address()
        # Sinh ngày sinh, giới hạn độ tuổi từ 18 đến 80
        date_of_birth = fake.date_of_birth(minimum_age=18, maximum_age=80)
        # Random giới tính
        gender = random.choice(['male', 'female', 'other'])
        # Sinh nghề nghiệp ngẫu nhiên
        occupation = fake.job()
        
        # Phân bố trạng thái: 85% active, 10% inactive, 5% blacklisted
        status = random.choices(
            ['active', 'inactive', 'blacklisted'],
            weights=[0.85, 0.10, 0.05]
        )[0]
        
        values.append((
            customer_code, full_name, id_number, phone, email, address,
            date_of_birth, gender, occupation, status
        ))
    
    query = """
    INSERT INTO customers (
        customer_code, full_name, id_number, phone, email, address,
        date_of_birth, gender, occupation, status
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "khách hàng")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {count} khách hàng")

def generate_loan_applications(count=2000):
    """Hàm tạo dữ liệu đơn xin vay"""
    print(f"Đang tạo {count} đơn xin vay...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy danh sách ID của các khách hàng đang ở trạng thái 'active' (để gán cho đơn vay)
    cursor.execute("SELECT customer_id FROM customers WHERE status = 'active'")
    customer_ids = [row[0] for row in cursor.fetchall()]
    
    if not customer_ids:
        print("Lỗi: Không tìm thấy khách hàng nào đang active. Vui lòng tạo dữ liệu khách hàng trước.")
        return
    
    # Danh sách các mục đích vay phổ biến
    purposes = [
        'Mua nhà', 'Mua xe', 'Kinh doanh', 'Giáo dục', 
        'Y tế', 'Du lịch', 'Tiêu dùng', 'Khác'
    ]
    
    values = []
    for i in range(count):
        # Chọn ngẫu nhiên một ID khách hàng
        customer_id = random.choice(customer_ids)
        # Sinh số tiền vay ngẫu nhiên từ 10 triệu đến 500 triệu VNĐ
        loan_amount = random.randint(10000000, 500000000)
        # Chọn kỳ hạn vay ngẫu nhiên (tháng)
        requested_term_months = random.choice([6, 12, 18, 24, 36, 48, 60])
        purpose = random.choice(purposes)
        
        # Phân bố trạng thái: 70% được duyệt (approved), 20% bị từ chối, 10% chờ xử lý hoặc đã hủy
        status = random.choices(
            ['pending', 'approved', 'rejected', 'cancelled'],
            weights=[0.10, 0.70, 0.15, 0.05]
        )[0]
        
        # Sinh ngày nộp đơn ngẫu nhiên trong vòng 2 năm trở lại đây
        submitted_at = fake.date_time_between(start_date='-2y', end_date='now')
        approved_at = None
        rejected_at = None
        
        # Nếu đơn được duyệt, giả lập ngày duyệt là sau 1-7 ngày so với ngày nộp
        if status == 'approved':
            approved_at = submitted_at + timedelta(days=random.randint(1, 7))
        # Nếu bị từ chối, giả lập ngày từ chối là sau 1-5 ngày so với ngày nộp
        elif status == 'rejected':
            rejected_at = submitted_at + timedelta(days=random.randint(1, 5))
        
        # Sinh mã đơn vay dạng APP-YYYYMMDD-NNNNNN
        application_number = f"APP-{submitted_at.strftime('%Y%m%d')}-{str(i+1).zfill(6)}"
        
        values.append((
            customer_id, application_number, loan_amount, requested_term_months, purpose,
            status, submitted_at, approved_at, rejected_at
        ))
    
    query = """
    INSERT INTO loan_applications (
        customer_id, application_number, loan_amount, requested_term_months, purpose,
        status, submitted_at, approved_at, rejected_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "đơn xin vay")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {count} đơn xin vay")

def generate_credit_scores():
    """Hàm tạo điểm tín dụng cho các đơn xin vay"""
    print("Đang tạo điểm tín dụng...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy danh sách các đơn xin vay cùng với customer_id
    cursor.execute("SELECT application_id, customer_id FROM loan_applications")
    applications = cursor.fetchall()
    
    values = []
    for application_id, customer_id in applications:
        # Sinh điểm tín dụng ngẫu nhiên từ 400 đến 950
        score = random.randint(400, 950)
        
        # Xác định mức xếp hạng dựa trên điểm tín dụng
        # Logic này PHẢI KHỚP với ràng buộc CHECK (chk_rating_match_score) trong DB:
        #   excellent: score >= 750
        #   good:      650 <= score < 750
        #   fair:      550 <= score < 650
        #   poor:      score < 550
        if score >= 750:
            rating = 'excellent'
        elif score >= 650:
            rating = 'good'
        elif score >= 550:
            rating = 'fair'
        else:
            rating = 'poor'
        
        # Tạo thông tin các yếu tố ảnh hưởng dạng JSON (thu nhập, số năm làm việc, tỷ lệ nợ...)
        factors = {
            'income': random.randint(5000000, 50000000), # Thu nhập từ 5tr - 50tr
            'employment_years': random.randint(0, 20),
            'debt_ratio': round(random.uniform(0.1, 0.6), 2),
            'credit_history_years': random.randint(0, 15),
            'number_of_loans': random.randint(0, 5)
        }
        
        # Ngày chấm điểm trong 2 năm qua
        score_date = fake.date_between(start_date='-2y', end_date='today')
        
        values.append((
            customer_id, application_id, score, score_date, rating,
            json.dumps(factors, ensure_ascii=False)
        ))
    
    query = """
    INSERT INTO credit_scores (
        customer_id, application_id, score, score_date, rating, factors
    ) VALUES (%s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "điểm tín dụng")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(values)} đánh giá điểm tín dụng")

def generate_loan_contracts():
    """Hàm tạo hợp đồng vay từ các đơn đã được duyệt"""
    print("Đang tạo hợp đồng vay...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Chỉ lấy các đơn xin vay có trạng thái 'approved' (đã duyệt)
    cursor.execute("""
        SELECT application_id, loan_amount, requested_term_months
        FROM loan_applications
        WHERE status = 'approved'
    """)
    applications = cursor.fetchall()
    
    values = []
    for idx, (application_id, loan_amount_raw, requested_term_months) in enumerate(applications):
        # ★ QUAN TRỌNG: Chuyển đổi Decimal → float để tránh lỗi phép toán
        # MySQL connector trả về kiểu decimal.Decimal cho cột DECIMAL(15,2),
        # nhưng Python không cho phép nhân Decimal với float trực tiếp.
        loan_amount = float(loan_amount_raw)
        
        # Số tiền gốc cho vay có thể thấp hơn số tiền đề nghị (từ 90% - 100%)
        principal_amount = round(loan_amount * random.uniform(0.9, 1.0), 2)
        # Sinh lãi suất ngẫu nhiên từ 8.0% đến 18.0%/năm
        interest_rate = round(random.uniform(8.0, 18.0), 2)
        # Lấy kỳ hạn theo số tháng khách hàng yêu cầu
        term_months = int(requested_term_months)
        
        # Ngày giải ngân giả lập trong vòng 1 năm qua
        disbursement_date = fake.date_between(start_date='-1y', end_date='today')
        # Sinh mã hợp đồng dạng CONTRACT-YYYYMMDD-NNNNNN
        contract_number = f"CONTRACT-{disbursement_date.strftime('%Y%m%d')}-{str(idx + 1).zfill(6)}"
        # Ngày thanh toán kỳ đầu tiên (sau 1 tháng)
        first_payment_date = disbursement_date + timedelta(days=30)
        # Tần suất trả nợ
        payment_frequency = random.choice(['monthly', 'quarterly', 'annually'])
        
        # Phân bố trạng thái: 80% hợp đồng đang active, 15% đã đóng (thanh toán xong), 5% bị vỡ nợ
        status = random.choices(
            ['active', 'closed', 'defaulted'],
            weights=[0.80, 0.15, 0.05]
        )[0]
        
        # Ngày ký hợp đồng trước ngày giải ngân vài ngày
        signed_at = disbursement_date - timedelta(days=random.randint(1, 7))
        
        values.append((
            application_id, contract_number, principal_amount, interest_rate, term_months,
            disbursement_date, None, first_payment_date, # maturity_date=None để DB trigger tự tính toán
            payment_frequency, status, signed_at
        ))
    
    query = """
    INSERT INTO loan_contracts (
        application_id, contract_number, principal_amount, interest_rate, term_months,
        disbursement_date, maturity_date, first_payment_date,
        payment_frequency, status, signed_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "hợp đồng vay")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(values)} hợp đồng vay")

def generate_payment_schedules():
    """Hàm tạo lịch trả nợ (các kỳ trả góp) cho các hợp đồng"""
    print("Đang tạo lịch trả nợ...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy thông tin các hợp đồng vay
    cursor.execute("""
        SELECT contract_id, principal_amount, interest_rate, term_months,
               disbursement_date, first_payment_date, payment_frequency
        FROM loan_contracts
    """)
    contracts = cursor.fetchall()
    
    all_values = []
    for contract_id, principal_amount_raw, interest_rate_raw, term_months_raw, \
        disbursement_date, first_payment_date, payment_frequency in contracts:
        
        # ★ QUAN TRỌNG: Chuyển đổi Decimal → float và các kiểu dữ liệu khác
        # để tránh lỗi "unsupported operand type(s) for *: 'decimal.Decimal' and 'float'"
        # khi thực hiện các phép toán lũy thừa (**) trong công thức amortization.
        principal_amount = float(principal_amount_raw)
        interest_rate = float(interest_rate_raw)
        term_months = int(term_months_raw)
        
        # Tính mức lãi suất hàng tháng
        monthly_rate = interest_rate / 100.0 / 12.0
        
        # Tính toán số tiền trả cố định hàng tháng (Sử dụng công thức Amortization - Dư nợ giảm dần đều)
        if monthly_rate > 0:
            monthly_payment = principal_amount * (
                monthly_rate * (1 + monthly_rate) ** term_months
            ) / ((1 + monthly_rate) ** term_months - 1)
        else:
            monthly_payment = principal_amount / term_months
        
        # Số tiền gốc còn lại ban đầu bằng tổng tiền gốc
        remaining_principal = principal_amount
        
        # Lấy ngày hiện tại 1 lần (tránh gọi lặp lại trong vòng lặp)
        today = datetime.now().date()
        
        # Lặp qua từng kỳ trả góp
        for installment in range(1, term_months + 1):
            # Tính toán ngày đến hạn dựa trên tần suất (tháng, quý, năm)
            if payment_frequency == 'monthly':
                due_date = first_payment_date + timedelta(days=30 * (installment - 1))
            elif payment_frequency == 'quarterly':
                due_date = first_payment_date + timedelta(days=90 * (installment - 1))
            else:  # annually
                due_date = first_payment_date + timedelta(days=365 * (installment - 1))
            
            # Tính toán phần tiền lãi và tiền gốc cho kỳ này
            if monthly_rate > 0:
                interest_due = remaining_principal * monthly_rate
                principal_due = monthly_payment - interest_due
            else:
                principal_due = remaining_principal / (term_months - installment + 1)
                interest_due = 0.0
            
            # Giảm trừ phần gốc còn lại cho các kỳ sau (dùng giá trị chưa làm tròn để giữ độ chính xác)
            remaining_principal -= principal_due
            
            # ★ QUAN TRỌNG: Làm tròn principal_due và interest_due TRƯỚC,
            # rồi tính total_due = tổng 2 giá trị đã làm tròn.
            # Điều này đảm bảo ràng buộc CHECK trong DB luôn đúng:
            #   chk_total_due_equals_sum: total_due = principal_due + interest_due
            #   chk_outstanding_equals_due_minus_paid: outstanding_amount = total_due - paid_amount
            principal_due = round(principal_due, 2)
            interest_due = round(interest_due, 2)
            total_due = round(principal_due + interest_due, 2)
            
            # Giả lập trạng thái đã thanh toán dựa trên ngày hiện tại
            if due_date < today:
                # Nếu đã qua ngày đến hạn (quá khứ)
                if random.random() < 0.1:  # 10% khả năng bị quá hạn (overdue) chưa trả
                    status = 'overdue'
                    paid_amount = 0.0
                    paid_at = None
                else: # Đã trả thành công
                    status = 'paid'
                    paid_amount = total_due  # Dùng total_due đã làm tròn
                    # Ngày thanh toán thực tế chênh lệch 0-5 ngày so với ngày đến hạn
                    paid_at = due_date + timedelta(days=random.randint(0, 5))
            else:
                # Nếu kỳ nợ ở tương lai (chưa tới hạn)
                status = 'pending'
                paid_amount = 0.0
                paid_at = None
            
            all_values.append((
                contract_id, installment, due_date,
                principal_due, interest_due, total_due,
                paid_amount, status, paid_at
            ))
    
    # Chèn dữ liệu hàng loạt theo khối (chunk) để tránh quá tải bộ nhớ
    query = """
    INSERT INTO payment_schedules (
        contract_id, installment_number, due_date,
        principal_due, interest_due, total_due,
        paid_amount, status, paid_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, all_values, "kỳ trả nợ")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(all_values)} kỳ trả nợ")

if __name__ == '__main__':
    # Có thể truyền số lượng vào tham số dòng lệnh: python generate_test_data.py <số khách hàng> <số đơn vay>
    if len(sys.argv) > 1:
        customer_count = int(sys.argv[1])
        application_count = int(sys.argv[2]) if len(sys.argv) > 2 else customer_count * 2
    else:
        # Số lượng mặc định
        customer_count = 1000
        application_count = 2000
    
    print("=" * 60)
    print("Cơ Sở Dữ Liệu Quản Lý Khoản Vay - Script Tạo Dữ Liệu Thử Nghiệm")
    print("=" * 60)
    print(f"Cấu hình: {customer_count} khách hàng, {application_count} đơn xin vay")
    print("=" * 60)
    
    try:
        generate_customers(customer_count)
        generate_loan_applications(application_count)
        generate_credit_scores()
        generate_loan_contracts()
        generate_payment_schedules()
        
        print("=" * 60)
        print("✓ Quá trình tạo dữ liệu hoàn tất thành công!")
        print("=" * 60)
    except mysql.connector.Error as e:
        print(f"✗ Lỗi cơ sở dữ liệu: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Lỗi hệ thống: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
