import pg from 'pg';
import * as argon2 from 'argon2';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/driveconnect',
});

async function seed() {
  console.log('🌱 Iniciando seed do banco de dados...');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Criar Usuário ADMIN
    const adminEmail = 'admin@driveconnect.com';
    const adminPassword = await argon2.hash('$driveconnect#Admin');
    
    const { rows: adminExist } = await client.query('SELECT id FROM usuario WHERE email = $1', [adminEmail]);
    let adminId;

    if (adminExist.length === 0) {
      const res = await client.query(
        "INSERT INTO usuario (email, senha, tipo) VALUES ($1, $2, 'ADMIN') RETURNING id",
        [adminEmail, adminPassword]
      );
      adminId = res.rows[0].id;
      console.log('✅ Usuário ADMIN criado: admin@driveconnect.com / admin123');
      
      // Criar perfil de gerente para o admin (para ele poder logar e ter nome)
      await client.query(
        "INSERT INTO gerente (usuario_id, nome_completo) VALUES ($1, $2)",
        [adminId, 'Administrador do Sistema']
      );
    } else {
      adminId = adminExist[0].id;
      console.log('ℹ️ Usuário ADMIN já existe.');
    }

    // 2. Criar Filial
    const { rows: filialExist } = await client.query("SELECT id FROM filial WHERE nome = 'Matriz São Paulo'");
    let filialId;

    if (filialExist.length === 0) {
      const res = await client.query(
        "INSERT INTO filial (nome, cidade, uf, ativo) VALUES ($1, $2, $3, $4) RETURNING id",
        ['Matriz São Paulo', 'São Paulo', 'SP', true]
      );
      filialId = res.rows[0].id;
      console.log('✅ Filial Matriz criada.');
    } else {
      filialId = filialExist[0].id;
    }

    // 3. Criar Usuário GERENTE
    const gerenteEmail = 'gerente@driveconnect.com';
    const gerentePassword = await argon2.hash('gerente123');
    
    const { rows: gerenteExist } = await client.query('SELECT id FROM usuario WHERE email = $1', [gerenteEmail]);

    if (gerenteExist.length === 0) {
      const res = await client.query(
        "INSERT INTO usuario (email, senha, tipo) VALUES ($1, $2, 'GERENTE') RETURNING id",
        [gerenteEmail, gerentePassword]
      );
      const newGerenteId = res.rows[0].id;
      
      await client.query(
        "INSERT INTO gerente (usuario_id, nome_completo, filial_id) VALUES ($1, $2, $3)",
        [newGerenteId, 'Gerente da Matriz', filialId]
      );
      console.log('✅ Usuário GERENTE criado: gerente@driveconnect.com / gerente123');
    }

    // 4. Planos de Seguro
    const { rows: segurosExist } = await client.query('SELECT id FROM plano_seguro');
    if (segurosExist.length === 0) {
      await client.query(
        "INSERT INTO plano_seguro (nome, descricao, percentual, obrigatorio, ativo) VALUES ($1, $2, $3, $4, $5)",
        ['Básico', 'Cobertura essencial contra roubo e furto.', 0.00, true, true]
      );
      await client.query(
        "INSERT INTO plano_seguro (nome, descricao, percentual, obrigatorio, ativo) VALUES ($1, $2, $3, $4, $5)",
        ['Standard', 'Cobertura completa + danos a terceiros.', 10.00, false, true]
      );
      await client.query(
        "INSERT INTO plano_seguro (nome, descricao, percentual, obrigatorio, ativo) VALUES ($1, $2, $3, $4, $5)",
        ['Premium', 'Cobertura total sem franquia e assistência 24h VIP.', 20.00, false, true]
      );
      console.log('✅ Planos de seguro criados.');
    }

    // 5. Categorias (Tipo Carro)
    const { rows: tiposExist } = await client.query('SELECT id, nome FROM tipo_carro');
    let economicoId, sedanId, suvId;

    if (tiposExist.length === 0) {
      const resE = await client.query("INSERT INTO tipo_carro (nome, preco_base_diaria) VALUES ('Econômico', 89.90) RETURNING id");
      const resS = await client.query("INSERT INTO tipo_carro (nome, preco_base_diaria) VALUES ('Sedan', 129.90) RETURNING id");
      const resV = await client.query("INSERT INTO tipo_carro (nome, preco_base_diaria) VALUES ('SUV', 189.90) RETURNING id");
      economicoId = resE.rows[0].id;
      sedanId = resS.rows[0].id;
      suvId = resV.rows[0].id;
      console.log('✅ Categorias de carros criadas.');
    } else {
      economicoId = tiposExist.find(t => t.nome === 'Econômico')?.id;
      sedanId = tiposExist.find(t => t.nome === 'Sedan')?.id;
      suvId = tiposExist.find(t => t.nome === 'SUV')?.id;
    }

    // 6. Modelos
    const { rows: modelosExist } = await client.query('SELECT id FROM modelo');
    if (modelosExist.length === 0) {
      await client.query("INSERT INTO modelo (nome, marca, tipo_carro_id) VALUES ('HB20', 'Hyundai', $1)", [economicoId]);
      await client.query("INSERT INTO modelo (nome, marca, tipo_carro_id) VALUES ('Corolla', 'Toyota', $1)", [sedanId]);
      await client.query("INSERT INTO modelo (nome, marca, tipo_carro_id) VALUES ('Compass', 'Jeep', $1)", [suvId]);
      console.log('✅ Modelos de carros criados.');
    }

    await client.query('COMMIT');
    console.log('✨ Seed finalizado com sucesso!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Erro ao executar seed:', error);
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
