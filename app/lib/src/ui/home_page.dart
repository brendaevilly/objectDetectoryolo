import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../camera/image_prep.dart';
import '../config.dart';
import '../protocol/tcp_client.dart';
import 'widgets/result_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _hostController = TextEditingController(text: AppConfig.defaultHost);
  final _portController = TextEditingController(
    text: AppConfig.defaultPort.toString(),
  );
  final _picker = ImagePicker();
  final _client = TcpClient();

  CameraController? _camera;
  bool _cameraReady = false;
  Uint8List? _preview;
  List<String> _labels = [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restoreSettings();
    _initCamera();
  }

  Future<void> _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hostController.text = prefs.getString('host') ?? AppConfig.defaultHost;
      _portController.text =
          (prefs.getInt('port') ?? AppConfig.defaultPort).toString();
    });
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('host', _hostController.text.trim());
    await prefs.setInt('port', int.parse(_portController.text.trim()));
  }

  Future<void> _initCamera() async {
    final granted = await Permission.camera.request();
    if (!granted.isGranted) {
      setState(() => _error = 'Permissão da câmera negada.');
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Nenhuma câmera encontrada.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _camera = controller;
        _cameraReady = true;
      });
    } catch (e) {
      setState(() => _error = 'Falha ao iniciar a câmera: $e');
    }
  }

  bool _validateConnection() {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (host.isEmpty || port == null || port <= 0 || port > 65535) {
      setState(() => _error = 'Informe um IP e uma porta válidos.');
      return false;
    }
    return true;
  }

  Future<void> _prepareFromBytes(Uint8List raw) async {
    setState(() {
      _busy = true;
      _error = null;
      _labels = [];
    });
    try {
      if (!_validateConnection()) return;
      await _persistSettings();
      final jpeg = prepareJpeg(raw);
      setState(() => _preview = jpeg);

      final result = await _client.sendImage(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        jpeg: jpeg,
      );
      if (!mounted) return;
      setState(() {
        _labels = result.labels.isNotEmpty
            ? result.labels
            : [result.message];
      });
    } catch (e) {
      setState(() {
        _error =
            'Não foi possível analisar. Verifique IP/porta e se o servidor está ligado.\n$e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onAnalyzePressed() async {
    if (_camera == null || !_cameraReady || _busy) return;
    final file = await _camera!.takePicture();
    await _prepareFromBytes(await file.readAsBytes());
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await _prepareFromBytes(await file.readAsBytes());
  }

  @override
  void dispose() {
    _camera?.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detector de objetos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(
                    labelText: 'IP do servidor',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Porta',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: _cameraReady && _camera != null
                  ? CameraPreview(_camera!)
                  : Container(
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: Text(
                        _error ?? 'Preparando câmera…',
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy || !_cameraReady ? null : _onAnalyzePressed,
            icon: const Icon(Icons.photo_camera),
            label: Text(_busy ? 'Analisando…' : 'Tirar e Analisar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Escolher da galeria'),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 16),
            const Text('Imagem enviada'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_preview!, height: 180, fit: BoxFit.cover),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
          ],
          if (_labels.isNotEmpty) ...[
            const SizedBox(height: 16),
            ResultCard(labels: _labels),
          ],
        ],
      ),
    );
  }
}
