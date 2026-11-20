import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ImkonAIApp());
}

class ImkonAIApp extends StatelessWidget {
  const ImkonAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImkonAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF365CF5),
        ),
      ),
      home: const AssistantPage(),
    );
  }
}

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _ready = false;
  bool _listening = false;

  String? _localeId;

  String _recognized = 'Siz aytgan gap shu yerda ko‘rinadi.';
  String _reply = 'Assalomu alaykum! Men ImkonAI yordamchisiman.';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          setState(() {
            _listening = status == 'listening';
          });
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _listening = false;
            _reply = 'Ovoz xatosi: ${error.errorMsg}';
          });
        },
      );

      String? uzLocale;

      if (available) {
        final locales = await _speech.locales();

        for (final locale in locales) {
          final id = locale.localeId.toLowerCase().replaceAll('-', '_');

          if (id.startsWith('uz')) {
            uzLocale = locale.localeId;
            break;
          }
        }
      }

      try {
        await _tts.setLanguage('uz-UZ');
        await _tts.setSpeechRate(0.48);
        await _tts.setPitch(1.0);
      } catch (_) {
        // O‘zbekcha ovoz telefonda mavjud bo‘lmasligi mumkin.
      }

      if (!mounted) return;

      setState(() {
        _ready = available;
        _localeId = uzLocale;

        if (!available) {
          _reply = 'Ovoz xizmati ishga tushmadi. Mikrofon ruxsatini tekshiring.';
        } else if (uzLocale == null) {
          _reply = 'O‘zbekcha nutq xizmati topilmadi. Telefoningizda o‘zbek tilini sozlang.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _reply = 'Ovoz xizmatini ishga tushirishda xatolik yuz berdi.';
      });
    }
  }

  Future<void> _speak(String message) async {
    if (!mounted) return;

    setState(() {
      _reply = message;
    });

    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {
      // Ovoz ishlamasa ham javob ekranda ko‘rinadi.
    }
  }

  Future<void> _listen() async {
    if (!_ready) {
      await _speak('Ovoz xizmati tayyor emas. Mikrofon ruxsatini tekshiring.');
      return;
    }

    if (_localeId == null) {
      await _speak('Telefoningizda o‘zbekcha nutqni tanish xizmati topilmadi.');
      return;
    }

    try {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _recognized = 'Tinglayapman...';
        _reply = 'Marhamat, gapiring.';
      });

      await _speech.listen(
        localeId: _localeId!,
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 4),
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            _recognized = result.recognizedWords;
          });

          if (result.finalResult) {
            _handleCommand(result.recognizedWords);
          }
        },
      );
    } catch (_) {
      await _speak('Mikrofonni ishga tushirib bo‘lmadi.');
    }
  }

  Future<void> _handleCommand(String raw) async {
    final command = raw.toLowerCase().trim();

    if (command.isEmpty) return;

    if (command.contains('salom')) {
      await _speak('Va alaykum assalom! Sizga qanday yordam beray?');
    } else if (command.contains('yordam')) {
      await _speak(
        'Siz salom, yordam, vaqt, sana yoki to‘xta deb aytishingiz mumkin.',
      );
    } else if (command.contains('vaqt') || command.contains('soat')) {
      final now = DateTime.now();
      final answer =
          'Hozir soat ${now.hour}:${now.minute.toString().padLeft(2, '0')}.';
      await _speak(answer);
    } else if (command.contains('sana') || command.contains('bugun')) {
      final now = DateTime.now();
      await _speak(
        'Bugungi sana: ${now.day}.${now.month}.${now.year}.',
      );
    } else if (command.contains('to‘xta') ||
        command.contains("to'xta") ||
        command.contains('toxta')) {
      await _stop();
    } else {
      await _speak(
        'Buyruqni tushunmadim. Yordam deb ayting.',
      );
    }
  }

  Future<void> _stop() async {
    await _speech.stop();
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _listening = false;
      _reply = 'Ovozli yordamchi to‘xtatildi.';
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ImkonAI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 15),
            const Icon(
              Icons.accessibility_new_rounded,
              size: 76,
              color: Color(0xFF365CF5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sizning aqlli yordamchingiz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _listening
                  ? 'Sizni tinglayapman...'
                  : 'O‘zbek tilida gapiring',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _listening ? Colors.green : Colors.black54,
              ),
            ),
            const SizedBox(height: 25),
            _infoCard(
              title: 'Siz aytgan gap',
              message: _recognized,
              icon: Icons.mic,
            ),
            const SizedBox(height: 12),
            _infoCard(
              title: 'ImkonAI javobi',
              message: _reply,
              icon: Icons.smart_toy_outlined,
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 70,
              child: FilledButton.icon(
                onPressed: _listening ? _stop : _listen,
                icon: Icon(
                  _listening
                      ? Icons.stop_circle_outlined
                      : Icons.mic,
                  size: 30,
                ),
                label: Text(
                  _listening ? 'TO‘XTATISH' : 'GAPIRISH',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () {
                  _speak(
                    'Assalomu alaykum! ImkonAI sizga yordam berishga tayyor.',
                  );
                },
                icon: const Icon(Icons.volume_up),
                label: const Text('Ovozli javobni sinash'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sinov buyruqlari:\n'
              'Salom • Yordam • Soat nechchi? • Bugungi sana',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'ImkonAI — imkoniyatlar sari birgalikda!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF365CF5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF365CF5)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
