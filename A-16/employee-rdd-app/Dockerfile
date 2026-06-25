FROM apache/spark:3.5.1

USER root

WORKDIR /workspace

COPY . .

RUN pip install --no-cache-dir pyspark==3.5.1

CMD ["spark-submit", "app.py"]