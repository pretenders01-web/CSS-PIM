import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'config/configuracao_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // O app foi desenhado só para retrato.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MundialTicketsApp(configuracao: ConfiguracaoApi.doAmbiente()));
}
