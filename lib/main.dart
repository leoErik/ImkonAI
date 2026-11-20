
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ImkonAiApp());
}

class ImkonAiApp extends StatelessWidget {
  const ImkonAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ImkonAI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D20),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7557FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<Map<String, String>> messages = [];

  bool isListening = false;
  bool speechAvailable = false;
  bool isSpeaking = false;

  String selectedLanguage = 'O‘zbekcha';
  String selectedVoice = 'Ayol';

  String get languageCode {
    switch (selectedLanguage) {
      case 'Русский':
        return 'ru-RU';
      case 'English':
        return 'en-US';
      default:
        return 'uz-UZ';
    }
  }

  @override
  void initState() {
    super.initState();
    initializeSpeech();
    initializeTts();
  }

  Future<void> initializeSpeech() async {
    try {
      speechAvailable = await speech.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              isListening = status == 'listening';
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              isListening = false;
            });
          }
        },
      );

      if (mounted) setState(() {});
    } catch (e) {
      speechAvailable = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> initializeTts() async {
    await tts.setLanguage(languageCode);
    await tts.setSpeechRate(0.48);
    await tts.setPitch(1.0);

    tts.setStartHandler(() {
      if (mounted) setState(() => isSpeaking = true);
    });

    tts.setCompletionHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });

    tts.setErrorHandler((message) {
      if (mounted) setState(() => isSpeaking = false);
    });
  }

  Future<void> speak(String text) async {
    await tts.stop();
    await tts.setLanguage(languageCode);
    await tts.speak(text);
  }

  Future<void> startListening() async {
    if (!speechAvailable) {
      await initializeSpeech();
    }

    if (!speechAvailable) {
      showMessage('Mikrofon ishlamayapti. Ruxsatlarni tekshiring.');
      return;
    }

    await tts.stop();

    await speech.listen(
      localeId: languageCode,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      onResult: (result) {
        if (mounted) {
          setState(() {
            controller.text = result.recognizedWords;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          });

          if (result.finalResult) {
            sendMessage();
          }
        }
      },
    );

    if (mounted) setState(() => isListening = true);
  }

  Future<void> stopListening() async {
    await speech.stop();
    if (mounted) setState(() => isListening = false);
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String getDateTimeAnswer() {
    final now = DateTime.now();

    final date =
        '${now.day}.${now.month}.${now.year}';

    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    switch (selectedLanguage) {
      case 'Русский':
        return 'Сегодня $date. Сейчас $time.';
      case 'English':
        return 'Today is $date. The time is $time.';
      default:
        return 'Bugun $date. Hozir soat $time.';
    }
  }

  String getOfflineAnswer(String question) {
    final q = question.toLowerCase();

    if (q.contains('vaqt') ||
        q.contains('soat') ||
        q.contains('time') ||
        q.contains('время')) {
      return getDateTimeAnswer();
    }

    if (q.contains('sana') ||
        q.contains('bugun') ||
        q.contains('date') ||
        q.contains('сегодня')) {
      return getDateTimeAnswer();
    }

    switch (selectedLanguage) {
      case 'Русский':
        return 'Я ImkonAI. Для полноценных ответов искусственного '
            'интеллекта необходимо подключение к интернету.';
      case 'English':
        return 'I am ImkonAI. An internet connection is needed '
            'for full AI answers.';
      default:
        return 'Men ImkonAI yordamchisiman. Hozircha oddiy '
            'buyruqlarni bajara olaman. To‘liq sun’iy intellekt '
            'javoblari uchun internet ulanishini sozlash kerak.';
    }
  }

  void sendMessage() {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({
        'role': 'user',
        'text': text,
      });
    });

    controller.clear();

    final answer = getOfflineAnswer(text);

    setState(() {
      messages.add({
        'role': 'ai',
        'text': answer,
      });
    });

    speak(answer);
    scrollToBottom();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> changeLanguage(String? value) async {
    if (value == null) return;

    setState(() {
      selectedLanguage = value;
    });

    await tts.setLanguage(languageCode);
    showMessage('Til o‘zgartirildi: $value');
  }

  Future<void> changeVoice(String? value) async {
    if (value == null) return;

    setState(() {
      selectedVoice = value;
    });

    showMessage(
      'Tanlangan ovoz: $value. Mavjud ovozlar telefoningizdagi '
      'TTS xizmatiga bog‘liq.',
    );
  }

  @override
  void dispose() {
    speech.stop();
    tts.stop();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF101B42),
              Color(0xFF090D20),
              Color(0xFF251044),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              buildHeader(),
              buildAssistant(),
              Expanded(child: buildMessages()),
              buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF536DFF),
                  Color(0xFFB44BFF),
                ],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ImkonAI',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Aqlli ovozli yordamchi',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF171D3A),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sozlamalar',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedLanguage,
                          decoration: const InputDecoration(
                            labelText: 'Tilni tanlang',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'O‘zbekcha',
                              child: Text('O‘zbekcha'),
                            ),
                            DropdownMenuItem(
                              value: 'Русский',
                              child: Text('Русский'),
                            ),
                            DropdownMenuItem(
                              value: 'English',
                              child: Text('English'),
                            ),
                          ],
                          onChanged: (value) {
                            changeLanguage(value);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedVoice,
                          decoration: const InputDecoration(
                            labelText: 'Ovoz tanlash',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Ayol',
                              child: Text('Ayol ovozi'),
                            ),
                            DropdownMenuItem(
                              value: 'Erkak',
                              child: Text('Erkak ovozi'),
                            ),
                          ],
                          onChanged: (value) {
                            changeVoice(value);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            },
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAssistant() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4169FF),
                  Color(0xFFB54BFF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7557FF).withOpacity(0.4),
                  blurRadius: 35,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              isListening
                  ? Icons.graphic_eq
                  : Icons.auto_awesome,
              size: 65,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            isListening
                ? 'Sizni tinglayapman...'
                : isSpeaking
                    ? 'Javob bermoqdaman...'
                    : 'Assalomu alaykum!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sizga qanday yordam beray?',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget buildMessages() {
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'Men bilan suhbatni boshlang.\n'
            'Matn yozing yoki mikrofon tugmasini bosing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message['role'] == 'user';

        return Align(
          alignment: isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            margin: const EdgeInsets.symmetric(vertical: 7),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF5549C9)
                  : const Color(0xFF202A4D),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message['text'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111832),
        border: Border(
          top: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
              decoration: InputDecoration(
                hintText: 'Xabar yozing...',
                filled: true,
                fillColor: const Color(0xFF202A4D),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(
              Icons.send_rounded,
              color: Color(0xFF9C83FF),
              size: 28,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF536DFF),
                  Color(0xFFB44BFF),
                ],
              ),
            ),
            child: IconButton(
              onPressed: isListening
                  ? stopListening
                  : startListening,
              icon: Icon(
                isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
