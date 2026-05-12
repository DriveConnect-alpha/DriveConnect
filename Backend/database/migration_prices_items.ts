import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Client } = pg;

async function migrate() {
  const dbUrl = process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/driveconnect';
  const client = new Client({ connectionString: dbUrl });

  try {
    await client.connect();
    console.log("Conectado ao banco de dados para migração (Preço e Itens)...");

    // 1. Adicionar preço customizado ao veículo
    await client.query(`
      ALTER TABLE veiculo 
      ADD COLUMN IF NOT EXISTS preco_diaria DECIMAL(10,2);
    `);
    console.log("✅ Coluna 'preco_diaria' adicionada à tabela 'veiculo'.");

    // 2. Criar tabela de itens/opcionais
    await client.query(`
      CREATE TABLE IF NOT EXISTS item (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        nome VARCHAR(100) UNIQUE NOT NULL,
        criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("✅ Tabela 'item' criada.");

    // 3. Criar tabela de ligação veículo <-> item
    await client.query(`
      CREATE TABLE IF NOT EXISTS veiculo_item (
        veiculo_id UUID REFERENCES veiculo(id) ON DELETE CASCADE,
        item_id UUID REFERENCES item(id) ON DELETE CASCADE,
        PRIMARY KEY (veiculo_id, item_id)
      );
    `);
    console.log("✅ Tabela 'veiculo_item' criada.");

    // 4. Inserir alguns itens padrão
    const defaultItems = [
      'Ar Condicionado',
      'Direção Hidráulica',
      'Vidros Elétricos',
      'Trava Elétrica',
      'Airbag',
      'ABS',
      'Som / Bluetooth',
      'Câmera de Ré',
      'Sensor de Estacionamento',
      'GPS'
    ];

    for (const item of defaultItems) {
      await client.query(`
        INSERT INTO item (nome) VALUES ($1)
        ON CONFLICT (nome) DO NOTHING;
      `, [item]);
    }
    console.log("✅ Itens padrão inseridos.");

    console.log("✨ Migração concluída com sucesso!");
  } catch (err) {
    console.error("❌ Erro na migração:", err);
  } finally {
    await client.end();
  }
}

migrate();
