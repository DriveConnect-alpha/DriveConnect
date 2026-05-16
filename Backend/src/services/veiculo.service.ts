import { query } from '../db/index.js';
import type { Veiculo } from '../entities/Veiculo.js';
import { notifyVeiculoStatusAlteradoAllManagers } from './fcm.service.js';

export async function criarVeiculo(dados: Veiculo & { itens_ids?: string[] }): Promise<Veiculo> {
    const q = `
    INSERT INTO veiculo (modelo_id, filial_id, placa, ano, cor, status, imagem_url, preco_diaria)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *;
  `;
    const values = [
        dados.modelo_id,
        dados.filial_id,
        dados.placa,
        dados.ano,
        dados.cor,
        dados.status,
        dados.imagem_url,
        dados.preco_diaria
    ];
    const result = await query(q, values);
    const veiculo = result.rows[0];

    // Associar itens se fornecidos
    if (dados.itens_ids && dados.itens_ids.length > 0) {
        for (const itemId of dados.itens_ids) {
            await query(
                'INSERT INTO veiculo_item (veiculo_id, item_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
                [veiculo.id, itemId]
            );
        }
    }

    return veiculo;
}

export async function listarVeiculos(filialId?: string): Promise<any[]> {
    let queryText = `
    SELECT
        v.id, v.modelo_id, v.filial_id, v.placa, v.ano, v.cor,
        CASE
            WHEN v.status = 'DISPONIVEL' AND EXISTS (
                SELECT 1 FROM reserva r
                WHERE r.veiculo_id = v.id
                  AND r.status = 'RESERVADA'
                  AND NOW() BETWEEN r.data_inicio AND r.data_fim
                  AND r.deletado_em IS NULL
            ) THEN 'ALUGADO'
            ELSE v.status
        END as status,
        COALESCE(v.imagem_url, (SELECT filename FROM veiculo_imagem WHERE veiculo_id = v.id ORDER BY is_principal DESC, ordem ASC LIMIT 1)) as imagem_url,
        v.criado_em,
        v.deletado_em,
        v.preco_diaria,
        ARRAY(SELECT i.nome FROM item i JOIN veiculo_item vi ON i.id = vi.item_id WHERE vi.veiculo_id = v.id) as itens,
        json_build_object(
            'id', m.id,
            'nome', m.nome,
            'marca', m.marca,
            'tipo_carro_id', m.tipo_carro_id,
            'tipo_carro', CASE WHEN tc.id IS NOT NULL THEN json_build_object(
                'id', tc.id,
                'nome', tc.nome,
                'preco_base_diaria', tc.preco_base_diaria
            ) ELSE NULL END
        ) as modelo,
        json_build_object(
            'id', f.id,
            'nome', f.nome,
            'cep', f.cep,
            'uf', f.uf,
            'cidade', f.cidade,
            'bairro', f.bairro,
            'rua', f.rua,
            'numero', f.numero,
            'complemento', f.complemento,
            'ativo', f.ativo,
            'criado_em', f.criado_em,
            'deletado_em', f.deletado_em
        ) as filial
    FROM veiculo v
    INNER JOIN modelo m ON v.modelo_id = m.id
    LEFT JOIN tipo_carro tc ON m.tipo_carro_id = tc.id
    INNER JOIN filial f ON v.filial_id = f.id
    WHERE v.deletado_em IS NULL
    `;

    const values = [];
    if (filialId) {
        queryText += ` AND v.filial_id = $1`;
        values.push(filialId);
    }
    queryText += ` ORDER BY v.criado_em DESC`;

    const result = await query(queryText, values);
    return result.rows;
}

