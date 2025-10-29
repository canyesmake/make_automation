-- Legal Document Request Automation - Database Schema

-- Create the main table for logging document requests
CREATE TABLE IF NOT EXISTS legal_document_requests (
    id VARCHAR(255) PRIMARY KEY NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    case_type VARCHAR(255) NOT NULL,
    document_type VARCHAR(255) NOT NULL,
    status VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_email ON legal_document_requests(email);
CREATE INDEX IF NOT EXISTS idx_created_at ON legal_document_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_status ON legal_document_requests(status);
CREATE INDEX IF NOT EXISTS idx_document_type ON legal_document_requests(document_type);

