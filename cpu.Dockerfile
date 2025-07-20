# Use a full image with uv pre-installed as builder
FROM ghcr.io/astral-sh/uv:python3.12-bookworm@sha256:f0c6a5d0e44fe3d28a76ae82de09ee07b8e1cc6d6b7a5e73ca2f5129df8c001d AS builder

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

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Copy the application files into the container
COPY . /app

# Install the dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-dev --extra cpu --extra frontend

# Use slim image as runner
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim@sha256:0fb89926774269712edaeedd8f4939d384b4ddee3fe303fc8a5d6cdd58d96b2c AS runner

# Metadata for the image
ARG IMAGE_CREATED="unknown"
ARG IMAGE_REVISION="unknown"
ARG IMAGE_VERSION="unknown"
LABEL org.opencontainers.image.authors='Fabian Reinold <contact@freinold.eu>' \
    org.opencontainers.image.vendor='Fabian Reinold' \
    org.opencontainers.image.created="$IMAGE_CREATED" \
    org.opencontainers.image.revision="$IMAGE_REVISION" \
    org.opencontainers.image.version="$IMAGE_VERSION" \
    org.opencontainers.image.url='https://github.com/freinold/gliner-api/pkgs/container/gliner-api' \
    org.opencontainers.image.documentation='https://github.com/freinold/gliner-api/README.md' \
    org.opencontainers.image.source='https://github.com/freinold/gliner-api' \
    org.opencontainers.image.licenses='MIT' \
    org.opencontainers.image.title='gliner-api' \
    org.opencontainers.image.description='A minimal FastAPI app serving GLiNER models; this image is built for CPU only.'

# Install the project into `/app`
WORKDIR /app

# Nur das, was du wirklich brauchst, übernehmen:
COPY --from=builder /app /app
COPY --from=builder /app/.venv /app/.venv

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Create a non-root user and group with UID/GID 1000
RUN groupadd -g 1000 appuser && \
    useradd -m -u 1000 -g appuser appuser

# Set cache directory for Huggingface Models and set ownership to appuser
RUN mkdir -p /app/huggingface && chown -R appuser:appuser /app/huggingface
ENV HF_HOME=/app/huggingface

# Disable tqdm for cleaner logs
ENV TQDM_DISABLE=1
ENV HF_HUB_DISABLE_PROGRESS_BARS=1

# Disable python warnings
ENV PYTHONWARNINGS="ignore"

# Switch to non-root user
USER appuser

# Reset the entrypoint, don't invoke `uv`
ENTRYPOINT ["python", "main.py"]

CMD ["--host", "0.0.0.0", "--port", "8080"]