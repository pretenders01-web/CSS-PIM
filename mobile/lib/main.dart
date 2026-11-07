import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'config/configuracao_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(orientacoesDoApp);

  runApp(MundialTicketsApp(configuracao: ConfiguracaoApi.doAmbiente()));
}
