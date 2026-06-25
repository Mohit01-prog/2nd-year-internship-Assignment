# PySpark DataFrame Sales Processing

## Objective
A PySpark DataFrame application deployed via Docker to analyze a sales dataset.

## Operations Performed
1. Read `sales.csv` into a PySpark DataFrame.
2. Sort products by sales in descending order.
3. Display the top 3 products with the highest sales.
4. Filter products with sales greater than 80,000 and save the results as a CSV file.

## Execution Instructions

**1. Build the Docker Image**
```bash
docker build -t sales-df-app .