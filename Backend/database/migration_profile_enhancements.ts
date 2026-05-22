import 'dotenv/config';
import { Pool } from 'pg';

async function migrate() {
    console.log('--- Iniciando Migração: Perfil e Notificações ---');

    // Explicit pool for the migration
    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
    });

    try {
        console.log('Testando conexão...');
        await pool.query('SELECT 1');
        console.log('Conectado!');

        // 1. Adicionar imagem_url ao usuário
        console.log('Adicionando coluna imagem_url na tabela usuario...');
        await pool.query(`ALTER TABLE usuario ADD COLUMN IF NOT EXISTS imagem_url TEXT;`);

        // 2. Adicionar preferências (JSONB) ao usuário
        console.log('Adicionando coluna preferencias na tabela usuario...');
        await pool.query(`ALTER TABLE usuario ADD COLUMN IF NOT EXISTS preferencias JSONB DEFAULT '{"notifications": {"email": true, "push": true, "whatsapp": true}, "theme": "light"}'::jsonb;`);

        console.log('✅ Migração concluída com sucesso!');
    } catch (err) {
        console.error('❌ Erro na migração:', err);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

migrate();