export async function buscarVeiculoPorId(id: string): Promise<any | null> {
    const q = `
        SELECT
            v.id, v.modelo_id, v.filial_id, v.placa, v.ano, v.cor,
            CASE
                WHEN v.status = 'DISPONIVEL' AND EXISTS (
                    SELECT 1 FROM reserva r
                    WHERE r.veiculo_id = v.id
                      AND r.status = 'RESERVADA'
                      AND NOW() BETWEEN r.data_inicio AND r.data_fim
                      AND r.deletado_em IS NULL
                ) THEN 'ALUGADO'
                ELSE v.status
            END as status,
            COALESCE(v.imagem_url, (SELECT filename FROM veiculo_imagem WHERE veiculo_id = v.id ORDER BY is_principal DESC, ordem ASC LIMIT 1)) as imagem_url,
            v.criado_em,
            v.deletado_em,
            v.preco_diaria,
            ARRAY(SELECT i.nome FROM item i JOIN veiculo_item vi ON i.id = vi.item_id WHERE vi.veiculo_id = v.id) as itens,
            json_build_object(
                'id', m.id,
                'nome', m.nome,
                'marca', m.marca,
                'tipo_carro_id', m.tipo_carro_id,
                'tipo_carro', CASE WHEN tc.id IS NOT NULL THEN json_build_object(
                    'id', tc.id,
                    'nome', tc.nome,
                    'preco_base_diaria', tc.preco_base_diaria
                ) ELSE NULL END
            ) as modelo,
            json_build_object(
                'id', f.id,
                'nome', f.nome,
                'cep', f.cep,
                'uf', f.uf,
                'cidade', f.cidade,
                'bairro', f.bairro,
                'rua', f.rua,
                'numero', f.numero,
                'complemento', f.complemento,
                'ativo', f.ativo,
                'criado_em', f.criado_em,
                'deletado_em', f.deletado_em
            ) as filial
        FROM veiculo v
        INNER JOIN modelo m ON v.modelo_id = m.id
        LEFT JOIN tipo_carro tc ON m.tipo_carro_id = tc.id
        INNER JOIN filial f ON v.filial_id = f.id
        WHERE v.id = $1 AND v.deletado_em IS NULL
    `;
    const result = await query(q, [id]);
    const veiculo = result.rows[0];
    if (!veiculo) return null;

    const qImagens = `SELECT * FROM veiculo_imagem WHERE veiculo_id = $1 ORDER BY is_principal DESC, ordem ASC`;
    const imagens = await query(qImagens, [id]);
    veiculo.imagens = imagens.rows;

    return veiculo;
}

export async function adicionarImagemVeiculo(veiculoId: string, filename: string, isPrincipal: boolean = false): Promise<void> {
    if (isPrincipal) {
        await query(`UPDATE veiculo_imagem SET is_principal = FALSE WHERE veiculo_id = $1`, [veiculoId]);
    }
    await query(`
        INSERT INTO veiculo_imagem (veiculo_id, filename, is_principal)
        VALUES ($1, $2, $3)
    `, [veiculoId, filename, isPrincipal]);
}

export async function substituirImagemVeiculo(veiculoId: string, filename: string): Promise<void> {
    await query(`DELETE FROM veiculo_imagem WHERE veiculo_id = $1`, [veiculoId]);
    await query(
        `INSERT INTO veiculo_imagem (veiculo_id, filename, is_principal)
         VALUES ($1, $2, TRUE)`,
        [veiculoId, filename],
    );
}

export async function atualizarVeiculo(id: string, dados: Partial<Veiculo>): Promise<Veiculo | null> {
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramIdx = 1;

    for (const [key, value] of Object.entries(dados)) {
        if (value !== undefined && key !== 'id') {
            setClauses.push(`${key} = $${paramIdx}`);
            values.push(value);
            paramIdx++;
        }
    }

    if (setClauses.length === 0) return null;

    values.push(id);
    const q = `
    UPDATE veiculo 
    SET ${setClauses.join(', ')} 
    WHERE id = $${paramIdx} AND deletado_em IS NULL 
    RETURNING *;
  `;

    const result = await query(q, values);
    return result.rows[0] || null;
}

