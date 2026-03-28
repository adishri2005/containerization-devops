# =============================================================================
# BACKEND DOCKERFILE — Multi-Stage Build
# =============================================================================
# This Dockerfile uses a MULTI-STAGE BUILD to create a small, secure, production
# image for the FastAPI backend application.
#
# WHY MULTI-STAGE?
#   Stage 1 (builder): Installs heavy build tools (gcc, dev headers) needed to
#                      compile Python packages like psycopg2 from source.
#   Stage 2 (final):   Only copies the compiled packages (wheels) into a clean,
#                      slim image — no build tools included. This results in a
#                      much smaller image size and reduced attack surface.
# =============================================================================

# ===========================
# STAGE 1: BUILD DEPENDENCIES
# ===========================
# Start from a slim Python 3.11 image. The 'AS builder' tag names this stage
# so we can reference it later with COPY --from=builder.
FROM python:3.11-slim AS builder

# Set the working directory inside the container.
# All subsequent commands (COPY, RUN, etc.) will execute relative to /app.
WORKDIR /app

# Install system-level build dependencies required to compile Python packages:
#   - gcc: The GNU C Compiler, needed to compile C extensions (e.g., psycopg2)
#   - libpq-dev: PostgreSQL development headers, needed for psycopg2 to link
#                against the PostgreSQL client library
# --no-install-recommends: Skips optional packages to keep the image smaller
# rm -rf /var/lib/apt/lists/*: Cleans up apt cache to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy only the requirements file first (not the full app code).
# This takes advantage of Docker's layer caching — if requirements.txt hasn't
# changed, Docker reuses the cached layer and skips the slow pip install step.
COPY requirements.txt .

# Build Python packages as wheel files (.whl) — portable, pre-compiled packages.
# --no-cache-dir: Don't store pip's download cache (saves space)
# --no-deps: Don't automatically resolve dependencies (we listed them all in requirements.txt)
# --wheel-dir /app/wheels: Save the built wheels to this directory for the next stage
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# ===================================
# STAGE 2: FINAL PRODUCTION IMAGE
# ===================================
# Start a fresh, clean Python 3.11 slim image (no build tools from Stage 1).
FROM python:3.11-slim

# Set the working directory for the production application
WORKDIR /app

# Install only RUNTIME dependencies (not build tools):
#   - libpq5: The PostgreSQL client library needed at runtime by psycopg2
#             (the -dev version with headers is NOT needed here)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy the pre-built wheel files from Stage 1 (the builder stage).
# This avoids needing gcc/libpq-dev in the final image.
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .

# Install all Python packages from the pre-built wheels.
# --no-cache: Don't store pip cache to keep the image lean
RUN pip install --no-cache /wheels/*

# Copy the entire application source code into the container.
# This includes main.py and any other application files.
COPY . /app

# SECURITY BEST PRACTICE: Create a non-root user and run the app as that user.
# Running as root inside a container is a security risk — if the container is
# compromised, the attacker would have root access. 'appuser' has limited privileges.
RUN useradd -m appuser && chown -R appuser /app
USER appuser

# Document that the container listens on port 8000.
# NOTE: EXPOSE doesn't actually publish the port — it's metadata/documentation.
# The actual port mapping is done in docker-compose.yml with 'ports'.
EXPOSE 8000

# CMD defines the default command to run when the container starts.
# This launches the FastAPI app using Uvicorn (an ASGI server):
#   - "main:app" → import the 'app' object from main.py
#   - "--host 0.0.0.0" → listen on all network interfaces (required in Docker)
#   - "--port 8000" → serve on port 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
