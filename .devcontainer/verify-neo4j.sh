#!/bin/bash
# Verify Neo4j, GDS, and APOC are working correctly

echo "Testing Neo4j connection and plugins..."

# Wait for Neo4j to be fully ready
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if wget --quiet --tries=1 --spider http://neo4j:7474 2>/dev/null; then
        break
    fi
    attempt=$((attempt + 1))
    sleep 2
done

# Test connection with Python
python3 << 'EOF'
import sys
import time
from neo4j import GraphDatabase

uri = "bolt://neo4j:7687"
auth = ("neo4j", "workshoppassword")

print("\n" + "="*50)
print("Neo4j Workshop Environment Verification")
print("="*50 + "\n")

# Test basic connection
try:
    driver = GraphDatabase.driver(uri, auth=auth)
    with driver.session() as session:
        result = session.run("RETURN 'Connection successful!' as message")
        record = result.single()
        print(f"✓ Neo4j Connection: {record['message']}")
except Exception as e:
    print(f"✗ Neo4j Connection Failed: {e}")
    sys.exit(1)

# Test APOC
try:
    with driver.session() as session:
        result = session.run("RETURN apoc.version() as version")
        record = result.single()
        print(f"✓ APOC Plugin: v{record['version']}")
except Exception as e:
    print(f"✗ APOC Plugin: Not available - {e}")
    sys.exit(1)

# Test GDS
try:
    with driver.session() as session:
        result = session.run("RETURN gds.version() as version")
        record = result.single()
        print(f"✓ GDS Plugin: v{record['version']}")
except Exception as e:
    print(f"✗ GDS Plugin: Not available - {e}")
    sys.exit(1)

# Test APOC function used in notebooks
try:
    with driver.session() as session:
        result = session.run("RETURN apoc.convert.fromJsonList('[1,2,3]') as test")
        record = result.single()
        print(f"✓ APOC JSON Functions: Working")
except Exception as e:
    print(f"✗ APOC JSON Functions: {e}")
    sys.exit(1)

driver.close()

print("\n" + "="*50)
print("All checks passed! Environment is ready.")
print("="*50 + "\n")
EOF

