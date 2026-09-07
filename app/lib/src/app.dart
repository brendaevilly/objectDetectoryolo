import 'package:flutter/material.dart';

import 'ui/home_page.dart';

class ObjectDetectorApp extends StatelessWidget {
  const ObjectDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}
