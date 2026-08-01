import sys
import os

# Add project root to Python path so `backend.*` imports work
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
# Also add backend/ itself, since modules inside backend use absolute
# imports like `from config.settings import settings` (as they do when
# run via `uvicorn main:app` from within backend/).
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))
