mongodump --host 127.0.0.1 --port 27017 -o /etc/backup/myback
mongorestore --host 127.0.0.1 --port 27017 /etc/backup/myback/databa
pg_dump DB_NAME > postgres_DB_NAME_bak.sql
psql --set ON_ERROR_STOP=1 --single-transaction < postgres_DB_NAME_bak.sql