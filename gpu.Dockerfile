# Use a NVIDIA CUDA development image as builder
FROM nvidia/cuda:13.1.1-cudnn-devel-ubuntu24.04@sha256:ef8a68702fdc93f3acb12919cde4468b9df0aeea214c1c97bf57598dad558967 AS builder

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
COPY --from=ghcr.io/astral-sh/uv:latest@sha256:9a23023be68b2ed09750ae636228e903a54a05ea56ed03a934d00fe9fbeded4b /uv /bin/

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
FROM docker.io/nvidia/cuda:13.1.1-cudnn-runtime-ubuntu24.04@sha256:bcc2ddb358d2a64ee3379b184ea3bc46a0926f1b1ec63df136ba61cd4d85f30d AS runner

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