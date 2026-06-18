use data_bank
--                                          A. Customer Nodes Exploration


--How many unique nodes are there on the Data Bank system?

select count(distinct node_id) as unique_nodecount
from customer_nodes;

--What is the number of nodes per region?

select r.region_name,count( cn.node_id) as nodecount
from customer_nodes cn inner join regions r
on cn.region_id = r.region_id
group by region_name;

--How many customers are allocated to each region?

select region_name,count(distinct customer_id) as customer_count
from customer_nodes cn inner join regions r
on cn.region_id = r.region_id
group by region_name;

--How many days on average are customers reallocated to a different node?

SELECT 
  ROUND(AVG(end_date - start_date), 0) AS avg_reallocation_days
FROM data_bank.customer_nodes
WHERE end_date != '9999-12-31';

--What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH node_days AS (
  SELECT 
    r.region_name,
    (cn.end_date - cn.start_date) AS reallocation_days
  FROM data_bank.customer_nodes cn
  JOIN data_bank.regions r ON cn.region_id = r.region_id
  WHERE cn.end_date != '9999-12-31'
)
SELECT 
  region_name,
  PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY reallocation_days) AS median_days,
  PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY reallocation_days) AS p80_days,
  PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY reallocation_days) AS p95_days
FROM node_days
GROUP BY region_name;


--                                             B. Customer Transactions


--What is the unique count and total amount for each transaction type?

SELECT 
  txn_type,
  COUNT(*) AS unique_count,
  SUM(txn_amount) AS total_amount
FROM data_bank.customer_transactions
GROUP BY txn_type;

--What is the average total historical deposit counts and amounts for allcustomers?

WITH customer_deposits AS (
  SELECT 
    customer_id,
    COUNT(txn_type) AS deposit_count,
    SUM(txn_amount) AS deposit_amount
  FROM data_bank.customer_transactions
  WHERE txn_type = 'deposit'
  GROUP BY customer_id
)
SELECT 
  ROUND(AVG(deposit_count), 0) AS avg_deposit_count,
  ROUND(AVG(deposit_amount), 2) AS avg_deposit_amount
FROM customer_deposits;

--For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH monthly_counts AS (
  SELECT 
    customer_id,
    EXTRACT(MONTH FROM txn_date) AS txn_month,
    SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
    SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
    SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
  FROM data_bank.customer_transactions
  GROUP BY customer_id, EXTRACT(MONTH FROM txn_date)
)
SELECT 
  txn_month,
  COUNT(DISTINCT customer_id) AS customer_count
FROM monthly_counts
WHERE deposit_count > 1 
  AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY txn_month
ORDER BY txn_month;

--What is the closing balance for each customer at the end of the month?

WITH monthly_transactions AS (
  SELECT 
    customer_id,
    EXTRACT(MONTH FROM txn_date) AS txn_month,
    SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS monthly_change
  FROM data_bank.customer_transactions
  GROUP BY customer_id, EXTRACT(MONTH FROM txn_date)
)
SELECT 
  customer_id,
  txn_month,
  SUM(monthly_change) OVER(PARTITION BY customer_id ORDER BY txn_month) AS closing_balance
FROM monthly_transactions;

--What is the percentage of customers who increase their closing balance by more than 5%?

WITH monthly_transactions AS (
  SELECT 
    customer_id,
    EXTRACT(MONTH FROM txn_date) AS txn_month,
    SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS monthly_change
  FROM data_bank.customer_transactions
  GROUP BY customer_id, EXTRACT(MONTH FROM txn_date)
),
closing_balances AS (
  SELECT 
    customer_id,
    txn_month,
    SUM(monthly_change) OVER(PARTITION BY customer_id ORDER BY txn_month) AS closing_balance
  FROM monthly_transactions
),
balance_growth AS (
  SELECT 
    customer_id,
    txn_month,
    closing_balance,
    LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY txn_month) AS prev_balance
  FROM closing_balances
)
SELECT 
  ROUND(100.0 * COUNT(DISTINCT customer_id) / 
    (SELECT COUNT(DISTINCT customer_id) FROM data_bank.customer_transactions), 2) AS percentage_customers
FROM balance_growth
WHERE prev_balance > 0 
  AND closing_balance > prev_balance * 1.05;


--                                                     C. Data Allocation Challenge



--To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options------:




--Option 1: data is allocated based off the amount of money at the end of the previous month
--Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
--Option 3: data is updated real-time

--For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

--running customer balance column that includes the impact each transaction

SELECT 
  customer_id,
  txn_date,
  txn_type,
  txn_amount,
  SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) 
    OVER(PARTITION BY customer_id ORDER BY txn_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
FROM data_bank.customer_transactions;

--customer balance at the end of each month

WITH monthly_changes AS (
  SELECT 
    customer_id,
    EXTRACT(MONTH FROM txn_date) AS txn_month,
    SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
  FROM data_bank.customer_transactions
  GROUP BY customer_id, EXTRACT(MONTH FROM txn_date)
)
SELECT 
  customer_id,
  txn_month,
  SUM(net_change) OVER(
    PARTITION BY customer_id 
    ORDER BY txn_month
  ) AS end_of_month_balance
FROM monthly_changes;

--minimum, average and maximum values of the running balance for each customer

WITH running_balances AS (
  SELECT 
    customer_id,
    SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) 
      OVER(PARTITION BY customer_id ORDER BY txn_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
  FROM data_bank.customer_transactions
)
SELECT 
  customer_id,
  MIN(running_balance) AS min_balance,
  MAX(running_balance) AS max_balance,
  ROUND(AVG(running_balance), 2) AS avg_balance
FROM running_balances
GROUP BY customer_id;

--Using all of the data available - how much data would have been required for each option on a monthly basis?




--                                                      D. Extra Challenge



--Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

--If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

WITH customer_dates AS (
  -- Find the first and last transaction dates for each customer to set the calendar bounds
  SELECT 
    customer_id,
    MIN(txn_date) AS start_date,
    MAX(txn_date) AS end_date 
  FROM data_bank.customer_transactions
  GROUP BY customer_id
),
date_series AS (
  -- Generate a row for every single day between a customer's first and last transaction
  SELECT 
    customer_id,
    GENERATE_SERIES(start_date, end_date, '1 day'::interval)::date AS daily_date
  FROM customer_dates
),
daily_changes AS (
  -- Calculate the net change in balance for days where transactions actually occurred
  SELECT 
    customer_id,
    txn_date,
    SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS amount_change
  FROM data_bank.customer_transactions
  GROUP BY customer_id, txn_date
),
daily_balances AS (
  -- Join the continuous calendar with the transaction changes and calculate the running balance
  SELECT 
    ds.customer_id,
    ds.daily_date,
    COALESCE(dc.amount_change, 0) AS daily_change,
    SUM(COALESCE(dc.amount_change, 0)) OVER(
      PARTITION BY ds.customer_id 
      ORDER BY ds.daily_date
    ) AS running_balance
  FROM date_series ds
  LEFT JOIN daily_changes dc 
    ON ds.customer_id = dc.customer_id AND ds.daily_date = dc.txn_date
)
-- Calculate the 6% annual interest applied daily on positive balances, grouped by month
SELECT 
  EXTRACT(MONTH FROM daily_date) AS allocation_month,
  ROUND(SUM(CASE 
    WHEN running_balance > 0 THEN running_balance * (0.06 / 365) 
    ELSE 0 
  END), 2) AS estimated_data_required
FROM daily_balances
GROUP BY EXTRACT(MONTH FROM daily_date)
ORDER BY allocation_month;