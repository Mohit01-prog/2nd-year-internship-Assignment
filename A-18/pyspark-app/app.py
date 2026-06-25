from pyspark.sql import SparkSession

def main():

    spark = SparkSession.builder \
        .appName("PartitionManagementAssignment") \
        .master("local[*]") \
        .getOrCreate()

    try:
        # Generate a DataFrame containing 5 million records
        print("Generating DataFrame...")
        df = spark.range(5000000)
        
        # 1. Display the initial number of partitions
        initial_partitions = df.rdd.getNumPartitions()
        print(f"Initial number of partitions: {initial_partitions}")
        
        # 2. Increase the partitions to 12 using repartition()
        df_repartitioned = df.repartition(12)
        repartitioned_count = df_repartitioned.rdd.getNumPartitions()
        print(f"Partitions after repartition(12): {repartitioned_count}")
        
        # 3. Reduce the partitions to 3 using coalesce()
        df_coalesced = df_repartitioned.coalesce(3)
        coalesced_count = df_coalesced.rdd.getNumPartitions()
        print(f"Partitions after coalesce(3): {coalesced_count}")

    finally:
        # Stop the SparkSession to release resources
        spark.stop()

if __name__ == "__main__":
    main()