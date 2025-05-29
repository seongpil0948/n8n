-- volumes/db/init-vector.sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create vector storage table for AI workflows
CREATE TABLE IF NOT EXISTS public.embeddings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    content text NOT NULL,
    metadata jsonb,
    embedding vector(1536), -- OpenAI embedding size
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Create index for vector similarity search
CREATE INDEX embeddings_embedding_idx ON public.embeddings 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Create function for similarity search
CREATE OR REPLACE FUNCTION match_embeddings(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.78,
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id uuid,
    content text,
    metadata jsonb,
    similarity float
)
LANGUAGE sql STABLE
AS $$
    SELECT
        embeddings.id,
        embeddings.content,
        embeddings.metadata,
        1 - (embeddings.embedding <=> query_embedding) AS similarity
    FROM embeddings
    WHERE 1 - (embeddings.embedding <=> query_embedding) > match_threshold
    ORDER BY embeddings.embedding <=> query_embedding
    LIMIT match_count;
$$;

-- Grant permissions
GRANT ALL ON public.embeddings TO authenticated;
GRANT ALL ON public.embeddings TO service_role;
GRANT EXECUTE ON FUNCTION match_embeddings TO authenticated;
GRANT EXECUTE ON FUNCTION match_embeddings TO service_role;