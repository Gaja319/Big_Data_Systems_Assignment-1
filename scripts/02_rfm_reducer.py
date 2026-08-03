#!/usr/bin/env python3
"""
Hadoop Streaming MapReduce Reducer: RFM Computation
Aggregates transactions per customer_id to calculate:
- Recency (days since last purchase relative to 2026-08-01)
- Frequency (total orders)
- Monetary (total spend)
"""
import sys
from datetime import datetime

REFERENCE_DATE = datetime(2026, 8, 1)

current_cust = None
latest_date = None
frequency = 0
monetary = 0.0

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    
    parts = line.split("\t")
    if len(parts) != 3:
        continue
    
    cust_id, odate_str, amt_str = parts[0], parts[1], parts[2]
    try:
        odate = datetime.strptime(odate_str, "%Y-%m-%d")
        amt = float(amt_str)
    except ValueError:
        continue

    if current_cust == cust_id:
        frequency += 1
        monetary += amt
        if odate > latest_date:
            latest_date = odate
    else:
        if current_cust:
            recency_days = (REFERENCE_DATE - latest_date).days
            print(f"{current_cust},{recency_days},{frequency},{monetary:.2f}")
        
        current_cust = cust_id
        latest_date = odate
        frequency = 1
        monetary = amt

if current_cust:
    recency_days = (REFERENCE_DATE - latest_date).days
    print(f"{current_cust},{recency_days},{frequency},{monetary:.2f}")
