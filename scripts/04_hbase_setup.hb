# ==============================================================================
# HBase Shell Commands: Schema Setup for Fast Downstream Serving
# Table: customer_rfm_features
# Column Families:
#   - cf_demographics: location, signup_date, demographic_segment
#   - cf_rfm: recency_days, frequency, monetary_amount, rfm_code
#   - cf_segmentation: customer_segment, is_churned
# ==============================================================================

# Disable and drop table if it exists (for clean execution)
disable 'customer_rfm_features'
drop 'customer_rfm_features'

# Create HBase table with defined column families
create 'customer_rfm_features', 'cf_demographics', 'cf_rfm', 'cf_segmentation'

# Verify Table Schema
describe 'customer_rfm_features'

# Verify Table Exists
list 'customer_rfm_features'
