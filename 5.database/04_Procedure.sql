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
