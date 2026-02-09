# Base image with NVIDIA PyTorch
FROM nvcr.io/nvidia/pytorch:24.11-py3

# Set working directory
WORKDIR /workspace

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Update pip
RUN pip install --upgrade pip

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get install -y libdbus-1-dev pkg-config \
    libglib2.0-dev libdbus-1-dev pkg-config \ 
    cmake \
    libcairo2-dev


# Install transformers and related dependencies
RUN pip install --no-cache-dir \
    transformers \
    tokenizers \
    datasets \
    accelerate \
    sentencepiece \
    protobuf

# Install additional utilities
RUN pip install --no-cache-dir \
    wandb \
    tensorboard \
    ipython \
    jupyter

# Copy project files (optional - uncomment if needed)
# COPY . /workspace/MegaDLMs

# Set the default command
CMD ["/bin/bash"]
