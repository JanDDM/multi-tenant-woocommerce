import mysql.connector
import os, yaml, subprocess

# DB Connection
db = mysql.connector.connect(
    host="mysql.db.svc.cluster.local",
    user="root",
    password="Genoras_20@25!/",
    database="platform_config"
)
cursor = db.cursor(dictionary=True)

# Fetch tenants + plan configs
cursor.execute("""
    SELECT t.*, p.cpu, p.memory, p.storage, p.plugins, p.features
    FROM tenants t
    JOIN plans p ON t.plan_id = p.plan_id
""")
tenants = cursor.fetchall()

# For each tenant, create values.yaml
for tenant in tenants:
    values = {
        "tenant": {
            "name": tenant["tenant_name"],
            "domain": tenant["domain"],
            "location": tenant["location"]
        },
        "resources": {
            "limits": {
                "cpu": tenant["cpu"],
                "memory": tenant["memory"]
            },
            "requests": {
                "storage": tenant["storage"]
            }
        },
        "database": {
            "host": "mysql.db.svc.cluster.local",
            "name": tenant["db_name"],
            "user": tenant["db_user"],
            "password": tenant["db_password"]
        },
        "plugins": tenant["plugins"],
        "preferences": tenant["preferences"]
    }

    # Write tenant values.yaml
    tenant_dir = f"tenants/{tenant['tenant_name']}"
    os.makedirs(tenant_dir, exist_ok=True)
    with open(f"{tenant_dir}/values.yaml", "w") as f:
        yaml.dump(values, f)

# Commit + push to GitHub
subprocess.run(["git", "add", "."])
subprocess.run(["git", "commit", "-m", "Update tenant configs"])
subprocess.run(["git", "push"])
