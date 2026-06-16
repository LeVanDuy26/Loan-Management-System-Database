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

def generate_disbursements():
    """Hàm tạo dữ liệu giải ngân cho các hợp đồng vay"""
    print("Đang tạo dữ liệu giải ngân...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy thông tin hợp đồng vay
    cursor.execute("""
        SELECT contract_id, principal_amount, disbursement_date
        FROM loan_contracts
    """)
    contracts = cursor.fetchall()
    
    values = []
    for idx, (contract_id, principal_amount_raw, disbursement_date) in enumerate(contracts):
        principal_amount = float(principal_amount_raw)
        
        # Mỗi hợp đồng có 1-3 lần giải ngân (giải ngân theo đợt)
        num_disbursements = random.choices([1, 2, 3], weights=[0.60, 0.30, 0.10])[0]
        
        # Chia số tiền gốc cho các lần giải ngân
        remaining = principal_amount
        for d in range(num_disbursements):
            if d == num_disbursements - 1:
                # Lần cuối: giải ngân hết số tiền còn lại
                amount = round(remaining, 2)
            else:
                # Các lần trước: giải ngân 30-60% số tiền còn lại
                amount = round(remaining * random.uniform(0.3, 0.6), 2)
                remaining -= amount
            
            # Ngày giải ngân: cùng ngày hoặc sau vài ngày so với ngày giải ngân hợp đồng
            disb_date = disbursement_date + timedelta(days=d * random.randint(7, 30))
            
            # Đảm bảo ngày giải ngân không ở tương lai (trigger trong DB sẽ chặn)
            today = datetime.now().date()
            if disb_date > today:
                disb_date = today
                
            # Sinh mã giải ngân duy nhất
            disbursement_number = f"DISB-{disb_date.strftime('%Y%m%d')}-{str(idx * 3 + d + 1).zfill(6)}"
            
            # Phân bố trạng thái: 90% completed, 5% pending, 3% failed, 2% cancelled
            status = random.choices(
                ['completed', 'pending', 'failed', 'cancelled'],
                weights=[0.90, 0.05, 0.03, 0.02]
            )[0]
            
            # Phương thức giải ngân
            method = random.choices(
                ['bank_transfer', 'cash', 'check', 'other'],
                weights=[0.70, 0.15, 0.10, 0.05]
            )[0]
            
            # Số tài khoản ngân hàng ngẫu nhiên
            bank_account = fake.bban()
            # Mã giao dịch tham chiếu
            transaction_ref = f"TXN{fake.unique.random_number(digits=10)}"
            
            completed_at = None
            if status == 'completed':
                completed_at = datetime.combine(disb_date, datetime.min.time()) + timedelta(hours=random.randint(8, 17))
            
            values.append((
                contract_id, disbursement_number, amount, disb_date,
                method, bank_account, transaction_ref, status, completed_at
            ))
    
    # Reset unique tracker của Faker để tránh lỗi khi chạy lại
    fake.unique.clear()
    
    query = """
    INSERT INTO disbursements (
        contract_id, disbursement_number, amount, disbursement_date,
        disbursement_method, bank_account, transaction_reference, status, completed_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "giao dịch giải ngân")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(values)} giao dịch giải ngân")


def generate_collaterals():
    """
    Hàm tạo dữ liệu tài sản thế chấp / tài sản đảm bảo.
    ⭐ ĐÂY LÀ BẢNG TRỌNG TÂM CỦA KHÓA LUẬN.
    """
    print("Đang tạo dữ liệu tài sản thế chấp (TRỌNG TÂM)...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy thông tin hợp đồng
    cursor.execute("""
        SELECT contract_id, principal_amount
        FROM loan_contracts
    """)
    contracts = cursor.fetchall()
    
    # Danh sách mô tả tài sản bất động sản chi tiết (tiếng Việt)
    real_estate_descriptions = [
        'Căn hộ chung cư cao cấp, 2 phòng ngủ, 1 phòng khách, diện tích 75m2',
        'Nhà phố 3 tầng, diện tích đất 60m2, diện tích sàn 180m2',
        'Biệt thự liền kề, diện tích 120m2, 4 phòng ngủ, sân vườn',
        'Đất nền thổ cư, diện tích 100m2, mặt tiền 5m',
        'Căn hộ Studio, diện tích 35m2, full nội thất',
        'Nhà cấp 4, diện tích 80m2, sổ hồng riêng',
        'Căn hộ Penthouse tầng 20, diện tích 150m2, view sông',
        'Đất vườn chuyển đổi, diện tích 200m2, đường xe hơi',
        'Nhà mặt phố kinh doanh, diện tích 45m2, 2 tầng',
        'Căn hộ Duplex, diện tích 100m2, 3 phòng ngủ',
    ]
    
    vehicle_descriptions = [
        'Xe ô tô Toyota Camry 2.5Q, đời 2023, màu đen',
        'Xe ô tô Honda CR-V 1.5L Turbo, đời 2024, màu trắng',
        'Xe ô tô VinFast VF8, đời 2024, màu xanh',
        'Xe ô tô Mercedes-Benz C200, đời 2022, màu bạc',
        'Xe ô tô Hyundai Accent 1.4AT, đời 2023, màu đỏ',
        'Xe ô tô Mazda CX-5 2.0 Premium, đời 2024, màu xám',
        'Xe ô tô KIA Seltos 1.4 Turbo, đời 2023, màu cam',
        'Xe tải Hyundai Porter H150, đời 2022, tải trọng 1.5 tấn',
        'Xe ô tô Ford Ranger Wildtrak, đời 2024, màu xanh dương',
        'Xe máy Honda SH350i, đời 2024, màu đen nhám',
    ]
    
    deposit_descriptions = [
        'Sổ tiết kiệm kỳ hạn 12 tháng tại Vietcombank',
        'Sổ tiết kiệm kỳ hạn 6 tháng tại BIDV',
        'Sổ tiết kiệm kỳ hạn 24 tháng tại Agribank',
        'Chứng chỉ tiền gửi kỳ hạn 36 tháng tại Techcombank',
        'Sổ tiết kiệm không kỳ hạn tại VPBank',
    ]
    
    other_descriptions = [
        'Máy móc thiết bị sản xuất - dây chuyền đóng gói tự động',
        'Vàng miếng SJC 10 lượng, có hóa đơn mua hàng',
        'Cổ phiếu VNM (Vinamilk), số lượng 5000 cổ phiếu',
        'Hàng hóa tồn kho - linh kiện điện tử, trị giá theo kiểm kê',
        'Quyền sử dụng thương hiệu và bằng sáng chế',
    ]
    
    # Danh sách các quận/huyện ở VN cho vị trí
    locations = [
        'Quận 1, TP. Hồ Chí Minh', 'Quận 7, TP. Hồ Chí Minh',
        'Quận Bình Thạnh, TP. Hồ Chí Minh', 'Quận Tân Bình, TP. Hồ Chí Minh',
        'Quận Cầu Giấy, Hà Nội', 'Quận Hoàn Kiếm, Hà Nội',
        'Quận Đống Đa, Hà Nội', 'Quận Nam Từ Liêm, Hà Nội',
        'Quận Hải Châu, Đà Nẵng', 'Quận Thanh Khê, Đà Nẵng',
        'TP. Biên Hòa, Đồng Nai', 'TP. Thủ Dầu Một, Bình Dương',
        'TP. Nha Trang, Khánh Hòa', 'TP. Huế, Thừa Thiên Huế',
        'TP. Cần Thơ', 'TP. Hải Phòng',
    ]
    
    values = []
    for contract_id, principal_amount_raw in contracts:
        principal_amount = float(principal_amount_raw)
        
        # Mỗi hợp đồng có 1-3 tài sản thế chấp
        num_collaterals = random.choices([1, 2, 3], weights=[0.55, 0.35, 0.10])[0]
        
        for c in range(num_collaterals):
            # Chọn loại tài sản theo phân bố: 40% BĐS, 30% xe, 15% tiền gửi, 15% khác
            collateral_type = random.choices(
                ['real_estate', 'vehicle', 'deposit', 'other'],
                weights=[0.40, 0.30, 0.15, 0.15]
            )[0]
            
            # Mô tả và giá trị dựa trên loại tài sản
            if collateral_type == 'real_estate':
                description = random.choice(real_estate_descriptions)
                estimated_value = round(random.uniform(500000000, 5000000000), 2)  # 500tr - 5 tỷ
                ownership_doc = f"Sổ hồng/Sổ đỏ số {fake.bothify('??######')}"
                location = f"{fake.street_address()}, {random.choice(locations)}"
            elif collateral_type == 'vehicle':
                description = random.choice(vehicle_descriptions)
                estimated_value = round(random.uniform(100000000, 1500000000), 2)  # 100tr - 1.5 tỷ
                ownership_doc = f"Đăng ký xe số {fake.bothify('##?-###.##')}"
                location = f"Đậu tại {random.choice(locations)}"
            elif collateral_type == 'deposit':
                description = random.choice(deposit_descriptions)
                estimated_value = round(random.uniform(50000000, 500000000), 2)  # 50tr - 500tr
                ownership_doc = f"Sổ tiết kiệm số {fake.bothify('STK########')}"
                location = None
            else:  # other
                description = random.choice(other_descriptions)
                estimated_value = round(random.uniform(50000000, 1000000000), 2)  # 50tr - 1 tỷ
                ownership_doc = f"Giấy tờ sở hữu số {fake.bothify('GT######')}"
                location = random.choice(locations) if random.random() > 0.3 else None
            
            # Giá trị thẩm định thường thấp hơn 10-30% so với giá trị ước tính
            appraised_value = round(estimated_value * random.uniform(0.70, 0.95), 2)
            
            # Phân bố trạng thái: 85% active, 10% released, 5% seized
            status = random.choices(
                ['active', 'released', 'seized'],
                weights=[0.85, 0.10, 0.05]
            )[0]
            
            released_at = None
            if status == 'released':
                released_at = fake.date_time_between(start_date='-6m', end_date='now')
            
            values.append((
                contract_id, collateral_type, description,
                estimated_value, appraised_value, ownership_doc,
                location, status, released_at
            ))
    
    query = """
    INSERT INTO collaterals (
        contract_id, collateral_type, description,
        estimated_value, appraised_value, ownership_document,
        location, status, released_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "tài sản thế chấp")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(values)} tài sản thế chấp")


