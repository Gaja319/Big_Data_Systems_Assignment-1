#!/bin/bash
# ==============================================================================
# Master Execution Pipeline Script
# Project: Retail Customer Segmentation & Churn Prediction (Problem 18)
# Runs the entire Hadoop ecosystem pipeline end-to-end:
# Data Generation -> HDFS Ingestion -> Pig RFM Computation -> Hive Analytics -> HBase Loading & Serving
# ==============================================================================

set -e

echo "========================================================"
echo " Starting Retail Customer Segmentation Pipeline"
echo "========================================================"

echo "[STAGE 1] Generating Synthetic CSV Datasets..."
cd ../data
python generate_datasets.py
cd ../scripts

echo "[STAGE 2] Setting up HDFS Directories and Uploading Data..."
bash 01_hdfs_setup.sh

echo "[STAGE 3] Executing Pig Latin Script for RFM Computation..."
pig -x mapreduce 02_rfm_computation.pig

echo "[STAGE 4] Executing Hive HQL Script for Segmentation & Cohort Analysis..."
hive -f 03_hive_analysis.hql

echo "[STAGE 5] Creating HBase Schema and Ingesting Feature Vectors..."
hbase shell 04_hbase_setup.hb
python 04_hbase_load.py
hbase shell load_hbase.hb

echo "[STAGE 6] Verifying Fast HBase Model Serving Lookups..."
bash 04_hbase_queries.sh

echo "========================================================"
echo " Pipeline Executed Successfully!"
echo " All datasets, Hive tables, and HBase feature vectors ready."
echo "========================================================"
