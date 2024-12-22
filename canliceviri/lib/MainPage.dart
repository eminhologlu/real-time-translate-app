import 'package:canliceviri/CameraPage.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  TranslateLanguage _sourceLanguage = TranslateLanguage.english;
  TranslateLanguage _targetLanguage = TranslateLanguage.turkish;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        title: const Text('Holo Gerçek Zamanlı Çeviri'),
        backgroundColor: Colors.amber[100],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Dilleri seçin ve kamera butonuna tıklayın:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: width * 0.04),
            const Text(
              'Kaynak Dil:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            DropdownButton<TranslateLanguage>(
              value: _sourceLanguage,
              alignment: Alignment.center,
              style: const TextStyle(color: Colors.teal),
              underline: Container(
                height: width * 0.08,
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    border:
                        Border.all(width: width * 0.001, color: Colors.teal),
                    borderRadius: BorderRadius.circular(width * 0.03)),
              ),
              onChanged: (TranslateLanguage? newValue) {
                setState(() {
                  _sourceLanguage = newValue!;
                });
              },
              items: TranslateLanguage.values
                  .map<DropdownMenuItem<TranslateLanguage>>(
                      (TranslateLanguage lang) {
                return DropdownMenuItem<TranslateLanguage>(
                  value: lang,
                  child: Text(lang.name),
                );
              }).toList(),
            ),
            SizedBox(height: width * 0.03),
            const Text(
              'Hedef Dil:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            DropdownButton<TranslateLanguage>(
              alignment: Alignment.center,
              value: _targetLanguage,
              style: const TextStyle(color: Colors.teal),
              underline: Container(
                height: width * 0.08,
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    border:
                        Border.all(width: width * 0.001, color: Colors.teal),
                    borderRadius: BorderRadius.circular(width * 0.03)),
              ),
              onChanged: (TranslateLanguage? newValue) {
                setState(() {
                  _targetLanguage = newValue!;
                });
              },
              items: TranslateLanguage.values
                  .map<DropdownMenuItem<TranslateLanguage>>(
                      (TranslateLanguage lang) {
                return DropdownMenuItem<TranslateLanguage>(
                  value: lang,
                  child: Text(lang.name),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Colors.teal,
        child: Icon(
          Icons.camera_alt_rounded,
          color: Colors.teal[50],
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CameraPage(
                sourceLanguage: _sourceLanguage,
                targetLanguage: _targetLanguage,
              ),
            ),
          );
        },
        // Kamera ikonu
      ),
    );
  }
}
