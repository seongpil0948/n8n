-- volumes/db/init-n8n.sql
\set pgpass `echo "$POSTGRES_PASSWORD"`

-- Create n8n database and user
CREATE DATABASE n8n;
CREATE USER n8n_user WITH ENCRYPTED PASSWORD :'pgpass';
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;

-- Connect to n8n database
\c n8n

-- Create schema and grant permissions
CREATE SCHEMA IF NOT EXISTS n8n AUTHORIZATION n8n_user;
GRANT ALL ON SCHEMA n8n TO n8n_user;
ALTER USER n8n_user SET search_path TO n8n, public;