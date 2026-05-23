CREATE TABLE Usuario (
    UsuarioID INT IDENTITY(1,1) PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Email VARCHAR(150) NOT NULL UNIQUE,
    SenhaHash VARCHAR(255) NOT NULL,      -- Armazenar hash (ex: bcrypt)
    CPF VARCHAR(14) NULL,                 
    DataCadastro DATETIME DEFAULT GETDATE(),
    Ativo BIT DEFAULT 1
);

CREATE TABLE Estadio (
    EstadioID INT IDENTITY(1,1) PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Cidade VARCHAR(100) NOT NULL,
    CapacidadeTotal INT NOT NULL CHECK (CapacidadeTotal > 0)
);

CREATE TABLE Setor (
    SetorID INT IDENTITY(1,1) PRIMARY KEY,
    EstadioID INT NOT NULL,
    NomeSetor VARCHAR(50) NOT NULL,       
    Capacidade INT NOT NULL CHECK (Capacidade > 0),
    PrecoBase DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Setor_Estadio FOREIGN KEY (EstadioID) 
        REFERENCES Estadio(EstadioID),
    CONSTRAINT UQ_Setor_Estadio UNIQUE (EstadioID, NomeSetor) 
);


CREATE TABLE Jogo (
    JogoID INT IDENTITY(1,1) PRIMARY KEY,
    EstadioID INT NOT NULL,
    DataHora DATETIME NOT NULL,
    TimeA VARCHAR(50) NOT NULL,
    TimeB VARCHAR(50) NOT NULL,
    Fase VARCHAR(30) NOT NULL,             -- Ex: 'Fase de Grupos', 'Oitavas', 'Final'
    CONSTRAINT FK_Jogo_Estadio FOREIGN KEY (EstadioID) 
        REFERENCES Estadio(EstadioID),
    CONSTRAINT UQ_Jogo_Estadio_DataHora UNIQUE (EstadioID, DataHora) 
);

CREATE TABLE Assento (
    AssentoID INT IDENTITY(1,1) PRIMARY KEY,
    SetorID INT NOT NULL,
    Numero VARCHAR(10) NOT NULL,            -- Ex: 'A12', 'B5'
    CONSTRAINT FK_Assento_Setor FOREIGN KEY (SetorID) 
        REFERENCES Setor(SetorID),
    CONSTRAINT UQ_Assento_Setor_Numero UNIQUE (SetorID, Numero)
);

CREATE TABLE Ingresso (
    IngressoID INT IDENTITY(1,1) PRIMARY KEY,
    JogoID INT NOT NULL,
    SetorID INT NOT NULL,
    AssentoID INT NULL,                    
    NumeroAssento VARCHAR(10) NULL,         
    PrecoFinal DECIMAL(10,2) NOT NULL,
    Status VARCHAR(20) DEFAULT 'DISPONIVEL' CHECK (Status IN ('DISPONIVEL', 'RESERVADO', 'VENDIDO', 'CANCELADO')),
    DataCriacao DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Ingresso_Jogo FOREIGN KEY (JogoID) 
        REFERENCES Jogo(JogoID),
    CONSTRAINT FK_Ingresso_Setor FOREIGN KEY (SetorID) 
        REFERENCES Setor(SetorID),
    CONSTRAINT FK_Ingresso_Assento FOREIGN KEY (AssentoID) 
        REFERENCES Assento(AssentoID),
    CONSTRAINT UQ_Ingresso_Jogo_Setor_Assento UNIQUE (JogoID, SetorID, AssentoID)
);

CREATE TABLE Venda (
    VendaID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL,
    DataVenda DATETIME DEFAULT GETDATE(),
    ValorTotal DECIMAL(10,2) NOT NULL,
    StatusPagamento VARCHAR(20) DEFAULT 'PENDENTE' CHECK (StatusPagamento IN ('PENDENTE', 'APROVADO', 'CANCELADO', 'ESTORNADO')),
    MetodoPagamento VARCHAR(30) NULL,      
    CONSTRAINT FK_Venda_Usuario FOREIGN KEY (UsuarioID) 
        REFERENCES Usuario(UsuarioID)
);

CREATE TABLE ItemVenda (
    ItemVendaID INT IDENTITY(1,1) PRIMARY KEY,
    VendaID INT NOT NULL,
    IngressoID INT NOT NULL UNIQUE,         
    PrecoUnitario DECIMAL(10,2) NOT NULL,  
    CONSTRAINT FK_ItemVenda_Venda FOREIGN KEY (VendaID) 
        REFERENCES Venda(VendaID),
    CONSTRAINT FK_ItemVenda_Ingresso FOREIGN KEY (IngressoID) 
        REFERENCES Ingresso(IngressoID)
);

CREATE TABLE QRCode (
    QRCodeID INT IDENTITY(1,1) PRIMARY KEY,
    VendaID INT NOT NULL,
    IngressoID INT NOT NULL UNIQUE,        
    CodigoQR VARCHAR(255) NOT NULL UNIQUE,  
    DataExpiracao DATETIME NOT NULL,  
    Utilizado BIT DEFAULT 0,
    CONSTRAINT FK_QRCode_Venda FOREIGN KEY (VendaID) 
        REFERENCES Venda(VendaID),
    CONSTRAINT FK_QRCode_Ingresso FOREIGN KEY (IngressoID) 
        REFERENCES Ingresso(IngressoID)
);

CREATE INDEX IX_Usuario_Email ON Usuario(Email);
CREATE INDEX IX_Jogo_DataHora ON Jogo(DataHora);
CREATE INDEX IX_Ingresso_Status ON Ingresso(Status) INCLUDE (JogoID, SetorID);
CREATE INDEX IX_Venda_UsuarioID ON Venda(UsuarioID);
CREATE INDEX IX_ItemVenda_VendaID ON ItemVenda(VendaID);