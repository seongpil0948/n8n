-- 04-init-supabase.sql
-- Initialize Supabase specific functions and settings

-- Set JWT configuration using DO block to handle variable properly
DO $$
DECLARE
    jwt_secret text := current_setting('jwt.secret', true);
    jwt_exp text := current_setting('jwt.exp', true);
BEGIN
    -- Use environment variables if available
    IF jwt_secret IS NOT NULL AND jwt_secret != '' THEN
        EXECUTE format('ALTER DATABASE %I SET "app.settings.jwt_secret" TO %L', current_database(), jwt_secret);
    END IF;
    
    IF jwt_exp IS NOT NULL AND jwt_exp != '' THEN
        EXECUTE format('ALTER DATABASE %I SET "app.settings.jwt_exp" TO %L', current_database(), jwt_exp);
    END IF;
    
    RAISE NOTICE 'JWT configuration set';
END $$;

-- Create auth schema if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
        RAISE NOTICE 'Created schema: auth';
    END IF;
END $$;

-- Set schema ownership
ALTER SCHEMA auth OWNER TO supabase_auth_admin;

-- Create auth schema objects
SET search_path TO auth, public;

-- auth.uid() function - returns current user's ID
CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid;
$$;

-- auth.role() function - returns current user's role
CREATE OR REPLACE FUNCTION auth.role()
RETURNS text
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::json->>'role', '')::text;
$$;

-- auth.email() function - returns current user's email
CREATE OR REPLACE FUNCTION auth.email()
RETURNS text
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::json->>'email', '')::text;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION auth.uid() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION auth.role() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION auth.email() TO anon, authenticated, service_role;

-- Create JWT check function for PostgREST
SET search_path TO public;

CREATE OR REPLACE FUNCTION public.check_jwt()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- This function is called by PostgREST before each request
    -- You can add custom JWT validation logic here
    NULL;
END;
$$;

-- Create storage schema if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_namespace WHERE nspname = 'storage') THEN
        CREATE SCHEMA storage;
        RAISE NOTICE 'Created schema: storage';
    END IF;
END $$;

-- Set storage schema ownership
ALTER SCHEMA storage OWNER TO supabase_storage_admin;

-- Create storage tables
SET search_path TO storage;

CREATE TABLE IF NOT EXISTS buckets (
    id text PRIMARY KEY,
    name text UNIQUE NOT NULL,
    owner uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    public boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS objects (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    bucket_id text REFERENCES buckets(id),
    name text,
    owner uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    last_accessed_at timestamptz DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED,
    UNIQUE(bucket_id, name)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_objects_bucket_id_name ON storage.objects(bucket_id, name);
CREATE INDEX IF NOT EXISTS idx_objects_owner ON storage.objects(owner);

-- Create default buckets
INSERT INTO storage.buckets (id, name, public) VALUES
    ('avatars', 'avatars', true),
    ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA storage TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO authenticated, service_role;

-- Reset search path
SET search_path TO public;

-- Log completion
DO $$ BEGIN RAISE NOTICE 'Supabase initialization completed'; END $$;