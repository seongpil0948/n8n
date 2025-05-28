-- 02-init-databases.sql
-- Create necessary databases

-- Create n8n database
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n') THEN
        CREATE DATABASE n8n WITH OWNER n8n_user;
        RAISE NOTICE 'Created database: n8n';
    END IF;
END $$;

-- Create _supabase database for internal use
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '_supabase') THEN
        CREATE DATABASE _supabase WITH OWNER postgres;
        RAISE NOTICE 'Created database: _supabase';
    END IF;
END $$;

-- Grant privileges on n8n database
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;

-- Grant privileges on _supabase database
GRANT ALL PRIVILEGES ON DATABASE _supabase TO supabase_admin;

-- Connect to n8n database and set up
\c n8n

DO $$
BEGIN
    -- Grant schema permissions
    GRANT ALL ON SCHEMA public TO n8n_user;
    GRANT CREATE ON SCHEMA public TO n8n_user;
    
    -- Set default privileges
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO n8n_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO n8n_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO n8n_user;
    
    RAISE NOTICE 'n8n database permissions configured';
END $$;

-- Back to main database
\c postgres

-- Connect to _supabase and create internal schemas
\c _supabase

DO $$
BEGIN
    -- Create analytics schema
    IF NOT EXISTS (SELECT FROM pg_namespace WHERE nspname = '_analytics') THEN
        CREATE SCHEMA _analytics;
        ALTER SCHEMA _analytics OWNER TO supabase_admin;
        RAISE NOTICE 'Created schema: _analytics';
    END IF;
    
    -- Create realtime schema
    IF NOT EXISTS (SELECT FROM pg_namespace WHERE nspname = '_realtime') THEN
        CREATE SCHEMA _realtime;
        ALTER SCHEMA _realtime OWNER TO supabase_admin;
        RAISE NOTICE 'Created schema: _realtime';
    END IF;
    
    -- Grant permissions
    GRANT ALL ON SCHEMA _analytics TO supabase_admin;
    GRANT ALL ON SCHEMA _realtime TO supabase_admin;
END $$;

-- Back to main database
\c postgres

-- Verify database creation
DO $$
DECLARE
    db_count integer;
BEGIN
    SELECT COUNT(*) INTO db_count 
    FROM pg_database 
    WHERE datname IN ('n8n', '_supabase');
    
    IF db_count = 2 THEN
        RAISE NOTICE 'All databases created successfully';
    ELSE
        RAISE EXCEPTION 'Database creation failed';
    END IF;
END $$;

-- Log completion
DO $$ BEGIN RAISE NOTICE 'Databases initialization completed successfully'; END $$;