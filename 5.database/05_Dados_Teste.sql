/****** Dados de teste para o banco CopaDoMundoVendas ******/
-- Execute DEPOIS dos scripts 00 a 04. Este arquivo so INSERE linhas: nao altera
-- tabelas, indices, triggers nem a procedure.
--
-- Pode ser executado varias vezes: cada linha so e inserida se ainda nao existir.
--
-- O QUE VEM DO PROJETO E O QUE E FICTICIO
--   Vem de 1.html/index.html: os 6 jogos, as datas, os times e 6 estadios com a cidade.
--   Estadio Sao Januario (Rio de Janeiro): acrescentado a pedido, nao esta no HTML.
--   Ele recebe setores e assentos, mas nenhum jogo, entao nao tem ingressos ainda.
--   FICTICIO (o HTML nao tem esses valores): CapacidadeTotal dos estadios, os setores,
--   os precos, o numero de assentos, o horario (16:00) e a fase dos jogos.
--
-- ATENCAO: as datas dos jogos sao as do HTML (junho de 2026). Se a data atual ja
-- passou delas, os jogos aparecem como realizados. Para mudar, troque os valores de
-- @Jogos abaixo e rode de novo em um banco limpo (veja o bloco de limpeza no fim).

USE [CopaDoMundoVendas]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- ---------- Estadios ----------
-- CapacidadeTotal (100) e FICTICIA e maior que a soma dos setores abaixo (25 lugares por estadio).
DECLARE @Estadios TABLE (Nome varchar(100), Cidade varchar(100), CapacidadeTotal int);
INSERT INTO @Estadios (Nome, Cidade, CapacidadeTotal) VALUES
    ('Estádio Azteca',         'Cidade do México', 100),
    ('SoFi Stadium',           'Los Angeles',      100),
    ('AT&T Stadium',           'Dallas',           100),
    ('Mercedes-Benz Stadium',  'Atlanta',          100),
    ('BC Place',               'Vancouver',        100),
    ('MetLife Stadium',        'Nova Jersey',      100),
    ('Estádio São Januário',   'Rio de Janeiro',   100);

INSERT INTO Estadio (Nome, Cidade, CapacidadeTotal)
SELECT e.Nome, e.Cidade, e.CapacidadeTotal
FROM @Estadios e
WHERE NOT EXISTS (SELECT 1 FROM Estadio x WHERE x.Nome = e.Nome AND x.Cidade = e.Cidade);

-- ---------- Setores (os mesmos 3 em todos os estadios; precos FICTICIOS) ----------
-- Capacidade = numero de assentos criados no setor. Prefixo = letra do numero do assento.
DECLARE @Setores TABLE (NomeSetor varchar(50), Prefixo varchar(1), Capacidade int, PrecoBase decimal(10,2));
INSERT INTO @Setores (NomeSetor, Prefixo, Capacidade, PrecoBase) VALUES
    ('Arquibancada Inferior', 'A', 10,  450.00),
    ('Arquibancada Superior', 'B', 10,  250.00),
    ('Camarote',              'C',  5, 1200.00);

INSERT INTO Setor (EstadioID, NomeSetor, Capacidade, PrecoBase)
SELECT e.EstadioID, s.NomeSetor, s.Capacidade, s.PrecoBase
FROM Estadio e
INNER JOIN @Estadios se ON se.Nome = e.Nome AND se.Cidade = e.Cidade
CROSS JOIN @Setores s
WHERE NOT EXISTS (SELECT 1 FROM Setor x WHERE x.EstadioID = e.EstadioID AND x.NomeSetor = s.NomeSetor);

-- ---------- Assentos (A01..A10, B01..B10, C01..C05) ----------
;WITH Numeros AS (
    SELECT 1 AS N
    UNION ALL
    SELECT N + 1 FROM Numeros WHERE N < 10
)
INSERT INTO Assento (SetorID, Numero)
SELECT st.SetorID, c.Numero
FROM Setor st
INNER JOIN Estadio e ON e.EstadioID = st.EstadioID
INNER JOIN @Estadios se ON se.Nome = e.Nome AND se.Cidade = e.Cidade
INNER JOIN @Setores s ON s.NomeSetor = st.NomeSetor
INNER JOIN Numeros n ON n.N <= s.Capacidade
CROSS APPLY (SELECT s.Prefixo + RIGHT('0' + CAST(n.N AS varchar(2)), 2) AS Numero) c
WHERE NOT EXISTS (SELECT 1 FROM Assento x WHERE x.SetorID = st.SetorID AND x.Numero = c.Numero);

