import 'package:canliceviri/MainPage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: 'Gerçek Zamanlı Çeviri',
        debugShowCheckedModeBanner: false,
        home: MainPage());
  }
}
