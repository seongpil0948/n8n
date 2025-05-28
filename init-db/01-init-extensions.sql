-- 01-init-extensions.sql
-- Install all required extensions

-- Core extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Vector extension for embeddings
CREATE EXTENSION IF NOT EXISTS "vector";

-- Create extensions schema for Supabase
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_namespace WHERE nspname = 'extensions') THEN
        CREATE SCHEMA extensions;
        RAISE NOTICE 'Created schema: extensions';
    END IF;
END $$;

-- JWT extension for Supabase (if available)
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS "pgjwt" SCHEMA extensions;
    RAISE NOTICE 'Created extension: pgjwt';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Extension pgjwt not available: %', SQLERRM;
END $$;

-- Network extension for webhooks (if available)
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS "pg_net" SCHEMA extensions;
    RAISE NOTICE 'Created extension: pg_net';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Extension pg_net not available: %', SQLERRM;
END $$;

-- Grant usage on extensions schema
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role, postgres;
GRANT ALL ON ALL TABLES IN SCHEMA extensions TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA extensions TO postgres;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA extensions TO postgres;

-- Verify critical extensions
DO $$
DECLARE
    ext_count integer;
BEGIN
    SELECT COUNT(*) INTO ext_count 
    FROM pg_extension 
    WHERE extname IN ('uuid-ossp', 'pgcrypto', 'vector');
    
    IF ext_count >= 3 THEN
        RAISE NOTICE 'Critical extensions verified';
    ELSE
        RAISE WARNING 'Some critical extensions may be missing';
    END IF;
END $$;

-- Log completion
DO $$ BEGIN RAISE NOTICE 'Extensions initialization completed'; END $$;