-- ---------- Jogos (os 6 de 1.html/index.html; horario 16:00 e fase FICTICIOS) ----------
DECLARE @Jogos TABLE (EstadioNome varchar(100), Cidade varchar(100), Dia varchar(8), TimeA varchar(50), TimeB varchar(50));
INSERT INTO @Jogos (EstadioNome, Cidade, Dia, TimeA, TimeB) VALUES
    ('Estádio Azteca',         'Cidade do México', '20260611', 'México',         'Canadá'),
    ('SoFi Stadium',           'Los Angeles',      '20260612', 'Estados Unidos', 'Uruguai'),
    ('AT&T Stadium',           'Dallas',           '20260615', 'Brasil',         'Sérvia'),
    ('Mercedes-Benz Stadium',  'Atlanta',          '20260616', 'Argentina',      'Dinamarca'),
    ('BC Place',               'Vancouver',        '20260617', 'França',         'Chile'),
    ('MetLife Stadium',        'Nova Jersey',      '20260618', 'Alemanha',       'Japão');

INSERT INTO Jogo (EstadioID, DataHora, TimeA, TimeB, Fase)
SELECT e.EstadioID, DATEADD(HOUR, 16, CONVERT(datetime, sj.Dia, 112)), sj.TimeA, sj.TimeB, 'Fase de grupos'
FROM @Jogos sj
INNER JOIN Estadio e ON e.Nome = sj.EstadioNome AND e.Cidade = sj.Cidade
WHERE NOT EXISTS (SELECT 1 FROM Jogo x WHERE x.EstadioID = e.EstadioID AND x.TimeA = sj.TimeA AND x.TimeB = sj.TimeB);

-- ---------- Ingressos: um por assento do estadio de cada jogo acima ----------
-- PrecoFinal = PrecoBase do setor. Status DISPONIVEL (padrao da coluna).
INSERT INTO Ingresso (JogoID, SetorID, AssentoID, NumeroAssento, PrecoFinal, Status)
SELECT j.JogoID, st.SetorID, a.AssentoID, a.Numero, st.PrecoBase, 'DISPONIVEL'
FROM @Jogos sj
INNER JOIN Estadio e ON e.Nome = sj.EstadioNome AND e.Cidade = sj.Cidade
INNER JOIN Jogo j ON j.EstadioID = e.EstadioID AND j.TimeA = sj.TimeA AND j.TimeB = sj.TimeB
INNER JOIN Setor st ON st.EstadioID = e.EstadioID
INNER JOIN Assento a ON a.SetorID = st.SetorID
WHERE NOT EXISTS (
    SELECT 1 FROM Ingresso x
    WHERE x.JogoID = j.JogoID AND x.SetorID = st.SetorID AND x.AssentoID = a.AssentoID
);

COMMIT TRANSACTION;

-- Conferencia: com um banco limpo, o esperado e 7 / 21 / 175 / 6 / 150.
SELECT
    (SELECT COUNT(*) FROM Estadio)  AS Estadios,
    (SELECT COUNT(*) FROM Setor)    AS Setores,
    (SELECT COUNT(*) FROM Assento)  AS Assentos,
    (SELECT COUNT(*) FROM Jogo)     AS Jogos,
    (SELECT COUNT(*) FROM Ingresso) AS Ingressos;
GO

/*
-- ---------- Promover o primeiro administrador (so se a coluna Usuario.Perfil existir) ----------
-- O cadastro cria sempre o perfil CLIENTE. Depois de cadastrar o usuario pelo sistema:
-- UPDATE Usuario SET Perfil = 'ADMIN' WHERE Email = 'email@exemplo.com';

-- ---------- Limpeza (APAGA TUDO; use so em banco de teste) ----------
-- Ordem inversa das chaves estrangeiras. Nao roda se ja houver vendas ligadas aos ingressos.
-- DELETE FROM QRCode;
-- DELETE FROM ItemVenda;
-- DELETE FROM Venda;
-- DELETE FROM Ingresso;
-- DELETE FROM Jogo;
-- DELETE FROM Assento;
-- DELETE FROM Setor;
-- DELETE FROM Estadio;
*/
