-- Seed básico 2026: filiais, categorias, modelos, veículos e tabela de preço

-- Filiais
INSERT INTO filial (nome, cep, uf, cidade, bairro, rua, numero, complemento, ativo)
SELECT * FROM (
  VALUES
    ('Unidade Aldeota', '60165121', 'CE', 'Fortaleza', 'Aldeota', 'Rua Exemplo', '100', NULL, TRUE),
    ('Unidade Aeroporto', '60741000', 'CE', 'Fortaleza', 'Aeroporto', 'Av. do Aeroporto', '1', NULL, TRUE),
    ('Unidade Centro', '61600100', 'CE', 'Caucaia', 'Centro', 'Rua Central', '50', NULL, TRUE)
) AS v(nome, cep, uf, cidade, bairro, rua, numero, complemento, ativo)
WHERE NOT EXISTS (
  SELECT 1 FROM filial f WHERE f.nome = v.nome AND f.cidade = v.cidade
);

-- Categorias
INSERT INTO tipo_carro (nome, preco_base_diaria)
SELECT * FROM (
  VALUES
    ('Econômico', 120.00),
    ('Compacto Automático', 160.00),
    ('Sedan', 190.00),
    ('SUV', 260.00),
    ('Premium', 600.00),
    ('Utilitário', 220.00)
) AS v(nome, preco_base_diaria)
WHERE NOT EXISTS (
  SELECT 1 FROM tipo_carro tc WHERE tc.nome = v.nome
);

-- Modelos
INSERT INTO modelo (nome, marca, tipo_carro_id)
SELECT v.nome, v.marca, tc.id
FROM (
  VALUES
    ('Onix', 'Chevrolet', 'Econômico'),
    ('HB20', 'Hyundai', 'Econômico'),
    ('Polo', 'Volkswagen', 'Econômico'),
    ('Argo', 'Fiat', 'Econômico'),
    ('Onix AT', 'Chevrolet', 'Compacto Automático'),
    ('HB20 AT', 'Hyundai', 'Compacto Automático'),
    ('Yaris AT', 'Toyota', 'Compacto Automático'),
    ('Virtus', 'Volkswagen', 'Sedan'),
    ('Corolla', 'Toyota', 'Sedan'),
    ('Civic', 'Honda', 'Sedan'),
    ('T-Cross', 'Volkswagen', 'SUV'),
    ('Creta', 'Hyundai', 'SUV'),
    ('Compass', 'Jeep', 'SUV'),
    ('A4', 'Audi', 'Premium'),
    ('320i', 'BMW', 'Premium'),
    ('C200', 'Mercedes-Benz', 'Premium'),
    ('Fiorino', 'Fiat', 'Utilitário'),
    ('Kangoo', 'Renault', 'Utilitário')
) AS v(nome, marca, categoria)
JOIN tipo_carro tc ON tc.nome = v.categoria
WHERE NOT EXISTS (
  SELECT 1 FROM modelo m WHERE m.nome = v.nome AND m.marca = v.marca
);

-- Veículos (2 por modelo em cada filial)
INSERT INTO veiculo (modelo_id, filial_id, placa, ano, cor, status)
SELECT
  m.id,
  f.id,
  (UPPER(SUBSTRING(MD5(m.id::text || f.id::text || g::text), 1, 3)) || TO_CHAR(g, 'FM0000')),
  2022 + ((g - 1) % 4),
  (ARRAY['Branco','Preto','Prata','Cinza','Azul'])[1 + ((g - 1) % 5)],
  'DISPONIVEL'
FROM modelo m
CROSS JOIN filial f
CROSS JOIN generate_series(1, 2) AS g
WHERE NOT EXISTS (
  SELECT 1 FROM veiculo v
  WHERE v.modelo_id = m.id AND v.filial_id = f.id
);

-- Tabela de preços 2026 (por trimestre)
WITH periodos AS (
  SELECT DATE '2026-01-01' AS ini, DATE '2026-03-31' AS fim UNION ALL
  SELECT DATE '2026-04-01', DATE '2026-06-30' UNION ALL
  SELECT DATE '2026-07-01', DATE '2026-09-30' UNION ALL
  SELECT DATE '2026-10-01', DATE '2026-12-31'
)
INSERT INTO tabela_preco (tipo_carro_id, filial_id, data_inicio, data_fim, valor_diaria)
SELECT tc.id, f.id, p.ini, p.fim,
  CASE tc.nome
    WHEN 'Econômico' THEN 120.00
    WHEN 'Compacto Automático' THEN 165.00
    WHEN 'Sedan' THEN 200.00
    WHEN 'SUV' THEN 270.00
    WHEN 'Premium' THEN 620.00
    WHEN 'Utilitário' THEN 230.00
    ELSE tc.preco_base_diaria
  END
FROM tipo_carro tc
CROSS JOIN filial f
CROSS JOIN periodos p
WHERE NOT EXISTS (
  SELECT 1 FROM tabela_preco tp
  WHERE tp.tipo_carro_id = tc.id
    AND tp.filial_id = f.id
    AND tp.data_inicio = p.ini
    AND tp.data_fim = p.fim
);
