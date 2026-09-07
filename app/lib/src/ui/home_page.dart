// ignore_for_file: unused_import

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
  @override
  Widget build(BuildContext context) {
    // TODO: IP/porta, preview da câmera, botão "Tirar e Analisar", resultado
    return const Scaffold(
      body: Center(child: Text('Detector de objetos')),
    );
  }
}
