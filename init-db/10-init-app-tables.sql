-- 10-init-app-tables.sql
-- Create application specific tables

SET search_path TO public;

-- Update trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Workflows table for n8n integration
CREATE TABLE IF NOT EXISTS workflows (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    n8n_workflow_id text UNIQUE,
    is_active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}',
    owner_id uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_workflows_owner ON workflows(owner_id);
CREATE INDEX idx_workflows_n8n_id ON workflows(n8n_workflow_id);

CREATE TRIGGER update_workflows_updated_at BEFORE UPDATE ON workflows
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- API Keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    key_hash text NOT NULL UNIQUE,
    owner_id uuid NOT NULL,
    permissions jsonb DEFAULT '[]',
    expires_at timestamptz,
    last_used_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_api_keys_owner ON api_keys(owner_id);
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Webhook logs table
CREATE TABLE IF NOT EXISTS webhook_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    workflow_id uuid REFERENCES workflows(id) ON DELETE CASCADE,
    endpoint text NOT NULL,
    method text NOT NULL,
    headers jsonb,
    body jsonb,
    response_status integer,
    response_body jsonb,
    duration_ms integer,
    created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_webhook_logs_workflow ON webhook_logs(workflow_id);
CREATE INDEX idx_webhook_logs_created ON webhook_logs(created_at);

-- Vector collections metadata
CREATE TABLE IF NOT EXISTS vector_collections (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text UNIQUE NOT NULL,
    description text,
    embedding_model text DEFAULT 'text-embedding-ada-002',
    embedding_dimensions integer DEFAULT 1536,
    metadata jsonb DEFAULT '{}',
    owner_id uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_vector_collections_owner ON vector_collections(owner_id);

CREATE TRIGGER update_vector_collections_updated_at BEFORE UPDATE ON vector_collections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Processing jobs table
CREATE TABLE IF NOT EXISTS processing_jobs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    type text NOT NULL,
    status text DEFAULT 'pending',
    payload jsonb DEFAULT '{}',
    result jsonb,
    error text,
    started_at timestamptz,
    completed_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_processing_jobs_status ON processing_jobs(status);
CREATE INDEX idx_processing_jobs_type ON processing_jobs(type);
CREATE INDEX idx_processing_jobs_created ON processing_jobs(created_at);

CREATE TRIGGER update_processing_jobs_updated_at BEFORE UPDATE ON processing_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

-- Enable RLS on sensitive tables
ALTER TABLE workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE vector_collections ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workflows
CREATE POLICY "Users can view their own workflows" ON workflows
    FOR SELECT USING (owner_id = auth.uid() OR owner_id IS NULL);

CREATE POLICY "Users can manage their own workflows" ON workflows
    FOR ALL USING (owner_id = auth.uid() OR auth.role() = 'service_role');

-- RLS Policies for api_keys
CREATE POLICY "Users can view their own API keys" ON api_keys
    FOR SELECT USING (owner_id = auth.uid());

CREATE POLICY "Users can manage their own API keys" ON api_keys
    FOR ALL USING (owner_id = auth.uid() OR auth.role() = 'service_role');

-- RLS Policies for vector_collections
CREATE POLICY "Users can view their own collections" ON vector_collections
    FOR SELECT USING (owner_id = auth.uid() OR owner_id IS NULL);

CREATE POLICY "Users can manage their own collections" ON vector_collections
    FOR ALL USING (owner_id = auth.uid() OR auth.role() = 'service_role');

-- Log completion
DO $$ BEGIN RAISE NOTICE 'Application tables initialization completed'; END $$;