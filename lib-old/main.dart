// main.dart (Flutter WebView TESTE MÍNIMO com print corrigido e aspas duplas)

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teste WebView Handler',
      home: const WebViewTestPage(),
    );
  }
}

class WebViewTestPage extends StatefulWidget {
  const WebViewTestPage({super.key});

  @override
  State<WebViewTestPage> createState() => _WebViewTestPageState();
}

class _WebViewTestPageState extends State<WebViewTestPage> {
  InAppWebViewController? _controller;

  final String _htmlContent = '''
  <!DOCTYPE html>
  <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>WebView Handler Test</title>
    </head>
    <body style="font-family: sans-serif; text-align: center; margin-top: 50px;">
      <h2>Testar comunicação com Flutter</h2>
      <button onclick="testFlutter()" style="font-size: 20px; padding: 10px 20px;">🔁 Testar</button>
      <script>
        async function testFlutter() {
          if (window.flutter_inappwebview) {
            try {
              const res = await window.flutter_inappwebview.callHandler('native', ['test']);
              alert("Resposta: " + res);
            } catch (e) {
              alert("Erro: " + e);
            }
          } else {
            alert("flutter_inappwebview não disponível");
          }
        }
      </script>
    </body>
  </html>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView Test')),
      body: InAppWebView(
        initialData: InAppWebViewInitialData(data: _htmlContent),
        onWebViewCreated: (controller) {
          _controller = controller;

          controller.addJavaScriptHandler(
            handlerName: 'native',
            callback: (args) {
              print("✅ Flutter recebeu callHandler args: $args (${args.runtimeType})");
              for (int i = 0; i < args.length; i++) {
                print("🔹 Arg[$i] = ${args[i]} (${args[i].runtimeType})");
              }
              if (args.isNotEmpty && args[0].toString().toLowerCase() == 'test') {
                return 'Flutter OK!';
              }
              return 'Comando desconhecido';
            },
          );
        },
      ),
    );
  }
}