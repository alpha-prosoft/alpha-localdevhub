# Build argument for Docker registry URL (defaults to Docker Hub)
ARG DOCKER_URL=docker.io

# Use AWS Lambda Python runtime as base image
FROM ${DOCKER_URL}/amazon/aws-lambda-python:3.13-x86_64 AS builder

# Build argument for custom pip index URL (optional)
ARG PIP_INDEX_URL

# Install build dependencies
# Use dnf for Amazon Linux 2023 (Python 3.12+) or yum for older versions
RUN dnf install -y zip || yum install -y zip

# Set working directory
WORKDIR /build

# Create dist directory for output files
RUN mkdir -p /dist

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies for the layer
# Use custom index URL if provided, otherwise use default PyPI
RUN if [ -n "$PIP_INDEX_URL" ]; then \
        echo "Using custom pip index: $PIP_INDEX_URL" && \
        pip install --index-url "$PIP_INDEX_URL" --target /build/python/ -r requirements.txt && \
        pip install --index-url "$PIP_INDEX_URL" --target /build/python/ certbot-dns-route53; \
    else \
        echo "Using default PyPI index" && \
        pip install --target /build/python/ -r requirements.txt && \
        pip install --target /build/python/ certbot-dns-route53; \
    fi

# Create layer zip file
RUN cd /build && \
    zip -r /dist/lambda-layer.zip python/ && \
    echo "Layer size: $(du -h /dist/lambda-layer.zip)"

# Copy Lambda function code
COPY main.py /build/

# Create function zip file
RUN cd /build && \
    zip /dist/lambda-function.zip main.py && \
    echo "Function size: $(du -h /dist/lambda-function.zip)"

# Final stage - output the artifacts
FROM scratch AS export
COPY --from=builder /dist/lambda-layer.zip /
COPY --from=builder /dist/lambda-function.zip /
