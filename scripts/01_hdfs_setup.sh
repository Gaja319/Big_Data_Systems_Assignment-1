#!/bin/bash
# ==============================================================================
# HDFS Setup Script for Retail Customer Segmentation & Churn Prediction
# Task: Create HDFS directory hierarchy and ingest CSV datasets
# ==============================================================================

echo "=== Step 1: Creating HDFS Directories ==="
hdfs dfs -mkdir -p /data/retail/customers
hdfs dfs -mkdir -p /data/retail/purchases
hdfs dfs -mkdir -p /data/retail/products
hdfs dfs -mkdir -p /data/retail/output

echo "=== Step 2: Ingesting Data into HDFS ==="
hdfs dfs -put -f ../data/customers.csv /data/retail/customers/
hdfs dfs -put -f ../data/purchases.csv /data/retail/purchases/
hdfs dfs -put -f ../data/products.csv /data/retail/products/

echo "=== Step 3: Verifying Ingested Files in HDFS ==="
echo "[Customers Directory]"
hdfs dfs -ls /data/retail/customers/

echo "[Purchases Directory]"
hdfs dfs -ls /data/retail/purchases/

echo "[Products Directory]"
hdfs dfs -ls /data/retail/products/

echo "=== HDFS Setup Complete ==="
