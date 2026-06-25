from pyspark.sql import SparkSession
from pyspark.sql.functions import col

spark = SparkSession.builder \
    .appName("SalesDataFrameProcessing") \
    .master("local[*]") \
    .getOrCreate()

df = spark.read.csv("data/sales.csv", header=True, inferSchema=True)


print("\n--- All Products Sorted by Sales (Descending) ---")
sorted_df = df.orderBy(col("sales").desc())
sorted_df.show()


print("\n--- Top 3 Products with Highest Sales ---")
sorted_df.limit(3).show()


print("\n--- Filtering Products (Sales > 80,000) and Saving to Output ---")
filtered_df = df.filter(col("sales") > 80000)

filtered_df.coalesce(1).write.csv("output/high_sales_products", header=True, mode="overwrite")
print("Data successfully saved to 'output/high_sales_products'.")

spark.stop()