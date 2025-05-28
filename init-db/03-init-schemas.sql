-- 03-init-schemas.sql
-- Create all necessary schemas

-- Supabase core schemas
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS supabase_functions;
CREATE SCHEMA IF NOT EXISTS _realtime;

-- Vector store schema
CREATE SCHEMA IF NOT EXISTS vector_store;

-- Set schema ownership
ALTER SCHEMA auth OWNER TO supabase_auth_admin;
ALTER SCHEMA storage OWNER TO supabase_storage_admin;
ALTER SCHEMA supabase_functions OWNER TO supabase_functions_admin;
ALTER SCHEMA _realtime OWNER TO supabase_admin;
ALTER SCHEMA vector_store OWNER TO postgres;

-- Grant schema permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role, n8n_user;
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA storage TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA vector_store TO anon, authenticated, service_role;

-- Grant table permissions on public schema
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Default privileges for public schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;

-- Default privileges for vector_store schema
ALTER DEFAULT PRIVILEGES IN SCHEMA vector_store GRANT ALL ON TABLES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vector_store GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA vector_store GRANT ALL ON SEQUENCES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vector_store GRANT ALL ON FUNCTIONS TO authenticated, service_role;

-- Log completion
DO $$ BEGIN RAISE NOTICE 'Schemas initialization completed'; END $$;