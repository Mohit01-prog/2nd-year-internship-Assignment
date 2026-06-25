from pyspark.sql import SparkSession

# Create Spark Session
spark = SparkSession.builder \
    .appName("EmployeeRDDProcessing") \
    .master("local[*]") \
    .getOrCreate()

sc = spark.sparkContext

# Read CSV file
rdd = sc.textFile("data/employees.csv")

# Remove header
header = rdd.first()
rdd = rdd.filter(lambda x: x != header)

# Convert rows to tuples
employees = rdd.map(lambda x: x.split(","))


# 1. Sort employees by salary descending

sorted_employees = employees.sortBy(
    lambda x: int(x[3]),
    ascending=False
)

print("\n===== Employees Sorted by Salary (Descending) =====")

for emp in sorted_employees.collect():
    print(emp)


# 2. Total salary department-wise

dept_salary = employees.map(
    lambda x: (x[2], int(x[3]))
)

dept_totals = dept_salary.reduceByKey(
    lambda a, b: a + b
)

print("\n===== Department Wise Salary Totals =====")

for dept, total in dept_totals.collect():
    print(f"{dept}: {total}")


# 3. Top 3 highest-paid employees

top3 = sorted_employees.take(3)

output_rdd = sc.parallelize(
    [
        f"{emp[0]},{emp[1]},{emp[2]},{emp[3]}"
        for emp in top3
    ]
)

output_rdd.saveAsTextFile("output/top3_employees")

print("\n===== Top 3 Highest Paid Employees =====")

for emp in top3:
    print(emp)

spark.stop()