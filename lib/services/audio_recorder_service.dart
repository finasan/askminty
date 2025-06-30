// lib/services/audio_recorder_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  FlutterSoundRecorder? _recorder;
  bool _isInitialized = false;
  String? _recordingPath; // Para armazenar o caminho da gravação atual

  // Construtor privado para o Singleton
  AudioRecorderService._privateConstructor();

  // Instância única do Singleton
  static final AudioRecorderService _instance = AudioRecorderService._privateConstructor();

  // Getter para acessar a instância do Singleton
  static AudioRecorderService get instance => _instance;

  Future<void> initRecorder() async {
    if (_isInitialized && _recorder != null && _recorder!.isOpen) { // CORRIGIDO: Usando .isOpen
      debugPrint("AudioRecorderService: Gravador já inicializado.");
      return;
    }

    if (Platform.isIOS) {
      debugPrint("AudioRecorderService (iOS): Tentando inicializar gravador.");
      var status = await Permission.microphone.status;
      debugPrint("AudioRecorderService (iOS): Status da permissão do microfone: $status");

      if (status != PermissionStatus.granted) {
        debugPrint("AudioRecorderService (iOS): Permissão não concedida. Não é possível inicializar o gravador.");
        _isInitialized = false;
        return;
      }

      try {
        _recorder = FlutterSoundRecorder();
        await _recorder!.openRecorder();
        debugPrint("AudioRecorderService (iOS): Gravador aberto com sucesso.");
        _isInitialized = true;
      } catch (e) {
        debugPrint("AudioRecorderService (iOS): ERRO ao abrir gravador: $e");
        _isInitialized = false;
        if (e.toString().contains("Permission denied") || e.toString().contains("AVAudioSession")) {
          debugPrint("AudioRecorderService (iOS): Possível problema de AVAudioSession ou permissão mais profunda.");
        }
      }
    } else if (Platform.isAndroid) {
      debugPrint("AudioRecorderService (Android): Inicializando gravador.");
      var status = await Permission.microphone.status;
      if (status != PermissionStatus.granted) {
        debugPrint("AudioRecorderService (Android): Permissão não concedida. Não é possível inicializar o gravador.");
        _isInitialized = false;
        return;
      }
      try {
        _recorder = FlutterSoundRecorder();
        await _recorder!.openRecorder();
        debugPrint("AudioRecorderService (Android): Gravador aberto com sucesso.");
        _isInitialized = true;
      } catch (e) {
        debugPrint("AudioRecorderService (Android): ERRO ao abrir gravador: $e");
        _isInitialized = false;
      }
    } else {
      debugPrint("AudioRecorderService: Inicialização do gravador para plataforma não suportada.");
      _isInitialized = false;
    }
  }

  bool isRecording() {
    return _recorder?.isRecording ?? false;
  }

  // RETORNA Future<String?>
  Future<String?> startRecording() async {
    if (!_isInitialized) {
      debugPrint("AudioRecorderService: Gravador não inicializado. Tentando inicializar agora.");
      await initRecorder(); // Tenta inicializar se não estiver
      if (!_isInitialized) {
        debugPrint("AudioRecorderService: Falha ao inicializar o gravador. Não é possível iniciar a gravação.");
        return null; // Retorna null para indicar falha
      }
    }

    if (_recorder!.isRecording) {
      debugPrint("AudioRecorderService: Já está gravando.");
      return _recordingPath; // Retorna o caminho atual se já estiver gravando
    }

    debugPrint("AudioRecorderService: Tentando iniciar a gravação.");
    try {
      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/finasana_audio_record.aac';
      debugPrint("AudioRecorderService: Gravando em: $_recordingPath");
      await _recorder!.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );
      debugPrint("AudioRecorderService: Gravação iniciada.");
      return _recordingPath;
    } catch (e) {
      debugPrint("AudioRecorderService: ERRO ao iniciar a gravação: $e");
      _recordingPath = null;
      return null;
    }
  }

  // RETORNA Future<String?>
  Future<String?> stopRecording() async {
    if (_recorder == null || !_recorder!.isRecording) {
      debugPrint("AudioRecorderService: Nenhuma gravação ativa para parar.");
      return null;
    }
    debugPrint("AudioRecorderService: Tentando parar a gravação.");
    try {
      final path = await _recorder!.stopRecorder();
      debugPrint("AudioRecorderService: Gravação parada. Arquivo: $path");
      _recordingPath = null; // Limpar caminho da gravação atual
      return path;
    } catch (e) {
      debugPrint("AudioRecorderService: ERRO ao parar a gravação: $e");
      _recordingPath = null;
      return null;
    }
  }

  Future<void> disposeRecorder() async {
    if (_recorder != null && _recorder!.isOpen) { // CORRIGIDO: Usando .isOpen
      debugPrint("AudioRecorderService: Descartando gravador.");
      try {
        await _recorder!.closeRecorder();
        _recorder = null;
        _isInitialized = false;
      } catch (e) {
        debugPrint("AudioRecorderService: Erro ao descartar gravador: $e");
      }
    }
  }
}