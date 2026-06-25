# Employee RDD Processing using PySpark

## Objective

Perform RDD-based processing on employee data.

### Operations

1. Sort employees by salary descending.
2. Calculate total salary department-wise.
3. Find top 3 highest-paid employees.
4. Save top 3 employees to output file.

---

## Dataset

employees.csv

---

## Requirements

- Docker
- Git

---

## Build Docker Image

```bash
docker build -t employee-rdd-app .
```

## Run Container

```bash
docker run --rm employee-rdd-app
```

---

## Output

### Department Totals

IT = 170000

HR = 85000

Finance = 130000

### Top 3 Employees

Priya

Neha

Rohit