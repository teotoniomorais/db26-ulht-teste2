-- Aluno: [Teotónio Morais]
-- Numero: [a22513721]
-- Turma: []
-- Horário: [8h às 10h]
-- Caso de estudo: [Consultas médicas]

CREATE SCHEMA a22513721;


GO
CREATE TABLE MEDICO (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Nome NVARCHAR(100) NOT NULL,
    NumeroOrdem VARCHAR(30) NOT NULL UNIQUE,
    Especialidade NVARCHAR(100),
    Telefone VARCHAR(20),
    Email VARCHAR(150)
);


GO
CREATE TABLE PACIENTE (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Nome NVARCHAR(100) NOT NULL,
    DataNascimento DATE,
    Telefone VARCHAR(20),
    Email VARCHAR(150),
    Morada NVARCHAR(200)
);


GO
CREATE TABLE CONSULTA (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MedicoID INT NULL,
    PacienteID INT NOT NULL,
    DataHora DATETIME2(0) NOT NULL,
    Motivo NVARCHAR(250),
    Observacoes NVARCHAR(MAX),
    Estado NVARCHAR(20) NOT NULL DEFAULT N'Agendada',
    CONSTRAINT FK_CONSULTA_MEDICO
        FOREIGN KEY (MedicoID) REFERENCES MEDICO(ID)
        ON DELETE SET NULL,
    CONSTRAINT FK_CONSULTA_PACIENTE
        FOREIGN KEY (PacienteID) REFERENCES PACIENTE(ID),
    CONSTRAINT UQ_CONSULTA_MEDICO_DATAHORA UNIQUE (MedicoID, DataHora),
    CONSTRAINT UQ_CONSULTA_PACIENTE_DATAHORA UNIQUE (PacienteID, DataHora),
    CONSTRAINT CK_CONSULTA_ESTADO
        CHECK (Estado IN (N'Agendada', N'Realizada', N'Cancelada'))
);



GO
-- 2. Insercoes: paciente com uma consulta, paciente com tres consultas
-- e medico sem consultas agendadas.
INSERT INTO MEDICO
    (Nome, NumeroOrdem, Especialidade, Telefone, Email)
VALUES
    (N'Dra. Sara Alves', 'OM-1001', N'Medicina Geral', '910000001', 'sara.alves@example.test'),
    (N'Dr. Breno Reis', 'OM-1002', N'Pediatria', '910000002', 'breno.reis@example.test'),
    (N'Dra. Carla Nunes', 'OM-1003', N'Dermatologia', '910000003', 'carla.nunes@example.test');

INSERT INTO PACIENTE
    (Nome, DataNascimento, Telefone, Email, Morada)
VALUES
    (N'Paula Lima', '1985-04-12', '920000001', 'paula.lima@example.test', N'Rua das Flores, 10'),
    (N'Nuno Costa', '1990-08-23', '920000002', 'nuno.costa@example.test', N'Av. Central, 20'),
    (N'Ana Pinto', '2001-02-05', '920000003', 'ana.pinto@example.test', N'Rua Nova, 30');

DECLARE @MedicoSara INT, @MedicoBreno INT, @PacientePaula INT,
        @PacienteNuno INT, @PacienteAna INT;

SELECT @MedicoSara = ID FROM MEDICO WHERE NumeroOrdem = 'OM-1001';
SELECT @MedicoBreno = ID FROM MEDICO WHERE NumeroOrdem = 'OM-1002';
SELECT @PacientePaula = ID FROM PACIENTE WHERE Email = 'paula.lima@example.test';
SELECT @PacienteNuno = ID FROM PACIENTE WHERE Email = 'nuno.costa@example.test';
SELECT @PacienteAna = ID FROM PACIENTE WHERE Email = 'sara.pinto@example.test';

INSERT INTO CONSULTA
    (MedicoID, PacienteID, DataHora, Motivo, Observacoes, Estado)
VALUES
    (@MedicoSara, @PacientePaula, '2026-12-01T08:00:00', N'Consulta de rotina', N'Primeira consulta.', N'Agendada'),
    (@MedicoSara, @PacienteNuno,  '2026-12-02T08:00:00', N'Acompanhamento', N'Rever na proxima consulta.', N'Agendada'),
    (@MedicoSara, @PacienteNuno,  '2026-12-03T09:00:00', N'Reavaliacao', N'Acompanhamento do paciente.', N'Agendada'),
    (@MedicoBreno, @PacienteNuno, '2026-12-04T10:00:00', N'Consulta de controlo', N'Sem observacoes adicionais.', N'Agendada'),
    (@MedicoBreno, @PacienteAna, '2026-12-02T09:00:00', N'Consulta inicial', N'Avaliar queixa apresentada.', N'Agendada');

PRINT N'Todos os dados inseridos:';
SELECT * FROM MEDICO;
SELECT * FROM PACIENTE;
SELECT * FROM CONSULTA;

