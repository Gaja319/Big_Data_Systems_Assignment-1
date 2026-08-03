#!/bin/bash
# ==============================================================================
# HBase Verification & Query Script
# Demonstrates fast downstream feature vector serving & row queries
# ==============================================================================

echo "=== 1. Checking HBase Table Count & Scan Sample ==="
hbase shell <<EOF
count 'customer_rfm_features'
scan 'customer_rfm_features', {LIMIT => 3}
EOF

echo "=== 2. Point Lookups for Downstream Model Serving ==="
echo "Retrieving Feature Vector for Customer CUST_0001:"
hbase shell <<EOF
get 'customer_rfm_features', 'CUST_0001'
EOF

echo "=== 3. Querying Specific Column Family (RFM Metrics only) ==="
hbase shell <<EOF
get 'customer_rfm_features', 'CUST_0005', {COLUMN => 'cf_rfm'}
EOF

echo "=== 4. Updating Feature Vector (Simulating Real-Time Event) ==="
hbase shell <<EOF
put 'customer_rfm_features', 'CUST_0001', 'cf_rfm:recency_days', '0'
get 'customer_rfm_features', 'CUST_0001', {COLUMN => 'cf_rfm:recency_days'}
EOF
