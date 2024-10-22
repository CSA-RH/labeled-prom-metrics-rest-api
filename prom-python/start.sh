#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(realpath "$(dirname "$0")")/../app"

pip install -r "$SCRIPT_DIR/requirements.txt"

# Run the FastAPI app using Uvicorn, specifying the app directory
uvicorn main:app --reload --app-dir "$SCRIPT_DIR"