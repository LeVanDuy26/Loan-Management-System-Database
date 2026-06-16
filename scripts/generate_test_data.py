#!/usr/bin/env python3
"""
Data Generation Script for Loan Management Database
Generates realistic test data using Faker library
"""

import mysql.connector
from faker import Faker
import random
from datetime import datetime, timedelta
import json
import sys

# Initialize Faker with Vietnamese locale
fake = Faker('vi_VN')

# Database connection - UPDATE THESE VALUES
config = {
    'user': 'loan_app',
    'password': 'your_password',  # UPDATE THIS
    'host': 'localhost',
    'database': 'loan_management'
}

def generate_customers(count=1000):
    """Generate customers"""
    print(f"Generating {count} customers...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    values = []
    for i in range(count):
        customer_code = f'CUST{str(i+1).zfill(6)}'
        full_name = fake.name()
        id_number = fake.ssn().replace('-', '')
        phone = fake.phone_number()
        email = fake.email()
        address = fake.address()
        date_of_birth = fake.date_of_birth(minimum_age=18, maximum_age=80)
        gender = random.choice(['male', 'female', 'other'])
        occupation = fake.job()
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
    
    cursor.executemany(query, values)
    conn.commit()
    cursor.close()
    conn.close()
    print(f"✓ Generated {count} customers")

def generate_loan_applications(count=2000):
    """Generate loan applications"""
    print(f"Generating {count} loan applications...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Get customer IDs
    cursor.execute("SELECT customer_id FROM customers WHERE status = 'active'")
    customer_ids = [row[0] for row in cursor.fetchall()]
    
    if not customer_ids:
        print("Error: No active customers found. Generate customers first.")
        return
    
    purposes = [
        'Mua nhà', 'Mua xe', 'Kinh doanh', 'Giáo dục', 
        'Y tế', 'Du lịch', 'Tiêu dùng', 'Khác'
    ]
    
    values = []
    for i in range(count):
        customer_id = random.choice(customer_ids)
        loan_amount = random.randint(10000000, 500000000)  # 10M - 500M VND
        requested_term_months = random.choice([6, 12, 18, 24, 36, 48, 60])
        purpose = random.choice(purposes)
        
        # Status distribution: 70% approved, 20% rejected, 10% cancelled
        status = random.choices(
            ['pending', 'approved', 'rejected', 'cancelled'],
            weights=[0.10, 0.70, 0.15, 0.05]
        )[0]
        
        submitted_at = fake.date_time_between(start_date='-2y', end_date='now')
        approved_at = None
        rejected_at = None
        
        if status == 'approved':
            approved_at = submitted_at + timedelta(days=random.randint(1, 7))
        elif status == 'rejected':
            rejected_at = submitted_at + timedelta(days=random.randint(1, 5))
        
        values.append((
            customer_id, loan_amount, requested_term_months, purpose,
            status, submitted_at, approved_at, rejected_at
        ))
    
    query = """
    INSERT INTO loan_applications (
        customer_id, loan_amount, requested_term_months, purpose,
        status, submitted_at, approved_at, rejected_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    cursor.executemany(query, values)
    conn.commit()
    cursor.close()
    conn.close()
    print(f"✓ Generated {count} loan applications")

def generate_credit_scores():
    """Generate credit scores for applications"""
    print("Generating credit scores...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Get applications
    cursor.execute("SELECT application_id, customer_id FROM loan_applications")
    applications = cursor.fetchall()
    
    values = []
    for application_id, customer_id in applications:
        # Generate realistic credit score
        score = random.randint(400, 950)
        
        # Determine rating
        if score >= 750:
            rating = 'excellent'
        elif score >= 650:
            rating = 'good'
        elif score >= 550:
            rating = 'fair'
        else:
            rating = 'poor'
        
        # Generate factors
        factors = {
            'income': random.randint(5000000, 50000000),
            'employment_years': random.randint(0, 20),
            'debt_ratio': round(random.uniform(0.1, 0.6), 2),
            'credit_history_years': random.randint(0, 15),
            'number_of_loans': random.randint(0, 5)
        }
        
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
    
    cursor.executemany(query, values)
    conn.commit()
    cursor.close()
    conn.close()
    print(f"✓ Generated {len(values)} credit scores")

def generate_loan_contracts():
    """Generate loan contracts from approved applications"""
    print("Generating loan contracts...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Get approved applications
    cursor.execute("""
        SELECT application_id, loan_amount, requested_term_months
        FROM loan_applications
        WHERE status = 'approved'
    """)
    applications = cursor.fetchall()
    
    values = []
    for application_id, loan_amount, requested_term_months in applications:
        # Principal amount có thể khác loan_amount (điều chỉnh)
        principal_amount = loan_amount * random.uniform(0.9, 1.0)
        interest_rate = round(random.uniform(8.0, 18.0), 2)
        term_months = requested_term_months
        
        disbursement_date = fake.date_between(start_date='-1y', end_date='today')
        first_payment_date = disbursement_date + timedelta(days=30)
        payment_frequency = random.choice(['monthly', 'quarterly', 'annually'])
        
        # Status: 80% active, 15% closed, 5% defaulted
        status = random.choices(
            ['active', 'closed', 'defaulted'],
            weights=[0.80, 0.15, 0.05]
        )[0]
        
        signed_at = disbursement_date - timedelta(days=random.randint(1, 7))
        
        values.append((
            application_id, principal_amount, interest_rate, term_months,
            disbursement_date, None, first_payment_date,
            payment_frequency, status, signed_at
        ))
    
    query = """
    INSERT INTO loan_contracts (
        application_id, principal_amount, interest_rate, term_months,
        disbursement_date, maturity_date, first_payment_date,
        payment_frequency, status, signed_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    cursor.executemany(query, values)
    conn.commit()
    cursor.close()
    conn.close()
    print(f"✓ Generated {len(values)} loan contracts")

def generate_payment_schedules():
    """Generate payment schedules for contracts"""
    print("Generating payment schedules...")
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    
    # Get contracts
    cursor.execute("""
        SELECT contract_id, principal_amount, interest_rate, term_months,
               disbursement_date, first_payment_date, payment_frequency
        FROM loan_contracts
    """)
    contracts = cursor.fetchall()
    
    all_values = []
    for contract_id, principal_amount, interest_rate, term_months, \
        disbursement_date, first_payment_date, payment_frequency in contracts:
        
        # Calculate payment schedule
        monthly_rate = interest_rate / 100 / 12
        
        # Calculate monthly payment (amortization formula)
        if monthly_rate > 0:
            monthly_payment = principal_amount * (
                monthly_rate * (1 + monthly_rate) ** term_months
            ) / ((1 + monthly_rate) ** term_months - 1)
        else:
            monthly_payment = principal_amount / term_months
        
        remaining_principal = principal_amount
        
        for installment in range(1, term_months + 1):
            # Calculate due date based on payment frequency
            if payment_frequency == 'monthly':
                due_date = first_payment_date + timedelta(days=30 * (installment - 1))
            elif payment_frequency == 'quarterly':
                due_date = first_payment_date + timedelta(days=90 * (installment - 1))
            else:  # annually
                due_date = first_payment_date + timedelta(days=365 * (installment - 1))
            
            # Calculate principal and interest
            if monthly_rate > 0:
                interest_due = remaining_principal * monthly_rate
                principal_due = monthly_payment - interest_due
            else:
                principal_due = remaining_principal / (term_months - installment + 1)
                interest_due = 0
            
            total_due = principal_due + interest_due
            remaining_principal -= principal_due
            
            # Determine status
            if due_date < datetime.now().date():
                # Past due date
                if random.random() < 0.1:  # 10% overdue
                    status = 'overdue'
                    paid_amount = 0
                    paid_at = None
                else:
                    status = 'paid'
                    paid_amount = total_due
                    paid_at = due_date + timedelta(days=random.randint(0, 5))
            else:
                # Future payment
                status = 'pending'
                paid_amount = 0
                paid_at = None
            
            all_values.append((
                contract_id, installment, due_date,
                round(principal_due, 2), round(interest_due, 2), round(total_due, 2),
                round(paid_amount, 2), status, paid_at
            ))
    
    # Bulk insert in chunks
    chunk_size = 1000
    query = """
    INSERT INTO payment_schedules (
        contract_id, installment_number, due_date,
        principal_due, interest_due, total_due,
        paid_amount, status, paid_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    for i in range(0, len(all_values), chunk_size):
        chunk = all_values[i:i+chunk_size]
        cursor.executemany(query, chunk)
        conn.commit()
        print(f"  Inserted {min(i+chunk_size, len(all_values))}/{len(all_values)} payment schedules...")
    
    cursor.close()
    conn.close()
    print(f"✓ Generated {len(all_values)} payment schedules")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        customer_count = int(sys.argv[1])
        application_count = int(sys.argv[2]) if len(sys.argv) > 2 else customer_count * 2
    else:
        customer_count = 1000
        application_count = 2000
    
    print("=" * 60)
    print("Loan Management Database - Test Data Generator")
    print("=" * 60)
    print(f"Configuration: {customer_count} customers, {application_count} applications")
    print("=" * 60)
    
    try:
        generate_customers(customer_count)
        generate_loan_applications(application_count)
        generate_credit_scores()
        generate_loan_contracts()
        generate_payment_schedules()
        
        print("=" * 60)
        print("✓ Data generation completed successfully!")
        print("=" * 60)
    except mysql.connector.Error as e:
        print(f"✗ Database error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)

