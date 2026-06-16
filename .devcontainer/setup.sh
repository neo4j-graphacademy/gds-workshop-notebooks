#!/bin/bash
set -e

echo "Setting up Python environment..."
python -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt

echo "Installing Jupyter kernel..."
.venv/bin/python -m ipykernel install --user --name=workshop-gds --display-name="Python (workshop-gds)"

echo "Configuring credentials (.env)..."
if [ ! -f .env ]; then
cat > .env << 'EOF'
# === Local Neo4j - lessons 3.x ===
# Pre-configured for the Neo4j container in this Codespace.
# Reached by its compose service name (the app is no longer bound to neo4j's network).
NEO4J_URI=bolt://neo4j:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=workshoppassword

# === Aura - lessons 4.x ===
# Fill these in with YOUR AuraDB + Aura API details before running the 4.x notebooks.
# Leave blank for the 3.x lessons.
AURA_URI=
AURA_USERNAME=neo4j
AURA_PASSWORD=
AURA_DATABASE=
AURA_CLIENT_ID=
AURA_CLIENT_SECRET=
# Only needed if your Aura account has more than one project.
AURA_PROJECT_ID=
EOF
echo "  Wrote .env (local Neo4j pre-filled; add Aura creds for the 4.x lessons)."
else
echo "  .env already exists - leaving it untouched (preserves any Aura creds you added)."
fi

echo "Waiting for Neo4j to be ready..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if wget --quiet --tries=1 --spider http://neo4j:7474 2>/dev/null; then
        echo "Neo4j is ready!"
        break
    fi
    attempt=$((attempt + 1))
    echo "Waiting for Neo4j... (attempt $attempt/$max_attempts)"
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "Warning: Neo4j may not be fully ready yet. Please wait a moment before running notebooks."
else
    echo "Verifying APOC and GDS plugins..."
    sleep 5  # Give Neo4j a bit more time to fully initialize plugins
    bash .devcontainer/verify-neo4j.sh || echo "Warning: Plugin verification incomplete. Neo4j may still be initializing."
fi

echo "Setup complete!"

