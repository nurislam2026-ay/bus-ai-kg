

import 'services/voice_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const BusAiApp());
}

class BusAiApp extends StatelessWidget {
  const BusAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BUS AI KG',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
      ),
      home: const TerminalPage(),
    );
  }
}

class BusRoute {
  final String destination;
  final String busNumber;
  final String description;

  const BusRoute({
    required this.destination,
    required this.busNumber,
    required this.description,
  });
}

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final VoiceService _voice = VoiceService();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _controller = TextEditingController();

  bool _speechAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _status = 'Микрофонду басып, сүйлөңүз.';
  BusRoute? _route;


  final List<BusRoute> _routes = const [
    BusRoute(
      destination: 'Аламүдүн',
      busNumber: '42',
      description: 'Аламүдүн багыты боюнча демо маалымат.',
    ),
    BusRoute(
      destination: 'Алтын-Ордо',
      busNumber: '7',
      description: 'Алтын-Ордо багыты боюнча демо маалымат.',
    ),
    BusRoute(
      destination: 'Борбор',
      busNumber: '5',
      description: 'Борбор багыты боюнча демо маалымат.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    final available = await _voice.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() {
          _isListening = status == 'listening';
        });
      },
      onError: () {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _status = 'Үн таанууда ката чыкты. Микрофонду текшериңиз.';
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _speechAvailable = available;
      _status = available
          ? 'Микрофон даяр. Сүйлөп баштаңыз.'
          : 'Үн таануу жеткиликсиз. Багытты жазып издесеңиз болот.';
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      setState(() {
        _status = 'Микрофон иштебейт. Chrome уруксаттарын текшериңиз.';
      });
      return;
    }

    setState(() {
      _recognizedText = '';
      _status = 'Угуп жатам... Сүйлөй бериңиз.';
    });

    try {
      await _voice.startListening(
        onResult: (words, isFinal) {
          if (!mounted) return;

          setState(() {
            _recognizedText = words;
            _controller.text = words;
          });

          if (isFinal && words.trim().isNotEmpty) {
            _findRoute(words);
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'Сүйлөөнү таанууда ката чыкты.';
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    await _voice.stopListening();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  Future<void> _speak(String message) async {
    try {
      await _tts.stop();
      await _tts.setLanguage('ru-RU');
      await _tts.setSpeechRate(0.48);
      await _tts.speak(message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Үн менен жооп берүү бул браузерде жеткиликсиз.',
          ),
        ),
      );
    }
  }

  void _findRoute([String? spokenText]) {
    final input = (spokenText ?? _controller.text)
        .trim()
        .toLowerCase()
        .replaceAll('ё', 'е');

    if (input.isEmpty) {
      setState(() {
        _status = 'Кайда барарыңызды айтып бериңиз.';
        _route = null;
      });
      return;
    }

    BusRoute? found;

    for (final route in _routes) {
      final destination = route.destination.toLowerCase();

      if (input.contains(destination) ||
          (destination == 'алты́н-ордо' &&
              input.contains('алтын')) ||
          (destination == 'алтын-ордо' &&
              input.contains('алтын')) ||
          (destination == 'аламүдүн' &&
              (input.contains('аламуд') ||
                  input.contains('аламу') ||
                  input.contains('аламү'))) ||
          (destination == 'борбор' &&
              (input.contains('борбор') ||
                  input.contains('центр')))) {
        found = route;
        break;
      }
    }

    if (found == null) {
      setState(() {
        _route = null;
        _status =
        'Багытты түшүнө алган жокмун. Аламүдүн, Алтын-Ордо же Борбор деп айтып көрүңүз.';
      });
      _speak(
        'Кечиресиз, багытты түшүнө алган жокмун. '
            'Кайра айтып көрүңүз.',
      );
      return;
    }

    setState(() {
      _route = found;
      _status = '${found!.destination} багыты табылды.';
    });

    _speak(
      '${found.destination}. '
          'Демо маалымат боюнча автобус номери ${found.busNumber}.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _voice.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F3),
      appBar: AppBar(
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        title: const Text(
          'BUS AI KG',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.green.shade800,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: Colors.white,
                  size: 54,
                ),
                SizedBox(height: 12),
                Text(
                  'Сүйлө — автобусуңду тап!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Жазуунун кереги жок. Багытыңды үн менен айт.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _isListening
                  ? _stopListening
                  : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.red.shade600
                      : Colors.green.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 55,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isListening ? 'ТОКТОТ' : 'СҮЙЛӨ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Та айттыңыз: $_recognizedText',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            onSubmitted: (_) => _findRoute(),
            decoration: InputDecoration(
              hintText: 'Же бул жерге багытты жазыңыз',
              prefixIcon: const Icon(Icons.location_on),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _findRoute(),
            icon: const Icon(Icons.search),
            label: const Text('БАГЫТТЫ ИЗДӨӨ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          if (_route != null) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Colors.green,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _route!.destination,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Демо автобус №${_route!.busNumber}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  QrImageView(
                    data:
                    'BUS-AI-KG|${_route!.busNumber}|${_route!.destination}',
                    size: 190,
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                  ),
                  const Text(
                    'Демо QR-код',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _speak(
                        '${_route!.destination}. '
                            'Демо автобус номери ${_route!.busNumber}.',
                      );
                    },
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Жоопту угуу'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Мисалдар: «Аламүдүнгө барам», '
                '«Алтын-Ордого кантип барам?», «Борборго барам».',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          const Text(
            'Эскертүү: автобус номерлери демо маалымат. '
                'Чыныгы каттамдар менен байланыш азырынча кошулган эмес.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}