def generate_guarantors():
    """Hàm tạo dữ liệu người bảo lãnh"""
    print("Đang tạo dữ liệu người bảo lãnh...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy thông tin hợp đồng
    cursor.execute("""
        SELECT contract_id, principal_amount
        FROM loan_contracts
    """)
    contracts = cursor.fetchall()
    
    # Danh sách mối quan hệ với khách hàng vay
    relationships = [
        'Bố', 'Mẹ', 'Vợ', 'Chồng', 'Anh trai', 'Chị gái', 'Em trai', 'Em gái',
        'Bạn thân', 'Đồng nghiệp', 'Đối tác kinh doanh', 'Người thân khác'
    ]
    
    values = []
    for contract_id, principal_amount_raw in contracts:
        principal_amount = float(principal_amount_raw)
        
        # Khoảng 50% hợp đồng có người bảo lãnh
        if random.random() > 0.50:
            continue
        
        # Mỗi hợp đồng có 1-2 người bảo lãnh
        num_guarantors = random.choices([1, 2], weights=[0.70, 0.30])[0]
        
        for g in range(num_guarantors):
            full_name = fake.name()
            id_number = fake.ssn().replace('-', '')
            phone = fake.phone_number()
            email = fake.email() if random.random() > 0.3 else None
            address = fake.address() if random.random() > 0.2 else None
            relationship = random.choice(relationships)
            
            # Số tiền bảo lãnh: 30-100% số tiền gốc hợp đồng (chia theo số người)
            guarantee_amount = round(
                principal_amount * random.uniform(0.3, 1.0) / num_guarantors, 2
            )
            
            # Phân bố trạng thái: 90% active, 10% released
            status = random.choices(['active', 'released'], weights=[0.90, 0.10])[0]
            
            values.append((
                contract_id, full_name, id_number, phone, email,
                address, relationship, guarantee_amount, status
            ))
    
    query = """
    INSERT INTO guarantors (
        contract_id, full_name, id_number, phone, email,
        address, relationship_with_customer, guarantee_amount, status
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "người bảo lãnh")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(values)} người bảo lãnh")


def generate_approval_workflows():
    """Hàm tạo dữ liệu quy trình phê duyệt đa cấp"""
    print("Đang tạo quy trình phê duyệt...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy các đơn vay đã duyệt hoặc bị từ chối (pending/cancelled không cần workflow hoàn chỉnh)
    cursor.execute("""
        SELECT application_id, loan_amount, status, submitted_at
        FROM loan_applications
        WHERE status IN ('approved', 'rejected')
    """)
    applications = cursor.fetchall()
    
    # Danh sách tên người phê duyệt giả lập
    level1_names = ['Nguyễn Văn Hùng', 'Trần Thị Mai', 'Lê Minh Tuấn', 'Phạm Thu Hà', 'Hoàng Đức Anh']
    level2_names = ['Nguyễn Thị Lan', 'Trần Quốc Bảo', 'Vũ Đình Khôi', 'Đỗ Thị Hương']
    level3_names = ['Nguyễn Đức Thắng', 'Phạm Minh Châu', 'Lê Hoàng Nam']
    
    values = []
    for application_id, loan_amount_raw, app_status, submitted_at in applications:
        loan_amount = float(loan_amount_raw)
        
        # Level 1: Chuyên viên tín dụng (tất cả đơn)
        approver_name = random.choice(level1_names)
        approver_id = f"CV{random.randint(100, 999)}"
        action_date = submitted_at + timedelta(hours=random.randint(4, 48))
        
        if app_status == 'rejected' and random.random() < 0.4:
            # 40% đơn bị từ chối ngay ở Level 1
            action = 'reject'
            wf_status = 'rejected'
        else:
            action = 'approve'
            wf_status = 'approved'
        
        comments = random.choice([
            'Hồ sơ đầy đủ, đáp ứng điều kiện cơ bản',
            'Khách hàng có thu nhập ổn định',
            'Đã xác minh thông tin cá nhân',
            'Cần xem xét thêm tại cấp cao hơn',
            'Hồ sơ không đạt yêu cầu tín dụng',
            'Điểm tín dụng thấp, rủi ro cao',
        ])
        
        values.append((
            application_id, 1, approver_id, approver_name,
            action, comments, action_date, wf_status
        ))
        
        # Level 2: Trưởng nhóm (khoản vay > 100 triệu)
        if loan_amount > 100000000 and action == 'approve':
            approver_name = random.choice(level2_names)
            approver_id = f"TN{random.randint(100, 999)}"
            action_date = action_date + timedelta(hours=random.randint(2, 24))
            
            if app_status == 'rejected' and random.random() < 0.6:
                action = 'reject'
                wf_status = 'rejected'
            else:
                action = 'approve'
                wf_status = 'approved'
            
            comments = random.choice([
                'Đã xem xét kỹ hồ sơ, đồng ý phê duyệt',
                'Tài sản đảm bảo đủ giá trị',
                'Yêu cầu bổ sung giấy tờ sao kê ngân hàng',
                'Từ chối do tỷ lệ nợ/thu nhập quá cao',
            ])
            
            values.append((
                application_id, 2, approver_id, approver_name,
                action, comments, action_date, wf_status
            ))
            
            # Level 3: Giám đốc (khoản vay > 300 triệu)
            if loan_amount > 300000000 and action == 'approve':
                approver_name = random.choice(level3_names)
                approver_id = f"GD{random.randint(100, 999)}"
                action_date = action_date + timedelta(hours=random.randint(4, 48))
                
                if app_status == 'rejected':
                    action = 'reject'
                    wf_status = 'rejected'
                else:
                    action = 'approve'
                    wf_status = 'approved'
                
                comments = random.choice([
                    'Phê duyệt. Khoản vay nằm trong hạn mức chi nhánh.',
                    'Đã xem xét toàn bộ hồ sơ và phê duyệt',
                    'Từ chối. Hạn mức tín dụng chi nhánh đã đầy.',
                ])
                
                values.append((
                    application_id, 3, approver_id, approver_name,
                    action, comments, action_date, wf_status
                ))
    
    query = """
    INSERT INTO approval_workflows (
        application_id, approver_level, approver_id, approver_name,
        action, comments, action_date, status
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "bước phê duyệt")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(values)} bước phê duyệt")


