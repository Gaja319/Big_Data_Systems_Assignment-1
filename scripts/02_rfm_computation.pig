-- ==============================================================================
-- Pig Latin Script: Compute RFM (Recency, Frequency, Monetary) Features
-- Objective: Ingest purchase history from HDFS, group by customer_id, and 
--            compute Recency (days), Frequency (order count), and Monetary (total spend).
-- ==============================================================================

-- Load Purchases Dataset from HDFS (Skip header line if present)
raw_purchases = LOAD '/data/retail/purchases/purchases.csv' USING PigStorage(',') 
    AS (customer_id:chararray, order_id:chararray, order_date:chararray, product_id:chararray, quantity:int, amount:double);

-- Filter out CSV header row
purchases = FILTER raw_purchases BY customer_id != 'customer_id';

-- Group transactions by customer_id
grouped_cust = GROUP purchases BY customer_id;

-- Compute aggregate metrics per customer relative to Reference Date '2026-08-01'
rfm_raw = FOREACH grouped_cust {
    -- Extract latest purchase date
    max_date = MAX(purchases.order_date);
    -- Calculate total frequency & monetary spend
    freq = COUNT(purchases);
    monetary = SUM(purchases.amount);
    GENERATE 
        group AS customer_id,
        max_date AS last_purchase_date,
        freq AS frequency,
        ROUND_TO(monetary, 2) AS monetary_amount;
};

-- Calculate Recency in days (DaysBetween reference date '2026-08-01' and max_date)
rfm_features = FOREACH rfm_raw GENERATE 
    customer_id,
    DaysBetween(ToDate('2026-08-01', 'yyyy-MM-dd'), ToDate(last_purchase_date, 'yyyy-MM-dd')) AS recency_days,
    frequency,
    monetary_amount;

-- Store computed RFM features into HDFS for Hive table loading
STORE rfm_features INTO '/data/retail/output/rfm_features' USING PigStorage(',');
