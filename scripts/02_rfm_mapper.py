#!/usr/bin/env python3
"""
Hadoop Streaming MapReduce Mapper: RFM Computation
Extracts customer_id, order_date, and amount from purchases.csv
"""
import sys

for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith("customer_id"):
        continue
    
    parts = line.split(",")
    if len(parts) >= 6:
        customer_id = parts[0]
        order_date = parts[2]
        try:
            amount = float(parts[5])
            print(f"{customer_id}\t{order_date}\t{amount}")
        except ValueError:
            continue
