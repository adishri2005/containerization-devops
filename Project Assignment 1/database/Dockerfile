FROM postgres:15-alpine

# Copy initialization script to the directory Postgres checks on startup
# The script will run automatically when the database is initialized for the first time
COPY init.sql /docker-entrypoint-initdb.d/

# Ensure appropriate permissions for the file
RUN chmod a+r /docker-entrypoint-initdb.d/init.sql
