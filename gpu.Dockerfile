# Use a NVIDIA CUDA development image as builder
FROM nvidia/cuda:13.0.0-cudnn-devel-ubuntu24.04@sha256:c2621d98e7de80c2aec5eb8403b19c67454c8f5b0c929e8588fd3563c9b6558d AS builder

# Install build tools needed for some packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    libboost-all-dev \
    libeigen3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install the project into `/app`
WORKDIR /app

# Copy the uv binary from the uv image
COPY --from=ghcr.io/astral-sh/uv:latest@sha256:a5727064a0de127bdb7c9d3c1383f3a9ac307d9f2d8a391edc7896c54289ced0 /uv /bin/

RUN mkdir /app/python && \
    mkdir /app/bin 

ENV UV_PYTHON_INSTALL_DIR=/app/python
ENV UV_PYTHON_BIN_DIR=/app/bin
ENV PATH="/app/bin:$PATH"

# Install the correct python version
RUN --mount=type=bind,source=.python-version,target=/app/.python-version \
    uv python install

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1
# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Install the transitive dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --no-dev --extra gpu --extra frontend --locked --no-install-project

COPY . /app

# Install the project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-dev --extra gpu --extra frontend --locked

# Use a NVIDIA CUDA runtime image as runner
FROM docker.io/nvidia/cuda:13.0.0-cudnn-runtime-ubuntu24.04@sha256:f2c12914cf4751e61073843724275aa35d4817e01dbdc87eac03905971628c6e AS runner

# Metadata for the image
ARG IMAGE_CREATED="unknown"
ARG IMAGE_REVISION="unknown"
ARG IMAGE_VERSION="unknown"
LABEL org.opencontainers.image.authors='Fabian Reinold <contact@freinold.eu>' \
    org.opencontainers.image.vendor='Fabian Reinold' \
    org.opencontainers.image.created="$IMAGE_CREATED" \
    org.opencontainers.image.revision="$IMAGE_REVISION" \
    org.opencontainers.image.version="$IMAGE_VERSION" \
    org.opencontainers.image.url='https://github.com/freinold/gliner-api/pkgs/container/gliner-api-gpu' \
    org.opencontainers.image.documentation='https://github.com/freinold/gliner-api/README.md' \
    org.opencontainers.image.source='https://github.com/freinold/gliner-api' \
    org.opencontainers.image.licenses='MIT' \
    org.opencontainers.image.title='gliner-api' \
    org.opencontainers.image.description='Easily configurable API & frontend providing simple access to dynamic NER models; this image is built for GPU only.'

# Install the project into `/app`
WORKDIR /app

# Create a non-root user and group with UID/GID 1001
RUN groupadd -g 1001 appuser && \
    useradd -m -u 1001 -g appuser appuser

# Set cache directory for Huggingface Models and set ownership to appuser
RUN mkdir -p /app/huggingface && chown -R appuser:appuser /app/huggingface
ENV HF_HOME=/app/huggingface

# Copy the application files from the builder stage
COPY --from=builder --chown=appuser:appuser /app /app

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Disable tqdm for cleaner logs
ENV TQDM_DISABLE=1
ENV HF_HUB_DISABLE_PROGRESS_BARS=1

# Disable python warnings
ENV PYTHONWARNINGS="ignore"

# Switch to non-root user
USER appuser

# Reset the entrypoint, don't invoke `uv`
ENTRYPOINT ["python", "main.py"]

CMD ["--host", "", "--port", "8080"]