
import pkg from 'pg';
const { Client } = pkg;
import dotenv from 'dotenv';
dotenv.config();

async function fixDb() {
  console.log('Verificando colunas da tabela reserva...');
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    await client.connect();
    const res = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'reserva'
    `);
    const columns = res.rows.map(r => r.column_name);
    console.log('Colunas encontradas:', columns);

    if (!columns.includes('valor_adicional')) {
      console.log('Adicionando coluna valor_adicional...');
      await client.query(`ALTER TABLE reserva ADD COLUMN valor_adicional DECIMAL(10,2) DEFAULT 0.00`);
      console.log('Coluna valor_adicional adicionada com sucesso.');
    } else {
      console.log('Coluna valor_adicional já existe.');
    }
  } catch (err) {
    console.error('Erro ao verificar/corrigir DB:', err);
  } finally {
    await client.end();
    process.exit();
  }
}

fixDb();
