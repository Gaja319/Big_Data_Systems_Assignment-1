import csv
import random
from datetime import datetime, timedelta

# Set seed for reproducibility
random.seed(42)

# Configuration
NUM_CUSTOMERS = 200
NUM_PRODUCTS = 50
NUM_PURCHASES = 1500
REFERENCE_DATE = datetime(2026, 8, 1)

# 1. Generate Product Catalog CSV
# Schema: product_id, category, price, department
categories = {
    'Electronics': ['Laptops', 'Audio', 'Accessories', 'Mobile'],
    'Apparel': ['Men', 'Women', 'Kids', 'Footwear'],
    'Home & Kitchen': ['Furniture', 'Cookware', 'Decor', 'Appliances'],
    'Beauty & Health': ['Skincare', 'Fitness', 'Personal Care']
}

products = []
for i in range(1, NUM_PRODUCTS + 1):
    pid = f"PROD_{i:03d}"
    cat = random.choice(list(categories.keys()))
    dept = random.choice(categories[cat])
    price = round(random.uniform(10.0, 500.0), 2)
    products.append([pid, cat, price, dept])

with open('products.csv', 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['product_id', 'category', 'price', 'department'])
    writer.writerows(products)

print(f"Generated products.csv with {len(products)} records.")

# 2. Generate Customer Data CSV
# Schema: customer_id, signup_date, location, demographic_segment
locations = ['New York', 'California', 'Texas', 'Florida', 'Illinois', 'Washington', 'Ohio']
segments = ['Young Adults', 'Families', 'Seniors', 'Professionals', 'Students']

customers = []
for i in range(1, NUM_CUSTOMERS + 1):
    cid = f"CUST_{i:04d}"
    # Signup date between 2024-01-01 and 2026-06-30
    days_back = random.randint(30, 900)
    signup_date = (REFERENCE_DATE - timedelta(days=days_back)).strftime('%Y-%m-%d')
    loc = random.choice(locations)
    seg = random.choice(segments)
    customers.append([cid, signup_date, loc, seg])

with open('customers.csv', 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['customer_id', 'signup_date', 'location', 'demographic_segment'])
    writer.writerows(customers)

print(f"Generated customers.csv with {len(customers)} records.")

# 3. Generate Purchase History CSV
# Schema: customer_id, order_id, order_date, product_id, quantity, amount
purchases = []
order_seq = 10000

# Create varying activity patterns to generate realistic churners & champions
for _ in range(NUM_PURCHASES):
    order_seq += 1
    oid = f"ORD_{order_seq}"
    
    # Select customer with weighted distribution (some active, some churned)
    cust_idx = random.randint(1, NUM_CUSTOMERS)
    cid = f"CUST_{cust_idx:04d}"
    
    # 20% of customers stopped buying > 180 days ago (Churned)
    if cust_idx % 5 == 0:
        order_days_ago = random.randint(180, 500)
    else:
        order_days_ago = random.randint(1, 150)
        
    order_date = (REFERENCE_DATE - timedelta(days=order_days_ago)).strftime('%Y-%m-%d')
    
    prod = random.choice(products)
    pid = prod[0]
    unit_price = prod[2]
    qty = random.randint(1, 5)
    amount = round(qty * unit_price, 2)
    
    purchases.append([cid, oid, order_date, pid, qty, amount])

# Sort purchases by order_date
purchases.sort(key=lambda x: x[2])

with open('purchases.csv', 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['customer_id', 'order_id', 'order_date', 'product_id', 'quantity', 'amount'])
    writer.writerows(purchases)

print(f"Generated purchases.csv with {len(purchases)} records.")
