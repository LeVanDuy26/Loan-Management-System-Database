#!/usr/bin/env python3
"""
Database Health Monitoring Script
Monitors database health metrics and provides status report
"""

import mysql.connector
from datetime import datetime

# Database connection - UPDATE THESE VALUES
config = {
    'user': 'loan_app',
    'password': 'your_password',  # UPDATE THIS
    'host': 'localhost',
    'database': 'loan_management'
}

def get_status_value(cursor, status_name):
    """Get a status value"""
    cursor.execute(f"SHOW STATUS LIKE '{status_name}'")
    result = cursor.fetchone()
    return int(result[1]) if result else 0

def get_variable_value(cursor, var_name):
    """Get a variable value"""
    cursor.execute(f"SHOW VARIABLES LIKE '{var_name}'")
    result = cursor.fetchone()
    return result[1] if result else None

def monitor_database():
    """Monitor database health"""
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        
        print("=" * 60)
        print("Database Health Monitor")
        print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        
        # Connection metrics
        print("\n[Connection Metrics]")
        print("-" * 60)
        connections = get_status_value(cursor, 'Threads_connected')
        max_connections = get_variable_value(cursor, 'max_connections')
        connection_usage = (connections / int(max_connections)) * 100 if max_connections else 0
        print(f"Active Connections: {connections} / {max_connections} ({connection_usage:.1f}%)")
        
        # Query metrics
        print("\n[Query Metrics]")
        print("-" * 60)
        total_queries = get_status_value(cursor, 'Questions')
        slow_queries = get_status_value(cursor, 'Slow_queries')
        slow_query_ratio = (slow_queries / total_queries * 100) if total_queries > 0 else 0
        print(f"Total Queries: {total_queries:,}")
        print(f"Slow Queries: {slow_queries:,} ({slow_query_ratio:.2f}%)")
        
        # Table sizes
        print("\n[Table Sizes]")
        print("-" * 60)
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
            print(f"{'Table':<30} {'Total (MB)':<12} {'Data (MB)':<12} {'Index (MB)':<12} {'Rows':<15}")
            print("-" * 60)
            for table, total_size, data_size, index_size, rows in table_sizes:
                print(f"{table:<30} {total_size:<12} {data_size:<12} {index_size:<12} {rows:<15,}")
        else:
            print("No tables found")
        
        # Index usage
        print("\n[Index Usage]")
        print("-" * 60)
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
            print(f"{'Table':<25} {'Index':<25} {'Column':<20} {'Cardinality':<15}")
            print("-" * 60)
            for table, index, seq, column, cardinality in indexes:
                print(f"{table:<25} {index:<25} {column:<20} {cardinality:<15,}")
        else:
            print("No indexes found")
        
        # Performance metrics
        print("\n[Performance Metrics]")
        print("-" * 60)
        innodb_buffer_pool_size = get_variable_value(cursor, 'innodb_buffer_pool_size')
        innodb_buffer_pool_reads = get_status_value(cursor, 'Innodb_buffer_pool_reads')
        innodb_buffer_pool_read_requests = get_status_value(cursor, 'Innodb_buffer_pool_read_requests')
        
        if innodb_buffer_pool_size:
            buffer_pool_size_mb = int(innodb_buffer_pool_size) / 1024 / 1024
            print(f"InnoDB Buffer Pool Size: {buffer_pool_size_mb:.0f} MB")
        
        if innodb_buffer_pool_read_requests > 0:
            hit_ratio = (1 - (innodb_buffer_pool_reads / innodb_buffer_pool_read_requests)) * 100
            print(f"Buffer Pool Hit Ratio: {hit_ratio:.2f}%")
            if hit_ratio < 95:
                print("  ⚠ WARNING: Low buffer pool hit ratio - consider increasing buffer pool size")
        
        # Health status
        print("\n[Health Status]")
        print("-" * 60)
        issues = []
        
        if connection_usage > 80:
            issues.append("High connection usage")
        
        if slow_query_ratio > 1:
            issues.append("High slow query ratio")
        
        if innodb_buffer_pool_read_requests > 0:
            hit_ratio = (1 - (innodb_buffer_pool_reads / innodb_buffer_pool_read_requests)) * 100
            if hit_ratio < 95:
                issues.append("Low buffer pool hit ratio")
        
        if issues:
            print("⚠ WARNINGS:")
            for issue in issues:
                print(f"  - {issue}")
        else:
            print("✓ All metrics within acceptable ranges")
        
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 60)
        
    except mysql.connector.Error as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    monitor_database()

