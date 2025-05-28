-- 05-init-vector.sql
-- Initialize vector store for embeddings

SET search_path TO vector_store, public;

-- Documents table for storing text and embeddings
CREATE TABLE IF NOT EXISTS documents (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    content text NOT NULL,
    metadata jsonb DEFAULT '{}',
    embedding vector(1536), -- OpenAI ada-002 dimension
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    owner_id uuid,
    collection_name text DEFAULT 'default',
    chunk_index integer DEFAULT 0,
    total_chunks integer DEFAULT 1
);

-- Create indexes for similarity search
CREATE INDEX IF NOT EXISTS documents_embedding_idx ON documents 
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE INDEX IF NOT EXISTS documents_collection_idx ON documents(collection_name);
CREATE INDEX IF NOT EXISTS documents_owner_idx ON documents(owner_id);
CREATE INDEX IF NOT EXISTS documents_metadata_idx ON documents USING gin(metadata);

-- Function to search similar documents
CREATE OR REPLACE FUNCTION vector_store.search_documents(
    query_embedding vector(1536),
    match_count int DEFAULT 10,
    collection text DEFAULT NULL,
    filter jsonb DEFAULT '{}'
)
RETURNS TABLE (
    id uuid,
    content text,
    metadata jsonb,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.content,
        d.metadata,
        1 - (d.embedding <=> query_embedding) AS similarity
    FROM vector_store.documents d
    WHERE 
        (collection IS NULL OR d.collection_name = collection)
        AND (filter = '{}' OR d.metadata @> filter)
        AND d.embedding IS NOT NULL
    ORDER BY d.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Function to add document with automatic chunking
CREATE OR REPLACE FUNCTION vector_store.add_document(
    p_content text,
    p_metadata jsonb DEFAULT '{}',
    p_collection text DEFAULT 'default',
    p_owner_id uuid DEFAULT NULL,
    p_chunk_size int DEFAULT 1000
)
RETURNS TABLE (
    id uuid,
    chunk_index integer,
    total_chunks integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    chunks text[];
    chunk text;
    i integer;
    total integer;
    doc_id uuid;
BEGIN
    -- Split content into chunks if needed
    IF length(p_content) > p_chunk_size THEN
        chunks := string_to_array(
            regexp_replace(p_content, '(.{1,' || p_chunk_size || '})', '\1|SPLIT|', 'g'),
            '|SPLIT|'
        );
    ELSE
        chunks := ARRAY[p_content];
    END IF;
    
    total := array_length(chunks, 1);
    
    -- Insert each chunk
    FOR i IN 1..total LOOP
        chunk := chunks[i];
        IF length(trim(chunk)) > 0 THEN
            INSERT INTO vector_store.documents (
                content, 
                metadata, 
                collection_name, 
                owner_id, 
                chunk_index, 
                total_chunks
            )
            VALUES (
                chunk,
                p_metadata || jsonb_build_object('chunk_index', i - 1, 'total_chunks', total),
                p_collection,
                p_owner_id,
                i - 1,
                total
            )
            RETURNING documents.id INTO doc_id;
            
            RETURN QUERY SELECT doc_id, i - 1, total;
        END IF;
    END LOOP;
END;
$$;

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA vector_store TO authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA vector_store TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA vector_store TO authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA vector_store TO authenticated, service_role;

-- Enable RLS
ALTER TABLE vector_store.documents ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own documents" ON vector_store.documents
    FOR SELECT USING (owner_id = auth.uid() OR owner_id IS NULL);

CREATE POLICY "Users can insert their own documents" ON vector_store.documents
    FOR INSERT WITH CHECK (owner_id = auth.uid() OR owner_id IS NULL);

CREATE POLICY "Users can update their own documents" ON vector_store.documents
    FOR UPDATE USING (owner_id = auth.uid());

CREATE POLICY "Users can delete their own documents" ON vector_store.documents
    FOR DELETE USING (owner_id = auth.uid());

-- Service role bypass
CREATE POLICY "Service role has full access" ON vector_store.documents
    FOR ALL USING (auth.role() = 'service_role');

-- Log completion
DO $$ BEGIN RAISE NOTICE 'Vector store initialization completed'; END $$;