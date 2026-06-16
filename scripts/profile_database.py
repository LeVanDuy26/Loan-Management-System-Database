#!/usr/bin/env python3
"""
Database Performance Profiling Script
Profiles critical queries and provides performance metrics
"""

import mysql.connector
import time
import sys

# Database connection - UPDATE THESE VALUES
config = {
    'user': 'loan_app',
    'password': 'your_password',  # UPDATE THIS
    'host': 'localhost',
    'database': 'loan_management'
}

def explain_query(query, name):
    """Explain a query"""
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        
        cursor.execute(f"EXPLAIN {query}")
        results = cursor.fetchall()
        
        print(f"\n{name} - EXPLAIN:")
        print("-" * 60)
        if results:
            # Print header
            columns = [desc[0] for desc in cursor.description]
            print("  " + " | ".join(columns))
            print("  " + "-" * 60)
            # Print rows
            for row in results:
                print("  " + " | ".join(str(val) for val in row))
        else:
            print("  No execution plan available")
        
        cursor.close()
        conn.close()
    except mysql.connector.Error as e:
        print(f"  Error: {e}")

def profile_query(query, name, iterations=10):
    """Profile a query"""
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        
        times = []
        row_counts = []
        
        for i in range(iterations):
            start = time.time()
            cursor.execute(query)
            results = cursor.fetchall()
            elapsed = (time.time() - start) * 1000  # Convert to ms
            times.append(elapsed)
            row_counts.append(len(results))
        
        cursor.close()
        conn.close()
        
        avg_time = sum(times) / len(times)
        min_time = min(times)
        max_time = max(times)
        avg_rows = sum(row_counts) / len(row_counts)
        
        print(f"\n{name} - Performance:")
        print("-" * 60)
        print(f"  Average: {avg_time:.2f} ms")
        print(f"  Min: {min_time:.2f} ms")
        print(f"  Max: {max_time:.2f} ms")
        print(f"  Average Rows: {avg_rows:.0f}")
        print(f"  Iterations: {iterations}")
        
        # Performance assessment
        if avg_time < 100:
            status = "✓ EXCELLENT"
        elif avg_time < 500:
            status = "✓ GOOD"
        elif avg_time < 2000:
            status = "⚠ ACCEPTABLE"
        else:
            status = "✗ NEEDS OPTIMIZATION"
        
        print(f"  Status: {status}")
        
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
        print(f"  Error: {e}")
        return None

# Critical queries to profile
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
        "Overdue Payments Query (CRITICAL)"
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
        "Customer Applications Query"
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
        "Active Contracts Query"
    ),
    (
        """
        SELECT * FROM customers 
        WHERE phone = '0912345678'
        """,
        "Customer Lookup by Phone"
    ),
    (
        """
        SELECT * FROM loan_applications 
        WHERE status = 'pending' 
        ORDER BY submitted_at ASC
        LIMIT 50
        """,
        "Pending Applications Query"
    )
]

if __name__ == '__main__':
    print("=" * 60)
    print("Database Performance Profiling")
    print("=" * 60)
    
    results = []
    for query, name in queries:
        explain_query(query, name)
        result = profile_query(query, name, iterations=10)
        if result:
            results.append(result)
    
    print("\n" + "=" * 60)
    print("Summary:")
    print("=" * 60)
    for result in results:
        print(f"{result['name']}")
        print(f"  Average Time: {result['avg_time']:.2f} ms - {result['status']}")
    
    print("\n" + "=" * 60)
    print("Performance Targets:")
    print("  ✓ EXCELLENT: < 100 ms")
    print("  ✓ GOOD: < 500 ms")
    print("  ⚠ ACCEPTABLE: < 2000 ms")
    print("  ✗ NEEDS OPTIMIZATION: >= 2000 ms")
    print("=" * 60)