def generate_interest_rate_schedules():
    """Hàm tạo lịch lãi suất cho các hợp đồng vay"""
    print("Đang tạo lịch lãi suất...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy thông tin hợp đồng
    cursor.execute("""
        SELECT contract_id, interest_rate, disbursement_date
        FROM loan_contracts
    """)
    contracts = cursor.fetchall()
    
    values = []
    for contract_id, interest_rate_raw, disbursement_date in contracts:
        interest_rate = float(interest_rate_raw)
        
        # 70% lãi suất cố định, 30% thả nổi
        rate_type = random.choices(['fixed', 'floating'], weights=[0.70, 0.30])[0]
        
        if rate_type == 'fixed':
            # Lãi suất cố định: rate lấy từ hợp đồng, không cần base_rate/spread
            values.append((
                contract_id, disbursement_date, interest_rate, 'fixed',
                None, None, 'reducing_balance', 'active'
            ))
        else:
            # Lãi suất thả nổi: rate = base_rate + spread
            base_rate = round(random.uniform(4.0, 8.0), 2)
            spread = round(interest_rate - base_rate, 2)
            # Đảm bảo spread hợp lệ (-100 đến 100)
            if spread < -100:
                spread = round(random.uniform(1.0, 4.0), 2)
            
            # 30% hợp đồng thả nổi có thay đổi lãi suất (thêm 1 bản ghi expired)
            if random.random() < 0.30:
                # Lãi suất cũ (expired) có hiệu lực từ ngày giải ngân
                old_rate = round(interest_rate + random.uniform(-2.0, 2.0), 2)
                old_rate = max(0.01, min(old_rate, 99.99))  # Đảm bảo 0-100
                old_base = round(base_rate + random.uniform(-1.0, 1.0), 2)
                old_base = max(0.01, min(old_base, 99.99))
                old_spread = round(old_rate - old_base, 2)
                old_spread = max(-99.99, min(old_spread, 99.99))
                old_date = disbursement_date
                
                values.append((
                    contract_id, old_date, old_rate, 'floating',
                    old_base, old_spread, 'reducing_balance', 'expired'
                ))
                
                # Lãi suất mới (active) có hiệu lực sau đó 1-6 tháng
                new_date = disbursement_date + timedelta(days=random.randint(30, 180))
                today = datetime.now().date()
                if new_date > today:
                    new_date = today
                
                values.append((
                    contract_id, new_date, interest_rate, 'floating',
                    base_rate, spread, 'reducing_balance', 'active'
                ))
            else:
                # Không thay đổi, lãi suất active từ đầu
                values.append((
                    contract_id, disbursement_date, interest_rate, 'floating',
                    base_rate, spread, 'reducing_balance', 'active'
                ))
    
    query = """
    INSERT INTO interest_rate_schedules (
        contract_id, effective_date, rate, rate_type,
        base_rate, spread, calculation_method, status
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    # DROP trigger tạm thời để tránh lỗi 1442 (Mutating Table) của MySQL
    cursor.execute("DROP TRIGGER IF EXISTS trg_prevent_overlapping_interest_rates;")
    
    insert_in_chunks(cursor, conn, query, values, "lịch lãi suất")
    
    # Tạo lại trigger sau khi insert xong
    recreate_trigger = """
    CREATE TRIGGER trg_prevent_overlapping_interest_rates
    BEFORE INSERT ON interest_rate_schedules
    FOR EACH ROW
    BEGIN
        IF NEW.status = 'active' THEN
            UPDATE interest_rate_schedules
            SET status = 'expired'
            WHERE contract_id = NEW.contract_id
              AND status = 'active';
        END IF;
    END
    """
    cursor.execute(recreate_trigger)
    
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(values)} lịch lãi suất")


def generate_repayments():
    """Hàm tạo dữ liệu giao dịch trả nợ (dựa trên payment_schedules đã paid)"""
    print("Đang tạo giao dịch trả nợ...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy các kỳ trả nợ đã thanh toán (paid) hoặc quá hạn (overdue)
    cursor.execute("""
        SELECT ps.contract_id, ps.due_date, ps.principal_due, ps.interest_due,
               ps.total_due, ps.status, ps.paid_at
        FROM payment_schedules ps
        WHERE ps.status IN ('paid', 'overdue')
    """)
    schedules = cursor.fetchall()
    
    values = []
    for contract_id, due_date, principal_due_raw, interest_due_raw, \
        total_due_raw, ps_status, paid_at in schedules:
        
        principal_due = float(principal_due_raw)
        interest_due = float(interest_due_raw)
        total_due = float(total_due_raw)
        
        if ps_status == 'paid':
            # Kỳ đã thanh toán → tạo 1 bản ghi repayment
            penalty = 0.0
            # Nếu paid_at > due_date vài ngày → có phạt trả trễ
            if paid_at and hasattr(paid_at, 'date'):
                actual_date = paid_at.date() if hasattr(paid_at, 'date') else paid_at
            else:
                actual_date = due_date + timedelta(days=random.randint(0, 3))
            
            if actual_date > due_date:
                days_late = (actual_date - due_date).days
                # Phạt 0.05%/ngày trên tổng nợ
                penalty = round(total_due * 0.0005 * days_late, 2)
            
            total_amount = round(principal_due + interest_due + penalty, 2)
            
            # Phương thức thanh toán
            payment_method = random.choices(
                ['bank_transfer', 'online', 'cash', 'check', 'other'],
                weights=[0.40, 0.30, 0.15, 0.10, 0.05]
            )[0]
            
            transaction_ref = f"PAY{random.randint(1000000000, 9999999999)}"
            
            values.append((
                contract_id, due_date, actual_date,
                round(principal_due, 2), round(interest_due, 2), round(penalty, 2),
                total_amount, payment_method, transaction_ref, 'paid', paid_at
            ))
        
        elif ps_status == 'overdue':
            # Kỳ quá hạn → 60% chưa trả, 40% đã trả trễ
            if random.random() < 0.40:
                # Đã trả trễ
                days_late = random.randint(10, 90)
                actual_date = due_date + timedelta(days=days_late)
                penalty = round(total_due * 0.0005 * days_late, 2)
                total_amount = round(principal_due + interest_due + penalty, 2)
                
                payment_method = random.choices(
                    ['bank_transfer', 'online', 'cash', 'check', 'other'],
                    weights=[0.40, 0.30, 0.15, 0.10, 0.05]
                )[0]
                transaction_ref = f"PAY{random.randint(1000000000, 9999999999)}"
                
                values.append((
                    contract_id, due_date, actual_date,
                    round(principal_due, 2), round(interest_due, 2), round(penalty, 2),
                    total_amount, payment_method, transaction_ref, 'paid',
                    datetime.combine(actual_date, datetime.min.time()) + timedelta(hours=random.randint(8, 17))
                ))
            else:
                # Chưa trả → ghi nhận là overdue
                penalty = round(total_due * 0.0005 * random.randint(30, 180), 2)
                total_amount = round(principal_due + interest_due + penalty, 2)
                
                values.append((
                    contract_id, due_date, None,
                    round(principal_due, 2), round(interest_due, 2), round(penalty, 2),
                    total_amount, 'bank_transfer', None, 'overdue', None
                ))
    
    query = """
    INSERT INTO repayments (
        contract_id, scheduled_date, actual_payment_date,
        principal_amount, interest_amount, penalty_amount,
        total_amount, payment_method, transaction_reference, status, paid_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "giao dịch trả nợ")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(values)} giao dịch trả nợ")


