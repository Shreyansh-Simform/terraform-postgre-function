import azure.functions as func
import json
import logging
import os
import re
import psycopg2
from psycopg2 import sql, pool
from typing import Optional

# Global connection pool
_connection_pool = None

def get_connection_pool():
    """Get or create PostgreSQL connection pool"""
    global _connection_pool
    if _connection_pool is None:
        try:
            _connection_pool = psycopg2.pool.SimpleConnectionPool(
                1, 5,  # min and max connections
                host=os.environ["PGHOST"],
                database=os.environ["PGDATABASE"],
                user=os.environ["PGUSER"],
                password=os.environ["PGPASSWORD"],
                port=5432
            )
            logging.info("Connection pool created successfully")
        except Exception as e:
            logging.error(f"Failed to create connection pool: {e}")
            raise
    return _connection_pool

def validate_username(username: str) -> bool:
    """Validate PostgreSQL username format"""
    if not username or len(username) < 2 or len(username) > 63:
        return False
    # PostgreSQL username rules: alphanumeric, underscore, start with letter or underscore
    return re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', username) is not None

def validate_password(password: str) -> bool:
    """Validate password strength"""
    if not password or len(password) < 8:
        return False
    # At least one uppercase, one lowercase, one digit, one special character
    return (re.search(r'[A-Z]', password) and 
            re.search(r'[a-z]', password) and 
            re.search(r'\d', password) and 
            re.search(r'[!@#$%^&*(),.?":{}|<>]', password))

def user_exists(cursor, username: str) -> bool:
    """Check if user already exists in PostgreSQL"""
    cursor.execute(
        "SELECT 1 FROM pg_user WHERE usename = %s",
        (username,)
    )
    return cursor.fetchone() is not None

def create_postgresql_user(username: str, password: str, privileges: Optional[str] = None) -> dict:
    """Create PostgreSQL user with specified privileges"""
    conn = None
    cursor = None
    
    try:
        # Get connection from pool
        pool = get_connection_pool()
        conn = pool.getconn()
        
        if conn is None:
            raise Exception("Failed to get connection from pool")
        
        # Set autocommit to False for transaction control
        conn.autocommit = False
        cursor = conn.cursor()
        
        # Check if user already exists
        if user_exists(cursor, username):
            return {
                "success": False,
                "message": f"User '{username}' already exists",
                "status_code": 409
            }
        
        # Create user with password
        cursor.execute(
            sql.SQL("CREATE USER {} WITH PASSWORD %s").format(sql.Identifier(username)),
            (password,)
        )
        
        # Grant privileges based on request or default
        database_name = os.environ["PGDATABASE"]
        
        if privileges == "readonly":
            cursor.execute(
                sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(
                    sql.Identifier(database_name), sql.Identifier(username)
                )
            )
            cursor.execute(
                sql.SQL("GRANT USAGE ON SCHEMA public TO {}").format(sql.Identifier(username))
            )
            cursor.execute(
                sql.SQL("GRANT SELECT ON ALL TABLES IN SCHEMA public TO {}").format(sql.Identifier(username))
            )
        elif privileges == "readwrite":
            cursor.execute(
                sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(
                    sql.Identifier(database_name), sql.Identifier(username)
                )
            )
            cursor.execute(
                sql.SQL("GRANT USAGE, CREATE ON SCHEMA public TO {}").format(sql.Identifier(username))
            )
            cursor.execute(
                sql.SQL("GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {}").format(sql.Identifier(username))
            )
        else:
            # Default: full privileges on database
            cursor.execute(
                sql.SQL("GRANT ALL PRIVILEGES ON DATABASE {} TO {}").format(
                    sql.Identifier(database_name), sql.Identifier(username)
                )
            )
        
        # Commit the transaction
        conn.commit()
        
        return {
            "success": True,
            "message": f"User '{username}' created successfully with {privileges or 'full'} privileges",
            "status_code": 201
        }
        
    except psycopg2.Error as e:
        # Rollback on database error
        if conn:
            try:
                conn.rollback()
            except:
                pass
        logging.error(f"PostgreSQL error: {e}")
        return {
            "success": False,
            "message": f"Database error: {str(e)}",
            "status_code": 500
        }
    except Exception as e:
        # Rollback on any error
        if conn:
            try:
                conn.rollback()
            except:
                pass
        logging.error(f"Unexpected error: {e}")
        return {
            "success": False,
            "message": f"Unexpected error: {str(e)}",
            "status_code": 500
        }
    finally:
        # Clean up resources
        if cursor:
            try:
                cursor.close()
            except:
                pass
        
        # Return connection to pool only if it's healthy
        if conn:
            try:
                # Check if connection is still valid
                if conn.closed == 0:  # 0 means connection is open
                    pool.putconn(conn)
                else:
                    logging.warning("Connection was closed, not returning to pool")
            except Exception as e:
                logging.error(f"Error handling connection cleanup: {e}")

def main(req: func.HttpRequest) -> func.HttpResponse:
    """Main function handler for PostgreSQL user creation"""
    logging.info('PostgreSQL user creation function processed a request.')
    
    try:
        # Get request body
        req_body = req.get_json()
        
        if not req_body:
            return func.HttpResponse(
                json.dumps({
                    "error": "Request body is required",
                    "required_fields": ["username", "password", "privileges"]
                }),
                status_code=400,
                mimetype="application/json"
            )
        
        # Extract parameters
        username = req_body.get('username')
        password = req_body.get('password')
        privileges = req_body.get('privileges', 'readonly')  # Default to readonly
        
        # Validate required parameters
        if not username or not password:
            return func.HttpResponse(
                json.dumps({
                    "error": "Missing required parameters",
                    "required": ["username", "password"],
                    "optional": ["privileges"]
                }),
                status_code=400,
                mimetype="application/json"
            )
        
        # Validate privileges
        valid_privileges = ['readonly', 'readwrite', 'full']
        if privileges not in valid_privileges:
            return func.HttpResponse(
                json.dumps({
                    "error": f"Invalid privileges. Must be one of: {valid_privileges}",
                    "provided": privileges
                }),
                status_code=400,
                mimetype="application/json"
            )
        
        # Create the user
        result = create_postgresql_user(username, password, privileges)
        
        # Return appropriate response
        if result["success"]:
            return func.HttpResponse(
                json.dumps({
                    "success": True,
                    "message": result["message"],
                    "username": username,
                    "privileges": privileges
                }),
                status_code=result["status_code"],
                mimetype="application/json"
            )
        else:
            return func.HttpResponse(
                json.dumps({
                    "success": False,
                    "message": result["message"]
                }),
                status_code=result["status_code"],
                mimetype="application/json"
            )
            
    except ValueError as e:
        # JSON parsing error
        logging.error(f"JSON parsing error: {e}")
        return func.HttpResponse(
            json.dumps({
                "error": "Invalid JSON in request body",
                "details": str(e)
            }),
            status_code=400,
            mimetype="application/json"
        )
    except Exception as e:
        # Unexpected error
        logging.error(f"Unexpected error in main function: {e}")
        return func.HttpResponse(
            json.dumps({
                "error": "Internal server error",
                "details": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )

