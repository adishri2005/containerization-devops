# =============================================================================
# FASTAPI BACKEND APPLICATION — main.py (Copy in backend/backend/)
# =============================================================================
# This is the main entry point for the backend REST API server.
# It uses FastAPI (a modern Python web framework) to define HTTP endpoints,
# and SQLAlchemy (an ORM — Object Relational Mapper) to interact with the
# PostgreSQL database without writing raw SQL queries.
#
# The application provides the following REST API endpoints:
#   GET  /         → Returns a welcome message (health check)
#   POST /users/   → Creates a new user in the database
#   GET  /users/   → Retrieves a paginated list of users from the database
# =============================================================================

# --- IMPORTS -----------------------------------------------------------------

# FastAPI: The web framework that handles HTTP requests and responses
# HTTPException: Used to return HTTP error responses (e.g., 400 Bad Request)
# Depends: Dependency injection — automatically provides resources (like DB sessions) to endpoints
from fastapi import FastAPI, HTTPException, Depends

# SQLAlchemy components for database interaction:
# create_engine: Creates the connection pool to the database
# Column, Integer, String: Define table columns and their data types
from sqlalchemy import create_engine, Column, Integer, String

# sessionmaker: Factory for creating database session objects
# Session: Type hint for database sessions
from sqlalchemy.orm import sessionmaker, Session

# declarative_base: Base class that our database models (tables) inherit from
from sqlalchemy.ext.declarative import declarative_base

# os module: Used to read environment variables for configuration
import os

#ADITYA SHRIVASTAVA R2142231558 BATCH 4 CCVT 6th Semester 3rd Year

# --- DATABASE CONFIGURATION --------------------------------------------------

# Read the database connection URL from environment variables.
# If DATABASE_URL is not set (e.g., during local development), fall back to the default.
# The URL format is: postgresql://username:password@hostname:port/database_name
# In Docker, 'db' resolves to the database container's IP via Docker's DNS.
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:password@db:5432/webapp")

# create_engine() establishes a connection pool to the PostgreSQL database.
# A connection pool reuses database connections instead of creating a new one
# for every request, which significantly improves performance.
engine = create_engine(DATABASE_URL)

# sessionmaker() creates a factory for producing database sessions.
# A session represents a "conversation" with the database — it tracks changes
# and commits them as a transaction.
# autocommit=False: We manually control when changes are saved (committed)
# autoflush=False: Don't automatically sync in-memory changes to the DB before queries
# bind=engine: Associate sessions with our database connection pool
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# declarative_base() returns a base class that all our ORM models inherit from.
# It keeps track of all model classes and their table mappings.
Base = declarative_base()

# --- DATABASE MODEL ----------------------------------------------------------

# The User class is an ORM model — it maps to the 'users' table in PostgreSQL.
# Each instance of User represents a single row in the table.
# SQLAlchemy automatically translates operations on User objects into SQL queries.
class User(Base):   
    __tablename__ = "users"  # Name of the table in the database

    # Column definitions — each maps to a column in the 'users' table:
    # id: Auto-incrementing primary key (unique identifier for each user)
    id = Column(Integer, primary_key=True, index=True)

    # name: The user's display name, indexed for faster lookups
    name = Column(String, index=True)

    # email: The user's email address, must be unique across all users
    # 'unique=True' prevents duplicate email registrations at the database level
    email = Column(String, unique=True, index=True)

# --- FASTAPI APPLICATION INSTANCE --------------------------------------------

# Create the FastAPI application instance.
# 'title' sets the name shown in the auto-generated API documentation at /docs
app = FastAPI(title="Backend API") 

# --- DEPENDENCY: DATABASE SESSION --------------------------------------------

# This is a dependency function used by FastAPI's Depends() system.
# It provides a database session to each API endpoint that needs one,
# and automatically closes the session when the request is done.
# Using 'yield' makes this a generator — code after yield runs as cleanup.
def get_db():
    db = SessionLocal()   # Create a new database session
    try:
        yield db          # Provide the session to the endpoint function
    finally:
        db.close()        # Always close the session when the request finishes
                          # This returns the connection to the pool

# --- API ENDPOINTS -----------------------------------------------------------

# ROOT ENDPOINT — GET /
# A simple health check endpoint that returns a welcome message.
# Useful for verifying that the backend server is running.
@app.get("/")
def read_root():
    return {"message": "Welcome to the FastAPI Backend Server!"}


# CREATE USER ENDPOINT — POST /users/
# Accepts 'name' and 'email' as query parameters and creates a new user.
# The 'db' parameter is auto-injected by FastAPI's dependency injection (Depends).
@app.post("/users/")
def create_user(name: str, email: str, db: Session = Depends(get_db)):
    # First, check if a user with this email already exists in the database
    user = db.query(User).filter(User.email == email).first()
    if user:
        # If email already exists, return a 400 Bad Request error
        raise HTTPException(status_code=400, detail="Email already registered")

    # Create a new User object with the provided name and email
    new_user = User(name=name, email=email)

    db.add(new_user)       # Stage the new user for insertion into the database
    db.commit()            # Commit the transaction — actually writes to the database
    db.refresh(new_user)   # Refresh the object to get the auto-generated id from the DB

    return new_user        # Return the created user (FastAPI auto-serializes to JSON)


# LIST USERS ENDPOINT — GET /users/
# Returns a paginated list of users from the database.
# 'skip' and 'limit' parameters enable pagination:
#   skip: Number of records to skip from the start (default: 0)
#   limit: Maximum number of records to return (default: 10)
@app.get("/users/")
def read_users(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    # Query all users with pagination using offset (skip) and limit
    users = db.query(User).offset(skip).limit(limit).all()
    return users  # Return the list of users as JSON