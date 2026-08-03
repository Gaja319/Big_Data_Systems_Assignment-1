-- ==============================================================================
-- Hive HQL Script: Customer Segmentation, Cohort Analysis & Churn Prediction
-- Objective: Build analytical tables, perform RFM scoring/segmentation, 
--            execute cohort retention analysis, and output churn-labeled datasets.
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS retail_analytics_db;
USE retail_analytics_db;

-- ------------------------------------------------------------------------------
-- 1. Create Raw External Tables over HDFS Data
-- ------------------------------------------------------------------------------
CREATE EXTERNAL TABLE IF NOT EXISTS ext_customers (
    customer_id STRING,
    signup_date STRING,
    location STRING,
    demographic_segment STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/retail/customers/'
TBLPROPERTIES ("skip.header.line.count"="1");

CREATE EXTERNAL TABLE IF NOT EXISTS ext_purchases (
    customer_id STRING,
    order_id STRING,
    order_date STRING,
    product_id STRING,
    quantity INT,
    amount DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/retail/purchases/'
TBLPROPERTIES ("skip.header.line.count"="1");

CREATE EXTERNAL TABLE IF NOT EXISTS ext_products (
    product_id STRING,
    category STRING,
    price DOUBLE,
    department STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/retail/products/'
TBLPROPERTIES ("skip.header.line.count"="1");

-- ------------------------------------------------------------------------------
-- 2. Create RFM Feature Table from Pig/MapReduce Output
-- ------------------------------------------------------------------------------
CREATE EXTERNAL TABLE IF NOT EXISTS ext_rfm_computed (
    customer_id STRING,
    recency_days INT,
    frequency INT,
    monetary_amount DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/retail/output/rfm_features';

-- ------------------------------------------------------------------------------
-- 3. Customer RFM Scoring & Segmentation View
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_customer_rfm_scored AS
WITH rfm_ranks AS (
    SELECT 
        customer_id,
        recency_days,
        frequency,
        monetary_amount,
        -- Recency: Inverted rank so lowest recency days gets rank 5
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_amount ASC) AS m_score
    FROM ext_rfm_computed
)
SELECT 
    customer_id,
    recency_days,
    frequency,
    monetary_amount,
    r_score,
    f_score,
    m_score,
    CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_combined_code,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score >= 2 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost / Churned'
        ELSE 'Needs Attention'
    END AS customer_segment,
    -- Churn Labeling rule: Recency > 90 days = Churned (1), else Active (0)
    CASE 
        WHEN recency_days > 90 THEN 1 
        ELSE 0 
    END AS is_churned
FROM rfm_ranks;

-- ------------------------------------------------------------------------------
-- 4. Cohort Analysis: Signup Cohort Monthly Retention & Spend Metrics
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tbl_cohort_analysis AS
SELECT 
    substr(c.signup_date, 1, 7) AS cohort_month,
    COUNT(DISTINCT c.customer_id) AS total_cohort_customers,
    COUNT(DISTINCT p.customer_id) AS active_purchasing_customers,
    ROUND(SUM(p.amount), 2) AS total_cohort_revenue,
    ROUND(AVG(p.amount), 2) AS avg_order_value
FROM ext_customers c
LEFT JOIN ext_purchases p ON c.customer_id = p.customer_id
GROUP BY substr(c.signup_date, 1, 7)
ORDER BY cohort_month;

-- ------------------------------------------------------------------------------
-- 5. Final Analytics Table Joining Demographics + RFM + Segment + Churn Label
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tbl_customer_analytics_final AS
SELECT 
    c.customer_id,
    c.signup_date,
    c.location,
    c.demographic_segment,
    r.recency_days,
    r.frequency,
    r.monetary_amount,
    r.r_score,
    r.f_score,
    r.m_score,
    r.rfm_combined_code,
    r.customer_segment,
    r.is_churned
FROM ext_customers c
JOIN v_customer_rfm_scored r ON c.customer_id = r.customer_id;

-- Summary Query 1: Segment Distribution & Churn Rate
SELECT 
    customer_segment,
    COUNT(*) AS total_customers,
    SUM(is_churned) AS churned_count,
    ROUND(AVG(is_churned) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(monetary_amount), 2) AS avg_monetary_val,
    ROUND(AVG(recency_days), 1) AS avg_recency_days
FROM tbl_customer_analytics_final
GROUP BY customer_segment
ORDER BY total_customers DESC;

-- Summary Query 2: Sample High-Value Churned Customers for Targeted Campaigns
SELECT 
    customer_id, location, demographic_segment, recency_days, monetary_amount, customer_segment
FROM tbl_customer_analytics_final
WHERE is_churned = 1 AND monetary_amount > 500
ORDER BY monetary_amount DESC
LIMIT 10;
