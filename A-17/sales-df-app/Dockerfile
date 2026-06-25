# Use the official Python slim image
FROM python:3.10-slim

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install ONLY the headless JRE (Java) to save massive space
# --no-install-recommends prevents installing unnecessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends default-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Java environment variable
ENV JAVA_HOME=/usr/lib/jvm/default-java

# Set the working directory
WORKDIR /workspace

# Copy ONLY requirements first to leverage Docker layer caching
COPY requirements.txt .

# Install PySpark (This automatically includes the necessary Spark binaries)
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the project files
COPY . .

# Automatically run the application
CMD ["spark-submit", "app.py"]