# =============================================================================
# main.py — FastAPI Application Entry Point
# =============================================================================
# This file defines a lightweight REST API using the FastAPI framework.
# FastAPI is a modern, high-performance Python web framework that automatically
# generates OpenAPI (Swagger) documentation and validates request/response data.
# =============================================================================

# --- Import Section ----------------------------------------------------------

# Import the FastAPI class from the 'fastapi' package.
# FastAPI is built on top of Starlette (for web routing) and Pydantic (for
# data validation). It lets us define API endpoints using simple Python functions.
from fastapi import FastAPI

# Import uvicorn — an ASGI (Asynchronous Server Gateway Interface) server.
# ASGI is the modern successor to WSGI; it supports asynchronous request handling.
# Uvicorn is the recommended production server for FastAPI applications.
import uvicorn

# --- Application Instance ----------------------------------------------------

# Create an instance of the FastAPI class.
# This 'app' object is the core of the entire application — every route (endpoint)
# we define below is registered on this object. When a request comes in, FastAPI
# uses this object to match the URL to the correct handler function.
app = FastAPI()

# =============================================================================
# ROUTE 1 — Root Endpoint (GET /)
# =============================================================================
# The '@app.get("/")' decorator registers the function below as the handler
# for HTTP GET requests to the root URL path "/".
#
# Decorators in Python are functions that wrap other functions to add behavior.
# Here, '@app.get' tells FastAPI: "When someone sends a GET request to '/',
# call the 'read_root()' function and return its result as the HTTP response."
#
# FastAPI automatically serializes the returned Python dictionary to JSON.
# So the browser/client will receive:
#   {"name": "Aditya Shrivastava", "sapid": "500124727", "Location": "Dehradun"}
# =============================================================================
@app.get("/")
def read_root():
    # Return a dictionary with personal identification details.
    # FastAPI converts this dict → JSON automatically (via its JSONResponse).
    return dict(
        name="Aditya Shrivastava",    # Student name
        sapid="500124727",             # SAP ID (university identifier)
        Location="Dehradun"            # Current location / campus city
    )

# =============================================================================
# ROUTE 2 — Dynamic Path Parameter Endpoint (GET /{data})
# =============================================================================
# This route uses a *path parameter* — the '{data}' part in the URL is a
# variable. Whatever the user types after the slash becomes the value of 'data'.
#
# Example:
#   GET /hello   → data = "hello"  → returns {"hi": "hello", "Location": "Dehradun"}
#   GET /world   → data = "world"  → returns {"hi": "world", "Location": "Dehradun"}
#
# Path parameters let us build dynamic endpoints that respond differently
# based on the URL, without needing to create a separate route for each value.
#
# FastAPI also auto-generates documentation (at /docs) showing this parameter.
# =============================================================================
@app.get("/{data}")
def read_data(data):
    # 'data' is automatically extracted from the URL path by FastAPI.
    # We echo it back in the response along with a static Location field.
    return dict(hi=data, Location="Dehradun")

# =============================================================================
# APPLICATION ENTRY POINT
# =============================================================================
# The block below runs ONLY when this file is executed directly
# (e.g., 'python3 main.py'). It does NOT run when the file is imported as
# a module by another script.
#
# __name__ is a special Python variable:
#   - When you run 'python3 main.py', __name__ is set to "__main__"
#   - When another file does 'import main', __name__ is set to "main"
#
# uvicorn.run() starts the ASGI server with the following parameters:
#   "main:app"  → Tells uvicorn: in the file 'main.py', use the object 'app'
#   host="0.0.0.0" → Listen on ALL network interfaces (not just localhost).
#                     This is essential inside Docker containers so that
#                     requests from outside the container can reach the server.
#   port=80     → Listen on port 80 (the default HTTP port).
#                  This matches the EXPOSE directive in the Dockerfile.
#   reload=True → Auto-restart the server when code changes are detected.
#                  Useful during development; in production you'd set this False.
# =============================================================================
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=80, reload=True)
