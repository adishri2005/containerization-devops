# =============================================================================
# DATABASE DOCKERFILE — PostgreSQL Initialization
# =============================================================================
# This Dockerfile creates a custom PostgreSQL database image.
# It extends the official postgres:15-alpine image (a lightweight version
# of PostgreSQL 15 built on Alpine Linux for a smaller image size).
#
# PURPOSE:
#   The main reason we use a custom Dockerfile instead of the plain postgres
#   image is to include our init.sql script. This script automatically creates
#   the required database tables and inserts seed data when the database
#   container starts for the FIRST TIME.
# =============================================================================

# Use the official PostgreSQL 15 image built on Alpine Linux.
# Alpine is a minimal Linux distribution (~5MB), making the final image very small.
# This image comes with PostgreSQL pre-installed and pre-configured.
FROM postgres:15-alpine

# Copy our SQL initialization script into the special docker-entrypoint-initdb.d/ directory.
# PostgreSQL's official Docker image is designed to automatically execute any
# .sql, .sql.gz, or .sh files placed in /docker-entrypoint-initdb.d/ when the
# database is initialized for the FIRST TIME (i.e., when the data volume is empty).
# This means our init.sql will run automatically to create tables and seed data.
# NOTE: This script does NOT run on subsequent container restarts if data already exists.
COPY init.sql /docker-entrypoint-initdb.d/

# Set read permissions on the init script so PostgreSQL can execute it.
# 'chmod a+r' grants read access to all users (owner, group, and others).
# This ensures the postgres process inside the container can read and execute the file.
RUN chmod a+r /docker-entrypoint-initdb.d/init.sql
