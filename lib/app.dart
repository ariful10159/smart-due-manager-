import 'package:flutter/material.dart';

class SmartDueApp extends StatelessWidget {
  const SmartDueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Due',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('Smart Due'))),
    );
  }
}