def generate_collections():
    """Hàm tạo dữ liệu hoạt động thu hồi nợ"""
    print("Đang tạo hoạt động thu hồi nợ...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Lấy các hợp đồng bị vỡ nợ (defaulted) hoặc có kỳ quá hạn
    cursor.execute("""
        SELECT DISTINCT lc.contract_id
        FROM loan_contracts lc
        WHERE lc.status = 'defaulted'
        UNION
        SELECT DISTINCT ps.contract_id
        FROM payment_schedules ps
        WHERE ps.status = 'overdue'
    """)
    contract_ids = [row[0] for row in cursor.fetchall()]
    
    # Lấy thông tin chi tiết các kỳ quá hạn
    if not contract_ids:
        print("✓ Không có hợp đồng nợ xấu nào cần thu hồi")
        cursor.close()
        conn.close()
        return
    
    # Danh sách nhân viên thu hồi nợ
    collectors = [
        'Nguyễn Thanh Tùng', 'Trần Văn Đức', 'Lê Thị Phương',
        'Phạm Hoàng Long', 'Vũ Minh Hải', 'Đặng Thu Thủy',
    ]
    
    # Danh sách ghi chú mẫu cho từng loại
    reminder_notes = [
        'Đã gửi SMS nhắc nhở thanh toán kỳ nợ quá hạn',
        'Gửi email thông báo nợ quá hạn lần 1',
        'Gọi điện nhắc nhở, khách hàng hứa trả trong 1 tuần',
        'Gửi thông báo qua ứng dụng di động',
    ]
    warning_notes = [
        'Gọi điện cảnh cáo lần 2, khách hàng chưa phản hồi',
        'Gửi thư cảnh cáo chính thức có dấu mộc ngân hàng',
        'Khách hàng xin gia hạn thêm 2 tuần',
        'Đã gặp trực tiếp khách hàng tại nhà, cam kết trả nợ',
    ]
    legal_notes = [
        'Đã chuyển hồ sơ cho bộ phận pháp lý xử lý',
        'Khởi kiện ra tòa án nhân dân quận/huyện',
        'Tiến hành thu giữ tài sản thế chấp theo hợp đồng',
        'Phát hành thông báo thanh lý tài sản',
    ]
    settlement_notes = [
        'Đàm phán cơ cấu lại nợ, giảm 20% phí phạt',
        'Khách hàng đồng ý trả góp nợ quá hạn trong 3 tháng',
        'Thương lượng thành công, khách hàng trả 80% nợ gốc',
        'Gia hạn thêm 6 tháng với lãi suất ưu đãi',
    ]
    
    values = []
    for contract_id in contract_ids:
        # Mỗi hợp đồng nợ xấu có 1-5 hoạt động thu hồi (leo thang dần)
        num_actions = random.randint(1, 5)
        
        # Tổng nợ quá hạn ngẫu nhiên
        amount_due = round(random.uniform(5000000, 200000000), 2)
        
        collection_date = fake.date_between(start_date='-1y', end_date='today')
        
        for a in range(num_actions):
            # Chọn loại thu hồi theo thứ tự leo thang
            if a == 0:
                collection_type = 'reminder'
                notes = random.choice(reminder_notes)
                # Thu hồi được 0-30% khi nhắc nhở
                collected = round(amount_due * random.uniform(0, 0.30), 2)
            elif a == 1:
                collection_type = 'warning'
                notes = random.choice(warning_notes)
                collected = round(amount_due * random.uniform(0, 0.20), 2)
            elif a == 2:
                collection_type = random.choice(['warning', 'legal_action'])
                notes = random.choice(warning_notes if collection_type == 'warning' else legal_notes)
                collected = round(amount_due * random.uniform(0, 0.15), 2)
            elif a == 3:
                collection_type = 'legal_action'
                notes = random.choice(legal_notes)
                collected = round(amount_due * random.uniform(0, 0.40), 2)
            else:
                collection_type = 'settlement'
                notes = random.choice(settlement_notes)
                collected = round(amount_due * random.uniform(0.30, 0.80), 2)
            
            # Đảm bảo collected <= amount_due (ràng buộc CHECK)
            collected = min(collected, amount_due)
            
            assigned_to = random.choice(collectors)
            
            # Ngày hành động tiếp theo (7-30 ngày sau)
            next_action_date = collection_date + timedelta(days=random.randint(7, 30))
            
            # Phân bố trạng thái
            if a == num_actions - 1 and random.random() < 0.40:
                status = 'resolved'
                resolved_at = collection_date + timedelta(days=random.randint(1, 14))
            elif a == num_actions - 1 and random.random() < 0.20:
                status = 'closed'
                resolved_at = None
            else:
                status = 'open'
                resolved_at = None
            
            values.append((
                contract_id, collection_type, collection_date,
                amount_due, collected, assigned_to, notes,
                next_action_date, status, resolved_at
            ))
            
            # Ngày của action tiếp theo cách 7-30 ngày
            collection_date = collection_date + timedelta(days=random.randint(7, 30))
    
    query = """
    INSERT INTO collections (
        contract_id, collection_type, collection_date,
        amount_due, amount_collected, assigned_to, notes,
        next_action_date, status, resolved_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    insert_in_chunks(cursor, conn, query, values, "hoạt động thu hồi nợ")
    cursor.close()
    conn.close()
    print(f"✓ Đã tạo thành công {len(values)} hoạt động thu hồi nợ")


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
        # === GIAI ĐOẠN 1: Dữ liệu cốt lõi ===
        generate_customers(customer_count)
        generate_loan_applications(application_count)
        generate_credit_scores()
        generate_loan_contracts()
        generate_payment_schedules()
        
        # === GIAI ĐOẠN 2: Dữ liệu bổ sung (7 bảng mới) ===
        generate_disbursements()
        generate_collaterals()             # ⭐ TRỌNG TÂM KHÓA LUẬN
        generate_guarantors()
        generate_approval_workflows()
        generate_interest_rate_schedules()
        generate_repayments()
        generate_collections()
        
        print("=" * 60)
        print("✓ Quá trình tạo dữ liệu hoàn tất thành công!")
        print("  Đã sinh dữ liệu cho TẤT CẢ 12 bảng trong database.")
        print("=" * 60)
    except mysql.connector.Error as e:
        print(f"✗ Lỗi cơ sở dữ liệu: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    except Exception as e:
        print(f"✗ Lỗi hệ thống: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

