import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() => runApp(const ImkonAiApp());

class ImkonAiApp extends StatelessWidget {
  const ImkonAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImkonAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF365CF5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
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
  String _recognized = 'Bu yerda sizning ovozli buyruqlaringiz ko‘rinadi.';
  String _reply = 'Assalomu alaykum! Men ImkonAI yordamchisiman.';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _listening = status == 'listening');
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _reply = 'Ovozni aniqlashda xatolik: ${error.errorMsg}';
        });
      },
    );

    String? uzLocale;
    if (available) {
      final locales = await _speech.locales();
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().replaceAll('-', '_').startsWith('uz')) {
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
      // Uzbek TTS may not be installed on every Android device.
    }

    if (!mounted) return;
    setState(() {
      _ready = available;
      _localeId = uzLocale;
      if (!available) {
        _reply = 'Ovoz xizmatini ishga tushirib bo‘lmadi. Telefon sozlamalarida mikrofon ruxsatini tekshiring.';
      } else if (uzLocale == null) {
        _reply = 'Telefoningizda o‘zbekcha nutqni tanish xizmati topilmadi. Ovoz sozlamalaridan Uzbek tilini o‘rnating yoki tanlang.';
      }
    });
  }

  Future<void> _speak(String text) async {
    setState(() => _reply = text);
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Keep the text response visible if TTS is unavailable.
    }
  }

  Future<void> _listen() async {
    if (!_ready) {
      await _speak('Ovoz xizmati tayyor emas. Mikrofon ruxsatini tekshiring.');
      return;
    }
    if (_localeId == null) {
      await _speak('O‘zbekcha nutqni tanish telefoningizda mavjud emas. Telefoningizga Uzbek speech xizmatini o‘rnating.');
      return;
    }
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
        setState(() => _recognized = result.recognizedWords);
        if (result.finalResult) _handleCommand(result.recognizedWords);
      },
    );
  }

  Future<void> _handleCommand(String raw) async {
    final command = raw.toLowerCase().trim();
    if (command.isEmpty) return;

    if (command.contains('salom')) {
      await _speak('Va alaykum assalom! Sizga qanday yordam beray?');
    } else if (command.contains('yordam')) {
      await _speak('Siz salom, yordam, vaqt, sana yoki to‘xta deb buyruq berishingiz mumkin. Keyingi versiyada kamera va hujjat o‘qish ham qo‘shiladi.');
    } else if (command.contains('vaqt')) {
      final now = DateTime.now();
      final answer = 'Hozir soat ${now.hour}:${now.minute.toString().padLeft(2, '0')}.';
      await _speak(answer);
    } else if (command.contains('sana') || command.contains('bugun')) {
      final now = DateTime.now();
      await _speak('Bugungi sana: ${now.day}.${now.month}.${now.year}.');
    } else if (command.contains('to‘xta') || command.contains("to'xta") || command.contains('toxta')) {
      await _speech.stop();
      await _tts.stop();
      setState(() => _reply = 'Ovozli javob to‘xtatildi.');
    } else {
      await _speak('Buyruqni tushunmadim. Iltimos, yordam deb ayting.');
    }
  }

  Future<void> _stop() async {
    await _speech.stop();
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _reply = 'To‘xtatildi.';
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
        title: const Text('ImkonAI'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              const Icon(Icons.accessibility_new_rounded, size: 64, color: Color(0xFF365CF5)),
              const SizedBox(height: 12),
              Text(
                'Sizning aqlli yordamchingiz',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _listening ? 'Sizni tinglayapman...' : 'O‘zbek tilida gapiring',
                textAlign: TextAlign.center,
                style: TextStyle(color: _listening ? Colors.green : Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Siz aytgan gap', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_recognized, style: const TextStyle(fontSize: 17)),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ImkonAI javobi', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_reply, style: const TextStyle(fontSize: 17)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Semantics(
                label: _listening ? 'Tinglashni to‘xtatish' : 'Ovozli buyruq berish',
                button: true,
                child: SizedBox(
                  height: 76,
                  child: FilledButton.icon(
                    onPressed: _listening ? _stop : _listen,
                    icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic, size: 30),
                    label: Text(_listening ? 'TO‘XTATISH' : 'GAPIRISH', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _speak('Assalomu alaykum! ImkonAI sizga yordam berishga tayyor.'),
                icon: const Icon(Icons.volume_up),
                label: const Text('Ovozli javobni sinash'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sinov buyruqlari: “Salom”, “Yordam”, “Soat nechchi?”, “Bugungi sana”.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
