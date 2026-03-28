-- =============================================================================
-- DATABASE INITIALIZATION SCRIPT — init.sql
-- =============================================================================
-- This SQL script runs automatically when the PostgreSQL container starts
-- for the FIRST TIME (via Docker's /docker-entrypoint-initdb.d/ mechanism).
--
-- PURPOSE:
--   1. Create the 'users' table that the FastAPI backend expects
--   2. Insert a default admin user as seed data for testing
--
-- NOTE: 'IF NOT EXISTS' and 'ON CONFLICT DO NOTHING' make this script
--       idempotent — it can run multiple times without causing errors.
-- =============================================================================

-- Create the 'users' table if it doesn't already exist.
-- This table stores all user records for the application.
CREATE TABLE IF NOT EXISTS users (

    -- 'id' is the primary key — a unique identifier for each user.
    -- SERIAL means PostgreSQL auto-increments this value (1, 2, 3, ...).
    id SERIAL PRIMARY KEY,

    -- 'name' stores the user's display name.
    -- VARCHAR(100) limits the name to 100 characters maximum.
    -- NOT NULL means this field is required (cannot be empty).
    name VARCHAR(100) NOT NULL,

    -- 'email' stores the user's email address.
    -- UNIQUE constraint ensures no two users can have the same email.
    -- NOT NULL means an email must always be provided.
    email VARCHAR(100) UNIQUE NOT NULL
);

-- Insert a default admin user into the table for initial testing.
-- ON CONFLICT DO NOTHING: If a user with this email already exists,
-- skip the insert silently instead of throwing a duplicate key error.
-- This makes the script safe to run multiple times.
INSERT INTO users (name, email) VALUES ('Admin User', 'admin@example.com') ON CONFLICT DO NOTHING;