PRINT N'Agenda dos medicos com mais de uma consulta agendada (sem identificadores):';
SELECT m.Nome AS Medico, p.Nome AS Paciente, c.DataHora AS Horario
FROM CONSULTA AS c
JOIN MEDICO AS m ON m.ID = c.MedicoID
JOIN PACIENTE AS p ON p.ID = c.PacienteID
WHERE c.Estado = N'Agendada'
  AND c.MedicoID IN (
      SELECT MedicoID
      FROM CONSULTA
      WHERE Estado = N'Agendada'
      GROUP BY MedicoID
      HAVING COUNT(*) > 1
  )
ORDER BY m.Nome, c.DataHora;

PRINT N'Medicos sem consultas agendadas:';
SELECT m.Nome AS Medico
FROM MEDICO AS m
WHERE NOT EXISTS (
    SELECT 1
    FROM CONSULTA AS c
    WHERE c.MedicoID = m.ID
      AND c.Estado = N'Agendada'
);

-- 3. Acrescenta diagnostico, opcional, mas com pelo menos 10 caracteres
-- quando preenchido.
ALTER TABLE CONSULTA
ADD Diagnostico NVARCHAR(500) NULL;

ALTER TABLE CONSULTA
ADD CONSTRAINT CK_CONSULTA_DIAGNOSTICO
CHECK (
    Diagnostico IS NULL
    OR LEN(LTRIM(RTRIM(Diagnostico))) = 0
    OR LEN(LTRIM(RTRIM(Diagnostico))) >= 10
);

UPDATE CONSULTA
SET Diagnostico = CASE Motivo
    WHEN N'Consulta de rotina' THEN N'Acompanhamento de rotina'
    WHEN N'Acompanhamento' THEN N'Observacao clinica'
    WHEN N'Reavaliacao' THEN N'Reavaliacao clinica'
    WHEN N'Consulta de controlo' THEN N'Controlo periodico'
    WHEN N'Consulta inicial' THEN NULL
    ELSE N'Avaliacao inicial'
END;

PRINT N'Todos os dados da tabela alterada (CONSULTA):';
SELECT * FROM CONSULTA;

PRINT N'Historico do paciente Nuno Costa, incluindo diagnosticos:';
SELECT p.Nome AS Paciente, c.DataHora, m.Nome AS Medico,
       c.Motivo, c.Diagnostico, c.Estado
FROM CONSULTA AS c
JOIN PACIENTE AS p ON p.ID = c.PacienteID
LEFT JOIN MEDICO AS m ON m.ID = c.MedicoID
WHERE p.ID = @PacienteNuno
ORDER BY c.DataHora;

-- 4. Corrige a identificacao (nome e contacto) do paciente.
UPDATE PACIENTE
SET Nome = N'Nuno Rodrigues',
    Telefone = '920000022',
    Email = 'nuno.rodrigues@example.test'
WHERE ID = @PacienteNuno;

PRINT N'Historico do paciente apos a correcao da identificacao:';
SELECT p.Nome AS Paciente, c.DataHora, m.Nome AS Medico,
       c.Motivo, c.Diagnostico, c.Estado
FROM CONSULTA AS c
JOIN PACIENTE AS p ON p.ID = c.PacienteID
LEFT JOIN MEDICO AS m ON m.ID = c.MedicoID
WHERE p.ID = @PacienteNuno
ORDER BY c.DataHora;

-- 5. Remove um medico com consultas agendadas. As consultas mantem-se
-- no historico, sem referencia ao medico removido.
DELETE FROM MEDICO
WHERE ID = @MedicoSara;

PRINT N'Historico do paciente que tinha consultas com a medica removida:';
SELECT p.Nome AS Paciente, c.DataHora,
       COALESCE(m.Nome, N'Medico removido') AS Medico,
       c.Motivo, c.Diagnostico, c.Estado
FROM CONSULTA AS c
JOIN PACIENTE AS p ON p.ID = c.PacienteID
LEFT JOIN MEDICO AS m ON m.ID = c.MedicoID
WHERE p.ID = @PacienteNuno
ORDER BY c.DataHora;

-- 6. Apaga todos os registos e confirma que as tabelas estao vazias.
DELETE FROM CONSULTA;
DELETE FROM PACIENTE;
DELETE FROM MEDICO;

PRINT N'Contagem de registos apos apagar os dados (todas devem ser zero):';
SELECT N'MEDICO' AS Tabela, COUNT(*) AS Registos FROM MEDICO
UNION ALL
SELECT N'PACIENTE', COUNT(*) FROM PACIENTE
UNION ALL
SELECT N'CONSULTA', COUNT(*) FROM CONSULTA;

SELECT * FROM MEDICO;
SELECT * FROM PACIENTE;
SELECT * FROM CONSULTA;

-- 7. Apaga as tabelas e no fim o schema.
DROP TABLE CONSULTA;
DROP TABLE PACIENTE;
DROP TABLE MEDICO;
GO
DROP SCHEMA ;

