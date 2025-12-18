from flask import Flask
import pymysql
import os

app = Flask(__name__)

def get_db_connection():
    return pymysql.connect(
        host=os.environ.get('DB_HOST'),
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASSWORD'),
        database=os.environ.get('DB_NAME'),
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=5
    )

@app.route('/')
def hello_world():
    db_host = os.environ.get('DB_HOST')
    
    # Fallback if environment variables aren't set yet
    if not db_host:
        return '<h1>Hello! (Database not configured)</h1>'
        
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            # Create table if not exists
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS page_hits (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    hit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            # Record a hit
            cursor.execute("INSERT INTO page_hits VALUES (NULL, NOW())")
            # Count hits
            cursor.execute("SELECT COUNT(*) as count FROM page_hits")
            result = cursor.fetchone()
            hit_count = result['count']
            
        connection.commit()
        connection.close()
        return f'<h1>Hello! This page has been visited {hit_count} times!</h1><p>Connected to: {db_host}</p>'
        
    except Exception as e:
        return f'<h1>DB Connection Error</h1><p>{str(e)}</p>'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
