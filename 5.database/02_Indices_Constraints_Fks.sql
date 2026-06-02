/****** Objeto:  Index [IX_Ingresso_Status]    Data do Script: 01/06/2026 21:40:55 ******/
CREATE NONCLUSTERED INDEX [IX_Ingresso_Status] ON [dbo].[Ingresso]
(
	[Status] ASC
)
INCLUDE([JogoID],[SetorID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto:  Index [UQ_Ingresso_Jogo_Setor_Assento]    Data do Script: 01/06/2026 21:40:55 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Ingresso_Jogo_Setor_Assento] ON [dbo].[Ingresso]
(
	[JogoID] ASC,
	[SetorID] ASC,
	[AssentoID] ASC
)
WHERE ([AssentoID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto:  Index [IX_ItemVenda_VendaID]    Data do Script: 01/06/2026 21:40:55 ******/
CREATE NONCLUSTERED INDEX [IX_ItemVenda_VendaID] ON [dbo].[ItemVenda]
(
	[VendaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto:  Index [IX_Jogo_DataHora]    Data do Script: 01/06/2026 21:40:55 ******/
CREATE NONCLUSTERED INDEX [IX_Jogo_DataHora] ON [dbo].[Jogo]
(
	[DataHora] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto:  Index [IX_Usuario_Email]    Data do Script: 01/06/2026 21:40:55 ******/
CREATE NONCLUSTERED INDEX [IX_Usuario_Email] ON [dbo].[Usuario]
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto:  Index [IX_Venda_UsuarioID]    Data do Script: 01/06/2026 21:40:55 ******/
CREATE NONCLUSTERED INDEX [IX_Venda_UsuarioID] ON [dbo].[Venda]
(
	[UsuarioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Ingresso] ADD  DEFAULT ('DISPONIVEL') FOR [Status]
GO
ALTER TABLE [dbo].[Ingresso] ADD  DEFAULT (getdate()) FOR [DataCriacao]
GO
ALTER TABLE [dbo].[QRCode] ADD  DEFAULT ((0)) FOR [Utilizado]
GO
ALTER TABLE [dbo].[Usuario] ADD  DEFAULT (getdate()) FOR [DataCadastro]
GO
ALTER TABLE [dbo].[Usuario] ADD  DEFAULT ((1)) FOR [Ativo]
GO
ALTER TABLE [dbo].[Venda] ADD  DEFAULT (getdate()) FOR [DataVenda]
GO
ALTER TABLE [dbo].[Venda] ADD  DEFAULT ('PENDENTE') FOR [StatusPagamento]
GO
ALTER TABLE [dbo].[Assento]  WITH CHECK ADD  CONSTRAINT [FK_Assento_Setor] FOREIGN KEY([SetorID])
REFERENCES [dbo].[Setor] ([SetorID])
GO
ALTER TABLE [dbo].[Assento] CHECK CONSTRAINT [FK_Assento_Setor]
GO
ALTER TABLE [dbo].[Ingresso]  WITH CHECK ADD  CONSTRAINT [FK_Ingresso_Assento] FOREIGN KEY([AssentoID])
REFERENCES [dbo].[Assento] ([AssentoID])
GO
ALTER TABLE [dbo].[Ingresso] CHECK CONSTRAINT [FK_Ingresso_Assento]
GO
ALTER TABLE [dbo].[Ingresso]  WITH CHECK ADD  CONSTRAINT [FK_Ingresso_Jogo] FOREIGN KEY([JogoID])
REFERENCES [dbo].[Jogo] ([JogoID])
GO
ALTER TABLE [dbo].[Ingresso] CHECK CONSTRAINT [FK_Ingresso_Jogo]
GO
ALTER TABLE [dbo].[Ingresso]  WITH CHECK ADD  CONSTRAINT [FK_Ingresso_Setor] FOREIGN KEY([SetorID])
REFERENCES [dbo].[Setor] ([SetorID])
GO
ALTER TABLE [dbo].[Ingresso] CHECK CONSTRAINT [FK_Ingresso_Setor]
GO
ALTER TABLE [dbo].[ItemVenda]  WITH CHECK ADD  CONSTRAINT [FK_ItemVenda_Ingresso] FOREIGN KEY([IngressoID])
REFERENCES [dbo].[Ingresso] ([IngressoID])
GO
ALTER TABLE [dbo].[ItemVenda] CHECK CONSTRAINT [FK_ItemVenda_Ingresso]
GO
ALTER TABLE [dbo].[ItemVenda]  WITH CHECK ADD  CONSTRAINT [FK_ItemVenda_Venda] FOREIGN KEY([VendaID])
REFERENCES [dbo].[Venda] ([VendaID])
GO
ALTER TABLE [dbo].[ItemVenda] CHECK CONSTRAINT [FK_ItemVenda_Venda]
GO
ALTER TABLE [dbo].[Jogo]  WITH CHECK ADD  CONSTRAINT [FK_Jogo_Estadio] FOREIGN KEY([EstadioID])
REFERENCES [dbo].[Estadio] ([EstadioID])
GO
ALTER TABLE [dbo].[Jogo] CHECK CONSTRAINT [FK_Jogo_Estadio]
GO
ALTER TABLE [dbo].[QRCode]  WITH CHECK ADD  CONSTRAINT [FK_QRCode_Ingresso] FOREIGN KEY([IngressoID])
REFERENCES [dbo].[Ingresso] ([IngressoID])
GO
ALTER TABLE [dbo].[QRCode] CHECK CONSTRAINT [FK_QRCode_Ingresso]
GO
ALTER TABLE [dbo].[QRCode]  WITH CHECK ADD  CONSTRAINT [FK_QRCode_Venda] FOREIGN KEY([VendaID])
REFERENCES [dbo].[Venda] ([VendaID])
GO
ALTER TABLE [dbo].[QRCode] CHECK CONSTRAINT [FK_QRCode_Venda]
GO
ALTER TABLE [dbo].[Setor]  WITH CHECK ADD  CONSTRAINT [FK_Setor_Estadio] FOREIGN KEY([EstadioID])
REFERENCES [dbo].[Estadio] ([EstadioID])
GO
ALTER TABLE [dbo].[Setor] CHECK CONSTRAINT [FK_Setor_Estadio]
GO
ALTER TABLE [dbo].[Venda]  WITH CHECK ADD  CONSTRAINT [FK_Venda_Usuario] FOREIGN KEY([UsuarioID])
REFERENCES [dbo].[Usuario] ([UsuarioID])
GO
ALTER TABLE [dbo].[Venda] CHECK CONSTRAINT [FK_Venda_Usuario]
GO
ALTER TABLE [dbo].[Estadio]  WITH CHECK ADD CHECK  (([CapacidadeTotal]>(0)))
GO
ALTER TABLE [dbo].[Ingresso]  WITH CHECK ADD CHECK  (([Status]='CANCELADO' OR [Status]='VENDIDO' OR [Status]='RESERVADO' OR [Status]='DISPONIVEL'))
GO
ALTER TABLE [dbo].[Setor]  WITH CHECK ADD CHECK  (([Capacidade]>(0)))
GO
ALTER TABLE [dbo].[Venda]  WITH CHECK ADD CHECK  (([StatusPagamento]='ESTORNADO' OR [StatusPagamento]='CANCELADO' OR [StatusPagamento]='APROVADO' OR [StatusPagamento]='PENDENTE'))
GO
