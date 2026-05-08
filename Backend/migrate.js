import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
});

async function run() {
    try {
        console.log('Running migration...');
        await pool.query(`
            ALTER TABLE usuario 
            ADD COLUMN IF NOT EXISTS reset_token VARCHAR(255),
            ADD COLUMN IF NOT EXISTS reset_token_expira_em TIMESTAMP;
        `);
        console.log('✅ Colunas de reset adicionadas na usuario.');
    } catch (e) {}

    try {
        await pool.query(`ALTER TABLE reserva ADD COLUMN IF NOT EXISTS valor_adicional DECIMAL(10,2) DEFAULT 0.00;`);
        console.log('✅ Coluna valor_adicional adicionada na reserva.');
    } catch (e) {}

    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS veiculo_imagem (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                veiculo_id UUID NOT NULL REFERENCES veiculo(id) ON DELETE CASCADE,
                filename VARCHAR(255) NOT NULL,
                is_principal BOOLEAN DEFAULT FALSE,
                ordem INT DEFAULT 0,
                criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS idx_veiculo_imagem_veiculo ON veiculo_imagem(veiculo_id);
        `);
        console.log('✅ Tabela veiculo_imagem verificada/criada.');
    } catch (e) {
        console.error('Erro ao criar veiculo_imagem', e);
    } finally {
        try {
            await pool.query(`CREATE EXTENSION IF NOT EXISTS vector;`);
        } catch (e) {
            console.error('Erro ao habilitar extensão vector', e);
        }

        try {
            await pool.query(`
                CREATE TABLE IF NOT EXISTS whatsapp_conversation (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    phone VARCHAR(32) UNIQUE NOT NULL,
                    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
                    last_message_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );

                CREATE TABLE IF NOT EXISTS whatsapp_message (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    conversation_id UUID REFERENCES whatsapp_conversation(id) ON DELETE CASCADE,
                    direction VARCHAR(3) NOT NULL CHECK (direction IN ('IN', 'OUT')),
                    wa_message_id VARCHAR(128),
                    text TEXT,
                    raw_payload JSONB,
                    status VARCHAR(20) NOT NULL DEFAULT 'received',
                    error TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );

                CREATE INDEX IF NOT EXISTS idx_whatsapp_message_conversation ON whatsapp_message(conversation_id, created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_whatsapp_message_wa_id ON whatsapp_message(wa_message_id);
            `);
            console.log('✅ Tabelas whatsapp_conversation e whatsapp_message verificadas/criadas.');
        } catch (e) {
            console.error('Erro ao criar tabelas de WhatsApp', e);
        }

        try {
            await pool.query(`
                CREATE TABLE IF NOT EXISTS langchain_pg_collection (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    name TEXT NOT NULL,
                    cmetadata JSONB
                );

                CREATE UNIQUE INDEX IF NOT EXISTS idx_langchain_pg_collection_name ON langchain_pg_collection(name);

                CREATE TABLE IF NOT EXISTS langchain_pg_embedding (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    collection_id UUID REFERENCES langchain_pg_collection(id) ON DELETE CASCADE,
                    embedding vector(1536),
                    document TEXT,
                    metadata JSONB
                );

                CREATE INDEX IF NOT EXISTS idx_langchain_pg_embedding_collection ON langchain_pg_embedding(collection_id);
                CREATE INDEX IF NOT EXISTS idx_langchain_pg_embedding_vector ON langchain_pg_embedding USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
            `);
            console.log('✅ Tabelas LangChain/PGVector verificadas/criadas.');
        } catch (e) {
            console.error('Erro ao criar tabelas de RAG', e);
        }

        await pool.end();
    }
}
run();
