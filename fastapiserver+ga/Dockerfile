# =============================================================================
# Dockerfile — Container Blueprint for the FastAPI Application
# =============================================================================
# A Dockerfile is a text file containing a sequence of instructions that Docker
# uses to build a container IMAGE. Think of it as a recipe: each instruction
# adds a new "layer" to the image. Once built, the image can be run as a
# container on any machine that has Docker installed.
#
# We use Docker to ensure the application runs identically everywhere —
# no more "it works on my machine" problems.
# =============================================================================

# ---- STEP 1: Base Image ----------------------------------------------------
# FROM specifies the base (parent) image to build upon.
# 'ubuntu' pulls the official Ubuntu Linux image from Docker Hub.
# Every Docker image starts from a base; here we use a full Ubuntu OS so we
# can install Python and other system packages via apt.
FROM ubuntu

# ---- STEP 2: Update System Packages ----------------------------------------
# RUN executes a command inside the image during the BUILD process.
# 'apt update -y' refreshes the package index so apt knows what's available.
# The '-y' flag auto-confirms prompts (necessary because Docker builds are
# non-interactive — there's no human to type "yes").
RUN apt update -y

# ---- STEP 3: Install Python & Package Manager ------------------------------
# Install three packages:
#   python3     — The Python 3 interpreter to run our FastAPI code
#   python3-pip — pip, the Python package installer (needed by pipenv)
#   pipenv      — A higher-level dependency manager that creates isolated
#                 virtual environments, preventing package conflicts
RUN apt install python3 python3-pip pipenv -y

# ---- STEP 4: Set Working Directory -----------------------------------------
# WORKDIR sets the current directory inside the container for all subsequent
# instructions (RUN, COPY, CMD, etc.). If /app doesn't exist, Docker creates it.
# This is similar to running 'cd /app' in a terminal.
WORKDIR /app

# ---- STEP 5: Copy Application Code -----------------------------------------
# COPY <source> <destination>
# Copies files from the host machine (your computer, or the CI/CD runner)
# into the container's filesystem.
# '.' means "everything in the current build context" (the fastapiserver+ga folder)
# '/app/' is the destination inside the container (our WORKDIR).
# After this, the container has main.py, requirements.txt, etc. at /app/.
COPY . /app/

# ---- STEP 6: Install Python Dependencies -----------------------------------
# Use pipenv to read requirements.txt and install the listed packages
# (fastapi and uvicorn) into a new virtual environment inside the container.
# The '-r' flag tells pipenv to read from a requirements file rather than
# a Pipfile. This keeps our setup simple with a single requirements.txt.
RUN pipenv install -r requirements.txt

# ---- STEP 7: Expose Port ---------------------------------------------------
# EXPOSE is a documentation directive — it tells Docker (and anyone reading
# this Dockerfile) that the application inside the container listens on port 80.
# NOTE: EXPOSE alone does NOT publish the port. You still need to use
# 'docker run -p 80:80' to map the container's port to the host's port.
# Port 80 matches the port we configured in uvicorn.run() in main.py.
EXPOSE 80

# ---- STEP 8: Container Startup Command -------------------------------------
# CMD defines the DEFAULT command that runs when a container starts.
# 'pipenv run' activates the virtual environment, then executes 'python3 ./main.py'.
# This launches our FastAPI server via uvicorn (see main.py's __main__ block).
#
# KEY DIFFERENCE: RUN vs CMD
#   RUN  → Executes during IMAGE BUILD (e.g., installing packages)
#   CMD  → Executes when a CONTAINER STARTS from the built image
CMD pipenv run python3 ./main.py
