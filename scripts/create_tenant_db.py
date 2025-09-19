import mysql.connector
import os, yaml, subprocess

# --------------------------
# DB Connection
# --------------------------
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Genoras_20@25!/",
    database="platform_config"
)
cursor = db.cursor(dictionary=True)


# Fetch tenants with no DB assigned yet
cursor.execute("SELECT * FROM tenants WHERE db_name IS NULL")
new_tenants = cursor.fetchall()

for tenant in new_tenants:
    tenant_id = tenant["tenant_id"]

    # Generate DB name, user, and password
    db_name = f"tenant_{tenant_id}"
    db_user = f"tenant_{tenant_id}_user"
    db_password = ''.join(secrets.choice(string.ascii_letters + string.digits) for i in range(16))

    # Create DB and user in MySQL
    admin = db.cursor()
    admin.execute(f"CREATE DATABASE {db_name};")
    admin.execute(f"CREATE USER '{db_user}'@'%' IDENTIFIED BY '{db_password}';")
    admin.execute(f"GRANT ALL PRIVILEGES ON {db_name}.* TO '{db_user}'@'%';")
    admin.execute("FLUSH PRIVILEGES;")

    # Save back to tenants table
    cursor.execute("""
        UPDATE tenants 
        SET db_name=%s, db_user=%s, db_password=%s 
        WHERE tenant_id=%s
    """, (db_name, db_user, db_password, tenant_id))
    db.commit()

    print(f"✅ Created DB for tenant {tenant['tenant_name']} -> {db_name}")

cursor.close()
db.close()
