-- 00-init-roles.sql
-- Create all necessary roles with proper error handling

-- Get password from environment
\set pgpass `echo "$POSTGRES_PASSWORD"`
\set n8npass `echo "$N8N_DB_PASSWORD"`

-- Create base roles using DO block for proper error handling
DO $$
DECLARE
    pwd text := :'pgpass';
    n8n_pwd text := :'n8npass';
BEGIN
    -- Base roles
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
        RAISE NOTICE 'Created role: anon';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN;
        RAISE NOTICE 'Created role: authenticated';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN BYPASSRLS;
        RAISE NOTICE 'Created role: service_role';
    END IF;
    
    -- Admin roles with passwords
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticator') THEN
        EXECUTE format('CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD %L', pwd);
        RAISE NOTICE 'Created role: authenticator';
    ELSE
        EXECUTE format('ALTER ROLE authenticator WITH PASSWORD %L', pwd);
        RAISE NOTICE 'Updated password for: authenticator';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        EXECUTE format('CREATE ROLE supabase_admin BYPASSRLS NOINHERIT CREATEROLE LOGIN PASSWORD %L', pwd);
        RAISE NOTICE 'Created role: supabase_admin';
    ELSE
        EXECUTE format('ALTER ROLE supabase_admin WITH PASSWORD %L', pwd);
        RAISE NOTICE 'Updated password for: supabase_admin';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
        EXECUTE format('CREATE ROLE supabase_auth_admin NOINHERIT CREATEROLE LOGIN PASSWORD %L', pwd);
        RAISE NOTICE 'Created role: supabase_auth_admin';
    ELSE
        EXECUTE format('ALTER ROLE supabase_auth_admin WITH PASSWORD %L', pwd);
        RAISE NOTICE 'Updated password for: supabase_auth_admin';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        EXECUTE format('CREATE ROLE supabase_storage_admin NOINHERIT CREATEROLE LOGIN PASSWORD %L', pwd);
        RAISE NOTICE 'Created role: supabase_storage_admin';
    ELSE
        EXECUTE format('ALTER ROLE supabase_storage_admin WITH PASSWORD %L', pwd);
        RAISE NOTICE 'Updated password for: supabase_storage_admin';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_functions_admin') THEN
        EXECUTE format('CREATE ROLE supabase_functions_admin NOINHERIT CREATEROLE LOGIN PASSWORD %L', pwd);
        RAISE NOTICE 'Created role: supabase_functions_admin';
    ELSE
        EXECUTE format('ALTER ROLE supabase_functions_admin WITH PASSWORD %L', pwd);
        RAISE NOTICE 'Updated password for: supabase_functions_admin';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_replication_admin') THEN
        EXECUTE format('CREATE ROLE supabase_replication_admin LOGIN REPLICATION PASSWORD %L', pwd);
        RAISE NOTICE 'Created role: supabase_replication_admin';
    ELSE
        EXECUTE format('ALTER ROLE supabase_replication_admin WITH PASSWORD %L', pwd);
        RAISE NOTICE 'Updated password for: supabase_replication_admin';
    END IF;
    
    -- n8n user with its own password
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'n8n_user') THEN
        EXECUTE format('CREATE ROLE n8n_user LOGIN PASSWORD %L', n8n_pwd);
        RAISE NOTICE 'Created role: n8n_user';
    ELSE
        EXECUTE format('ALTER ROLE n8n_user WITH PASSWORD %L', n8n_pwd);
        RAISE NOTICE 'Updated password for: n8n_user';
    END IF;
    
    -- pgbouncer for connection pooling
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pgbouncer') THEN
        EXECUTE format('CREATE ROLE pgbouncer LOGIN PASSWORD %L', pwd);
        RAISE NOTICE 'Created role: pgbouncer';
    ELSE
        EXECUTE format('ALTER ROLE pgbouncer WITH PASSWORD %L', pwd);
        RAISE NOTICE 'Updated password for: pgbouncer';
    END IF;
END $$;

-- Grant base roles to authenticator
GRANT anon TO authenticator;
GRANT authenticated TO authenticator;
GRANT service_role TO authenticator;

-- Grant all admin roles to postgres
GRANT supabase_admin TO postgres;
GRANT supabase_auth_admin TO postgres;
GRANT supabase_storage_admin TO postgres;
GRANT supabase_functions_admin TO postgres;

-- Grant base roles to supabase_admin
GRANT anon TO supabase_admin;
GRANT authenticated TO supabase_admin;
GRANT service_role TO supabase_admin;

-- Log completion
DO $$ BEGIN RAISE NOTICE 'Roles initialization completed successfully'; END $$;