export async function atualizarStatusVeiculoE_Notificar(params: {
    veiculoId: string;
    novoStatus: string;
    origem?: string;
    motivo?: string;
}): Promise<void> {
    const { veiculoId, novoStatus, origem, motivo } = params;
    if (!veiculoId || !novoStatus) return;

    const before = await query(
        `SELECT v.id, v.placa, v.status, v.filial_id,
                f.nome AS filial_nome, f.cidade, f.uf,
                m.nome AS modelo_nome, m.marca AS modelo_marca
         FROM veiculo v
         JOIN filial f ON f.id = v.filial_id
         JOIN modelo m ON m.id = v.modelo_id
         WHERE v.id = $1 AND v.deletado_em IS NULL
         LIMIT 1`,
        [veiculoId],
    );
    const row = before.rows[0];
    if (!row) return;

    const statusAnterior = String(row.status || '');
    const statusNovo = String(novoStatus);
    if (statusAnterior === statusNovo) return;

    await query(
        `UPDATE veiculo SET status = $1 WHERE id = $2 AND deletado_em IS NULL`,
        [statusNovo, veiculoId],
    );

    const modelo = [row.modelo_marca, row.modelo_nome].filter(Boolean).join(' ').trim() || null;

    const payload: {
        veiculoId: string;
        placa?: string;
        statusAnterior?: string | null;
        statusNovo: string;
        filialId?: string | null;
        filialNome?: string | null;
        cidade?: string | null;
        uf?: string | null;
        modelo?: string | null;
        origem?: string;
        motivo?: string;
    } = {
        veiculoId,
        statusNovo,
        statusAnterior,
        filialId: row.filial_id ?? null,
        filialNome: row.filial_nome ?? null,
        cidade: row.cidade ?? null,
        uf: row.uf ?? null,
        modelo,
        origem: origem ?? 'BACKEND',
    };
    if (row.placa) payload.placa = String(row.placa);
    if (motivo) payload.motivo = motivo;

    await notifyVeiculoStatusAlteradoAllManagers(payload);
}

export async function atualizarStatusVeiculoPorReservaE_Notificar(params: {
    reservaId: string;
    novoStatus: string;
    origem?: string;
    motivo?: string;
}): Promise<void> {
    const { reservaId, novoStatus, origem, motivo } = params;
    if (!reservaId || !novoStatus) return;

    const r = await query(`SELECT veiculo_id FROM reserva WHERE id = $1 AND deletado_em IS NULL LIMIT 1`, [reservaId]);
    const veiculoId = r.rows[0]?.veiculo_id as string | undefined;
    if (!veiculoId) return;

    const next: { veiculoId: string; novoStatus: string; origem?: string; motivo?: string } = { veiculoId, novoStatus };
    if (origem) next.origem = origem;
    if (motivo) next.motivo = motivo;
    await atualizarStatusVeiculoE_Notificar(next);
}

export async function deletarVeiculo(id: string): Promise<boolean> {
    const q = `UPDATE veiculo SET deletado_em = CURRENT_TIMESTAMP WHERE id = $1 RETURNING id`;
    const result = await query(q, [id]);
    return (result.rowCount ?? 0) > 0;
}

export async function listarItens(): Promise<any[]> {
    const q = `SELECT * FROM item ORDER BY nome ASC`;
    const result = await query(q);
    return result.rows;
}

export async function listarReservasDoVeiculo(veiculoId: string): Promise<any[]> {
    const q = `
        SELECT data_inicio, data_fim 
        FROM reserva 
        WHERE veiculo_id = $1 
          AND (
            status IN ('RESERVADA', 'ATIVA') 
            OR (status = 'PENDENTE_PAGAMENTO' AND expira_em > NOW())
          )
          AND deletado_em IS NULL
        ORDER BY data_inicio ASC;
    `;
    const result = await query(q, [veiculoId]);
    return result.rows;
}

export async function listarVeiculosDisponiveis(filialId: string, dataInicio: Date, dataFim: Date): Promise<any[]> {
    const q = `
    SELECT
        v.id, v.modelo_id, v.filial_id, v.placa, v.ano, v.cor, v.status,
        COALESCE(v.imagem_url, (SELECT filename FROM veiculo_imagem WHERE veiculo_id = v.id ORDER BY is_principal DESC, ordem ASC LIMIT 1)) as imagem_url,
        v.preco_diaria,
        json_build_object(
            'id', m.id,
            'nome', m.nome,
            'marca', m.marca,
            'tipo_carro_id', m.tipo_carro_id
        ) as modelo
    FROM veiculo v
    INNER JOIN modelo m ON v.modelo_id = m.id
    WHERE v.filial_id = $1
      AND v.status = 'DISPONIVEL'
      AND v.deletado_em IS NULL
      AND NOT EXISTS (
          SELECT 1 FROM reserva r
          WHERE r.veiculo_id = v.id
            AND r.deletado_em IS NULL
            AND r.status IN ('RESERVADA', 'ATIVA', 'PENDENTE_PAGAMENTO')
            AND (r.status != 'PENDENTE_PAGAMENTO' OR r.expira_em > NOW())
            AND r.data_inicio <= $3
            AND r.data_fim >= $2
      )
    ORDER BY m.marca ASC, m.nome ASC;
    `;
    const result = await query(q, [filialId, dataInicio, dataFim]);
    return result.rows;
}
