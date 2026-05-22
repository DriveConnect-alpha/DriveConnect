import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Client } = pg;

async function migrate() {
  const dbUrl = process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/driveconnect';
  const client = new Client({ connectionString: dbUrl });

  try {
    await client.connect();
    console.log("Conectado ao banco de dados para migração...");

    // 1. Adicionar coluna imagem_url se não existir
    console.log("Verificando coluna 'imagem_url' na tabela 'veiculo'...");
    await client.query(`
      DO $$ 
      BEGIN 
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='veiculo' AND column_name='imagem_url') THEN
          ALTER TABLE veiculo ADD COLUMN imagem_url TEXT;
          RAISE NOTICE 'Coluna imagem_url adicionada.';
        END IF;
      END $$;
    `);

    // 2. Criar tabela veiculo_imagem se não existir
    console.log("Verificando tabela 'veiculo_imagem'...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS veiculo_imagem (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          veiculo_id UUID NOT NULL REFERENCES veiculo(id) ON DELETE CASCADE,
          filename VARCHAR(255) NOT NULL,
          is_principal BOOLEAN DEFAULT FALSE,
          ordem INT DEFAULT 0,
          criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // 3. Criar índice se não existir
    console.log("Verificando índice idx_veiculo_imagem_veiculo...");
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_veiculo_imagem_veiculo ON veiculo_imagem(veiculo_id);
    `);

    console.log("✅ Migração concluída com sucesso!");
  } catch (error) {
    console.error("❌ Erro durante a migração:", error);
  } finally {
    await client.end();
  }
}

migrate();
