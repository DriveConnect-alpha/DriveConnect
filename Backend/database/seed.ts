import pg from 'pg';
import * as argon2 from 'argon2';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/driveconnect',
});

// Helpers para geração de dados
const randomElement = <T>(array: T[]): T => array[Math.floor(Math.random() * array.length)];
const randomPlate = () => {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const numbers = '0123456789';
  return (
    randomElement(letters.split('')) +
    randomElement(letters.split('')) +
    randomElement(letters.split('')) +
    randomElement(numbers.split('')) +
    randomElement(letters.split('')) +
    randomElement(numbers.split('')) +
    randomElement(numbers.split(''))
  );
};

async function seed() {
  console.log('🌱 Iniciando seed completa do banco de dados...');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Criar Usuário ADMIN (Manter existente)
    const adminEmail = 'admin@driveconnect.com';
    const adminPassword = await argon2.hash('$driveconnect#Admin');
    const { rows: adminExist } = await client.query('SELECT id FROM usuario WHERE email = $1', [adminEmail]);
    if (adminExist.length === 0) {
      const res = await client.query(
        "INSERT INTO usuario (email, senha, tipo) VALUES ($1, $2, 'ADMIN') RETURNING id",
        [adminEmail, adminPassword]
      );
      await client.query(
        "INSERT INTO gerente (usuario_id, nome_completo) VALUES ($1, $2)",
        [res.rows[0].id, 'Administrador do Sistema']
      );
      console.log('✅ Usuário ADMIN criado.');
    }

    // 2. Criar 5 Filiais
    console.log('🏢 Criando filiais...');
    const filiaisData = [
      { nome: 'Matriz São Paulo', cidade: 'São Paulo', uf: 'SP', cep: '01310-100', rua: 'Av. Paulista', numero: '1000' },
      { nome: 'Filial Rio', cidade: 'Rio de Janeiro', uf: 'RJ', cep: '20040-000', rua: 'Av. Rio Branco', numero: '500' },
      { nome: 'Filial BH', cidade: 'Belo Horizonte', uf: 'MG', cep: '30140-000', rua: 'Rua da Bahia', numero: '123' },
      { nome: 'Filial Curitiba', cidade: 'Curitiba', uf: 'PR', cep: '80010-000', rua: 'Rua XV de Novembro', numero: '88' },
      { nome: 'Filial Brasília', cidade: 'Brasília', uf: 'DF', cep: '70040-000', rua: 'Eixo Monumental', numero: 'S/N' },
    ];

    const filialIds: string[] = [];
    for (const f of filiaisData) {
      const { rows } = await client.query(
        "INSERT INTO filial (nome, cidade, uf, cep, rua, numero, ativo) VALUES ($1, $2, $3, $4, $5, $6, true) ON CONFLICT (id) DO NOTHING RETURNING id",
        [f.nome, f.cidade, f.uf, f.cep, f.rua, f.numero]
      );
      if (rows.length > 0) {
        filialIds.push(rows[0].id);
      } else {
        const { rows: existing } = await client.query("SELECT id FROM filial WHERE nome = $1", [f.nome]);
        filialIds.push(existing[0].id);
      }
    }
    console.log(`✅ ${filialIds.length} Filiais prontas.`);

    // 3. Planos de Seguro
    const { rows: segurosExist } = await client.query('SELECT id FROM plano_seguro');
    if (segurosExist.length === 0) {
      await client.query("INSERT INTO plano_seguro (nome, descricao, percentual, obrigatorio, ativo) VALUES ('Básico', 'Essencial', 0.00, true, true)");
      await client.query("INSERT INTO plano_seguro (nome, descricao, percentual, obrigatorio, ativo) VALUES ('Standard', 'Intermediário', 10.00, false, true)");
      await client.query("INSERT INTO plano_seguro (nome, descricao, percentual, obrigatorio, ativo) VALUES ('Premium', 'Completo', 20.00, false, true)");
      console.log('✅ Planos de seguro criados.');
    }

    // 4. Categorias (Tipo Carro)
    const { rows: tiposExist } = await client.query('SELECT id, nome FROM tipo_carro');
    let economicoId, sedanId, suvId;
    if (tiposExist.length === 0) {
      const resE = await client.query("INSERT INTO tipo_carro (nome, preco_base_diaria) VALUES ('Econômico', 89.90) RETURNING id");
      const resS = await client.query("INSERT INTO tipo_carro (nome, preco_base_diaria) VALUES ('Sedan', 129.90) RETURNING id");
      const resV = await client.query("INSERT INTO tipo_carro (nome, preco_base_diaria) VALUES ('SUV', 189.90) RETURNING id");
      economicoId = resE.rows[0].id;
      sedanId = resS.rows[0].id;
      suvId = resV.rows[0].id;
    } else {
      economicoId = tiposExist.find(t => t.nome === 'Econômico')?.id;
      sedanId = tiposExist.find(t => t.nome === 'Sedan')?.id;
      suvId = tiposExist.find(t => t.nome === 'SUV')?.id;
    }

    // 5. Modelos (10)
    console.log('🚗 Criando modelos...');
    const modelosData = [
      { nome: 'HB20', marca: 'Hyundai', tipo: economicoId },
      { nome: 'Onix', marca: 'Chevrolet', tipo: economicoId },
      { nome: 'Mobi', marca: 'Fiat', tipo: economicoId },
      { nome: 'Corolla', marca: 'Toyota', tipo: sedanId },
      { nome: 'Civic', marca: 'Honda', tipo: sedanId },
      { nome: 'Virtus', marca: 'VW', tipo: sedanId },
      { nome: 'Cronos', marca: 'Fiat', tipo: sedanId },
      { nome: 'Compass', marca: 'Jeep', tipo: suvId },
      { nome: 'Renegade', marca: 'Jeep', tipo: suvId },
      { nome: 'T-Cross', marca: 'VW', tipo: suvId },
    ];

    const modeloIds: number[] = [];
    for (const m of modelosData) {
      const { rows } = await client.query(
        "INSERT INTO modelo (nome, marca, tipo_carro_id) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING RETURNING id",
        [m.nome, m.marca, m.tipo]
      );
      if (rows.length > 0) {
        modeloIds.push(rows[0].id);
      } else {
        const { rows: existing } = await client.query("SELECT id FROM modelo WHERE nome = $1", [m.nome]);
        modeloIds.push(existing[0].id);
      }
    }
    console.log(`✅ ${modeloIds.length} Modelos prontos.`);

    // 5.5. Itens de Veículo
    console.log('🔌 Criando itens opcionais...');
    const itensData = [
      'Ar Condicionado', 'Direção Hidráulica', 'Vidros Elétricos', 'Trava Elétrica',
      'Airbag', 'ABS', 'Som Bluetooth', 'Sensor de Estacionamento', 'Câmera de Ré'
    ];
    for (const itemNome of itensData) {
      await client.query("INSERT INTO item (nome) VALUES ($1) ON CONFLICT (nome) DO NOTHING", [itemNome]);
    }
    console.log('✅ Itens opcionais criados.');

    // 6. Clientes (10)
    console.log('👥 Criando clientes...');
    const clientesNomes = [
      'João Silva', 'Maria Oliveira', 'Pedro Santos', 'Ana Costa', 'Lucas Pereira',
      'Julia Rodrigues', 'Bruno Souza', 'Carla Fernandes', 'Diego Lima', 'Elena Rocha'
    ];
    const password = await argon2.hash('cliente123');
    for (let i = 0; i < clientesNomes.length; i++) {
      const email = `cliente${i + 1}@email.com`;
      const { rows: userExist } = await client.query('SELECT id FROM usuario WHERE email = $1', [email]);
      if (userExist.length === 0) {
        const userRes = await client.query(
          "INSERT INTO usuario (email, senha, tipo) VALUES ($1, $2, 'CLIENTE') RETURNING id",
          [email, password]
        );
        const userId = userRes.rows[0].id;
        await client.query(
          "INSERT INTO cliente (usuario_id, nome_completo, cpf) VALUES ($1, $2, $3)",
          [userId, clientesNomes[i], `${i}${i}${i}.${i}${i}${i}.${i}${i}${i}-${i}${i}`]
        );
      }
    }
    console.log('✅ 10 Clientes criados.');

    // 7. Veículos (30)
    console.log('🏎️  Criando veículos...');
    const cores = ['Branco', 'Preto', 'Prata', 'Cinza', 'Vermelho', 'Azul'];
    const statusList = ['DISPONIVEL', 'DISPONIVEL', 'DISPONIVEL', 'ALUGADO', 'MANUTENCAO']; // Mais disponíveis
    
    // Pegar IDs dos itens para associação
    const { rows: items } = await client.query('SELECT id FROM item');

    for (let i = 0; i < 30; i++) {
      const modeloId = randomElement(modeloIds);
      const filialId = randomElement(filialIds);
      const placa = randomPlate();
      const cor = randomElement(cores);
      const status = randomElement(statusList);
      const ano = 2022 + Math.floor(Math.random() * 4); // 2022 a 2025
      
      // Preço diário baseado na categoria (pegando do banco simplificadamente)
      const { rows: modInfo } = await client.query('SELECT t.preco_base_diaria FROM modelo m JOIN tipo_carro t ON m.tipo_carro_id = t.id WHERE m.id = $1', [modeloId]);
      const precoBase = parseFloat(modInfo[0].preco_base_diaria);
      const precoDiaria = precoBase + (Math.random() * 20); // Variação pequena

      const { rows: vRes } = await client.query(
        `INSERT INTO veiculo (modelo_id, filial_id, placa, ano, cor, status, preco_diaria) 
         VALUES ($1, $2, $3, $4, $5, $6, $7) 
         ON CONFLICT (placa) DO NOTHING RETURNING id`,
        [modeloId, filialId, placa, ano, cor, status, precoDiaria]
      );

      if (vRes.length > 0) {
        const veiculoId = vRes[0].id;
        
        // Associar 3 a 5 itens aleatórios
        const numItems = 3 + Math.floor(Math.random() * 3);
        const shuffledItems = [...items].sort(() => 0.5 - Math.random());
        for (let j = 0; j < numItems; j++) {
          await client.query(
            "INSERT INTO veiculo_item (veiculo_id, item_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
            [veiculoId, shuffledItems[j].id]
          );
        }
      }
    }
    console.log('✅ 30 Veículos criados e configurados.');

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
