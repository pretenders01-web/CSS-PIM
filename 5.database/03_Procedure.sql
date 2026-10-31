/****** Objeto:  StoredProcedure [dbo].[sp_RealizarCompra]    Data do Script: 01/06/2026 21:40:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[sp_RealizarCompra]
    @UsuarioID INT,
    @Ingressos VARCHAR(MAX),
    @MetodoPagamento VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    -- Validar lista vazia ou nula
    IF @Ingressos IS NULL
       OR LTRIM(RTRIM(@Ingressos)) = ''
    BEGIN
        ;THROW 50010, 'Informe ao menos um ingresso para realizar a compra.', 1;
    END;

    -- Validar IDs vazios, nao numericos ou nao positivos
    IF EXISTS (
        SELECT 1
        FROM STRING_SPLIT(@Ingressos, ',') AS s
        WHERE NULLIF(LTRIM(RTRIM(s.value)), '') IS NULL
           OR TRY_CONVERT(INT, LTRIM(RTRIM(s.value))) IS NULL
           OR TRY_CONVERT(INT, LTRIM(RTRIM(s.value))) <= 0
    )
    BEGIN
        ;THROW 50011, 'A lista de ingressos contem IDs invalidos ou vazios.', 1;
    END;

    -- Validar ingressos inexistentes
    IF EXISTS (
        SELECT 1
        FROM STRING_SPLIT(@Ingressos, ',') AS s
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.Ingresso AS i
            WHERE i.IngressoID =
                TRY_CONVERT(INT, LTRIM(RTRIM(s.value)))
        )
    )
    BEGIN
        ;THROW 50012, 'Um ou mais ingressos informados nao existem.', 1;
    END;

    -- Validar ingressos repetidos
    IF EXISTS (
        SELECT 1
        FROM STRING_SPLIT(@Ingressos, ',') AS s
        GROUP BY TRY_CONVERT(INT, LTRIM(RTRIM(s.value)))
        HAVING COUNT(*) > 1
    )
    BEGIN
        ;THROW 50013, 'A lista contem ingressos repetidos.', 1;
    END;

    DECLARE @VendaID INT;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO Venda (UsuarioID, ValorTotal, StatusPagamento, MetodoPagamento)
        VALUES (@UsuarioID, 0, 'PENDENTE', @MetodoPagamento);
        SET @VendaID = SCOPE_IDENTITY();

        INSERT INTO ItemVenda (VendaID, IngressoID, PrecoUnitario)
        SELECT @VendaID, value, (SELECT PrecoFinal FROM Ingresso WHERE IngressoID = value)
        FROM STRING_SPLIT(@Ingressos, ',');

        UPDATE Venda SET StatusPagamento = 'APROVADO' WHERE VendaID = @VendaID;
        COMMIT TRANSACTION;

        SELECT qr.CodigoQR, j.DataHora AS DataJogo, j.TimeA + ' x ' + j.TimeB AS Partida
        FROM QRCode qr
        INNER JOIN Ingresso i ON qr.IngressoID = i.IngressoID
        INNER JOIN Jogo j ON i.JogoID = j.JogoID
        WHERE qr.VendaID = @VendaID;

        PRINT 'Compra realizada com sucesso!';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
GO
