import pg from 'pg';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';

dotenv.config();

const { Client } = pg;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function setupDatabase() {
  const dbUrl = process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/driveconnect';
  
  // Extrai os dados da URL (bem simplificado)
  const urlObj = new URL(dbUrl);
  const dbName = urlObj.pathname.split('/')[1];
  
  // Conecta ao banco 'postgres' padrão para criar o banco 'driveconnect' se não existir
  const defaultUrl = dbUrl.replace(`/${dbName}`, '/postgres');
  
  const clientSetup = new Client({ connectionString: defaultUrl });
  
  try {
    await clientSetup.connect();
    
    // Verifica se o banco existe
    const res = await clientSetup.query(`SELECT 1 FROM pg_database WHERE datname = $1`, [dbName]);
    
    if (res.rowCount === 0) {
      console.log(`Bando de dados '${dbName}' não existe. Criando...`);
      await clientSetup.query(`CREATE DATABASE ${dbName}`);
      console.log(`✅ Banco '${dbName}' criado com sucesso!`);
    } else {
      console.log(`✅ Banco de dados '${dbName}' já existe.`);
    }
  } catch (error) {
    console.error("❌ Erro ao checar/criar o banco de dados:", error);
    process.exit(1);
  } finally {
    await clientSetup.end();
  }

  // Agora conecta no banco recém criado/verificado para rodar o init.sql
  const clientApp = new Client({ connectionString: dbUrl });
  try {
    await clientApp.connect();
    
    const sqlFilePath = path.join(__dirname, 'init.sql');
    const sql = fs.readFileSync(sqlFilePath, 'utf8');
    
    console.log(`Executando o script 'init.sql'...`);
    await clientApp.query(sql);
    console.log(`✅ Tabelas criadas/atualizadas com sucesso!`);
    
  } catch (error) {
    console.error("❌ Erro ao rodar o init.sql:", error);
  } finally {
    await clientApp.end();
  }
}

setupDatabase();
