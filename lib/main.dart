import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => QuizProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        return MaterialApp(
          title: 'IT Yo‘lim',
          debugShowCheckedModeBanner: false,
          themeMode: quizProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            fontFamily: 'Roboto',
          ),
          home: const WelcomeScreen(),
        );
      },
    );
  }
}

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/img.png"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: child,
    );
  }
}

class QuizProvider extends ChangeNotifier {
  int _currentQuestionIndex = 0;

  int get currentQuestionIndex => _currentQuestionIndex;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  final Map<String, int> scores = {
    "Grafik Dizayn": 0,
    "Frontend": 0,
    "Flutter": 0,
    "Backend": 0,
    "Kiberxavfsizlik": 0,
  };

  static const int totalQuestions = 20;

  final List<String> categories = [
    "Grafik Dizayn",
    "Frontend",
    "Flutter",
    "Backend",
    "Kiberxavfsizlik",
  ];

  List<Question> _shuffledQuestions = [];

  List<Question> get questions => _shuffledQuestions;

  int? _selectedOption;

  void initializeQuiz() {
    _shuffledQuestions = List.from(originalQuestions)..shuffle();

    for (var q in _shuffledQuestions) {
      final pairs = List.generate(
        5,
        (i) => {'text': q.options[i], 'pointIndex': i},
      );
      pairs.shuffle();

      q._shuffledOptions = pairs.map((p) => p['text'] as String).toList();
      q._shuffledPointIndices = pairs
          .map((p) => p['pointIndex'] as int)
          .toList();
    }

    _currentQuestionIndex = 0;
    _selectedOption = null;
    scores.updateAll((key, value) => 0);
    notifyListeners();
  }

  void selectOption(int displayIndex, BuildContext context) {
    if (_selectedOption != null) return;
    _selectedOption = displayIndex;

    final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
    final originalIndex = currentQuestion._shuffledPointIndices[displayIndex];
    final category = categories[originalIndex];

    scores[category] = scores[category]! + 1;

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (_currentQuestionIndex < totalQuestions - 1) {
        _currentQuestionIndex++;
        _selectedOption = null;
        notifyListeners();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResultScreen()),
        );
      }
    });
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      _selectedOption = null;
      notifyListeners();
    }
  }

  String getTopDirection() {
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Map<String, double> get dataMap =>
      scores.map((key, value) => MapEntry(key, value.toDouble()));

  void reset() {
    _currentQuestionIndex = 0;
    _selectedOption = null;
    scores.updateAll((_, __) => 0);
    _shuffledQuestions = [];
    notifyListeners();
  }
}

class Question {
  final String text;
  final List<String> options;
  final List<int> points;

  List<String> _shuffledOptions = [];

  List<String> get displayOptions => _shuffledOptions;

  List<int> _shuffledPointIndices = [];

  List<int> get pointIndices => _shuffledPointIndices;

  Question(this.text, this.options, {required this.points})
    : assert(options.length == points.length && points.length == 5) {
    _shuffledOptions = List.from(options);
    _shuffledPointIndices = List.generate(points.length, (i) => i);
  }
}

List<Question> originalQuestions = [
  Question(
    "Bo‘sh vaqtingizda ko‘proq nimani qilib ketib qolganingizni sezmay qolasiz?",
    [
      "Biror narsani chiroyliroq qilib ko‘rish bilan",
      "Atrofimdagi narsalarni tartibga solish bilan",
      "Turli xil ishlarni navbatma-navbat qilib",
      "Bosh qotiradigan masalalar bilan",
      "Hamma narsa joyida ekanini tekshirib",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Yangi joyga kirganingizda nimasi tezroq ko‘zingizga tashlanadi?",
    [
      "Qanday bezatilgani",
      "Qanchalik qulay ekanligi",
      "Qanday harakat bo‘layotgani",
      "Ichki tartibi",
      "Xavfsiz yoki yo‘qligi",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Biror buyum sizga yoqishi uchun nimasi muhimroq?",
    [
      "Ko‘rinishi",
      "Qulayligi",
      "Har xil holatga mosligi",
      "Uzoq xizmat qilishi",
      "Ishonch berishi",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Do‘stlaringiz muammo bo‘lsa sizga qachon murojaat qilishadi?",
    [
      "Biror narsani chiroyli qilib berish kerak bo‘lsa",
      "Qanday qulay ishlatishni tushunmay qolishsa",
      "Biror ishni tezda qilib berish kerak bo‘lsa",
      "Boshlari qotib qolsa",
      "Ishonchli maslahat kerak bo‘lsa",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Biror ishni qilayotganda qaysi holat sizga ko‘proq yoqadi?",
    [
      "Natija ko‘zni quvontirsa",
      "Odamlar qiynalmasdan foydalansa",
      "Jarayon zeriktirmasa",
      "Hamma narsa o‘z o‘rnida bo‘lsa",
      "Xavotir bo‘lmasa",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Biror narsa ishlamay qolsa, odatda nima qilasiz?",
    [
      "Tashqi tomondan o‘zgartirib ko‘raman",
      "Qanday ishlatilishini qayta ko‘rib chiqaman",
      "Qayta-qayta sinab ko‘raman",
      "Nega bunday bo‘lganini o‘ylab ko‘raman",
      "Xavf yo‘qmi deb tekshiraman",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Quyidagilardan qaysi biri sizni tezroq bezovta qiladi?",
    [
      "Betartiblik",
      "Noqulaylik",
      "Sekinlik",
      "Tushunarsizlik",
      "Ishonchsizlik",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Qaysi muhitda o‘zingizni erkinroq his qilasiz?",
    [
      "Ilhom beradigan joyda",
      "Hammasi aniq bo‘lgan joyda",
      "Harakat ko‘p bo‘lgan joyda",
      "Sokin va jim joyda",
      "Nazoratli joyda",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Film yoki serial ko‘rayotganda nimasi sizni ko‘proq tortadi?",
    [
      "Tasvir va muhit",
      "Tushunarli voqealar",
      "Ritmi va tezligi",
      "Mantiqiy bog‘liqlik",
      "Sirli tomonlari",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Sizni qaysi holat ko‘proq xursand qiladi?",
    [
      "Ko‘zimga yoqadigan natija",
      "Odamlar rozi bo‘lishi",
      "Ishlar tez yurishi",
      "Muammo yechilishi",
      "Xotirjamlik bo‘lishi",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  // 11–20
  Question(
    "Biror ishni boshlashdan oldin ichingizda qaysi savol paydo bo‘ladi?",
    [
      "Chiroyli chiqadimi?",
      "Odamlar tushuna oladimi?",
      "Tez bitadimi?",
      "Ichida nima bo‘lyapti?",
      "Muammo chiqmaydimi?",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Qaysi vaziyatda o‘zingizni foydaliroq his qilasiz?",
    [
      "Biror narsani bezab bersam",
      "Biror ishni osonlashtirsam",
      "Ishlar tezlashsa",
      "Chalkashlikni yo‘qotsam",
      "Xavfni oldini olsam",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Quyidagi ishlarning qaysi biri sizga yaqinroq?",
    [
      "Tasavvur qilish",
      "Tushuntirib berish",
      "Harakat qilish",
      "Tahlil qilish",
      "Kuzatib turish",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Biror narsani baholayotganda nimaga qaraysiz?",
    [
      "Ko‘zimga yoqadimi",
      "Foydalanish osonmi",
      "Qanday ishlaydi",
      "Ichidan puxtami",
      "Ishonchlimi",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Qachon o‘zingizdan mamnun bo‘lasiz?",
    [
      "Natija chiroyli bo‘lsa",
      "Odamlar qiynalmasa",
      "Ish tez bitsa",
      "Muammo qolmasa",
      "Xavotir bo‘lmasa",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Yangi narsaga munosabatingiz qanday?",
    [
      "Ko‘zimga yoqsa sinab ko‘raman",
      "Qulay bo‘lsa yetarli",
      "Oson bo‘lsa yoqadi",
      "Mantiqli bo‘lsa qiziq",
      "Xavfsiz bo‘lsa ishonaman",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Siz uchun yaxshi bajarilgan ish nimasi bilan bilinadi?",
    [
      "Ko‘rinishi bilan",
      "Oson ishlatilishi bilan",
      "Muammosiz ishlashi bilan",
      "Ichidan puxta bo‘lishi bilan",
      "Xotirjamlik berishi bilan",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Qaysi holatda ko‘proq asabiylashasiz?",
    [
      "Didga to‘g‘ri kelmasa",
      "Noqulay bo‘lsa",
      "Sekin bo‘lsa",
      "Tushunarsiz bo‘lsa",
      "Xavf sezilsa",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Agar biror ish sizga topshirilsa, nimaga ko‘proq e’tibor berasiz?",
    [
      "Qanday ko‘rinishiga",
      "Odamlar qanday ishlatishiga",
      "Qanchalik tez bajarilishiga",
      "Ichki tartibiga",
      "Xavfsizligiga",
    ],
    points: [1, 1, 1, 1, 1],
  ),

  Question(
    "Sizni eng ko‘p qoniqtiradigan holat qaysi?",
    [
      "Natija ko‘zni quvontirsa",
      "Hamma tushunsa",
      "Ishlar tez yursa",
      "Hamma narsa joyida bo‘lsa",
      "Xotirjam bo‘lsam",
    ],
    points: [1, 1, 1, 1, 1],
  ),
];

final Map<String, Map<String, String>> directionInfo = {
  "Grafik Dizayn": {
    "desc":
        "Logolar, bannerlar, UI/UX dizaynlar yaratish. Eng ijodiy IT yo‘nalishi!",
    "tools": "Figma, Adobe XD, Photoshop, Illustrator",
    "salary": "O‘rtacha: 200-700\$ (junior-mid)",
    "demand": "Juda yuqori",
    "difficulty": "O‘rganish oson, ijod talab qiladi",
  },
  "Frontend": {
    "desc":
        "Veb-saytlarning ko‘rinadigan qismini yaratish. Foydalanuvchi bilan bevosita aloqa!",
    "tools": "HTML, CSS, JavaScript, React, Vue",
    "salary": "O‘rtacha: 300-900\$",
    "demand": "Doimiy talab",
    "difficulty": "O‘rtacha qiyinlik",
  },
  "Flutter": {
    "desc":
        "Bitta kod bilan Android va iOS ilovalari yasash. Mobil dunyoning kelajagi!",
    "tools": "Dart, Flutter SDK",
    "salary": "O‘rtacha: 300-1000\$",
    "demand": "Tez o‘sib borayotgan",
    "difficulty": "O‘rtacha, Dartni o‘rganish kerak",
  },
  "Backend": {
    "desc":
        "Server, ma'lumotlar bazasi va logikani boshqarish. Saytning 'miyasi'!",
    "tools": "Python, Node.js, Java, PHP, SQL",
    "salary": "O‘rtacha: 300-1500\$",
    "demand": "Juda yuqori",
    "difficulty": "Qiyinroq, mantiq talab qiladi",
  },
  "Kiberxavfsizlik": {
    "desc":
        "Tizimlarni xakerlardan himoya qilish. Kelajakning eng muhim va yuqori maoshli sohasi!",
    "tools": "Kali Linux, Wireshark, Ethical Hacking",
    "salary": "O‘rtacha: 300-1200\$",
    "demand": "Eng talabgir soha",
    "difficulty": "Juda qiyin, doimiy o‘rganish kerak",
  },
};

final Map<String, List<String>> directionFacts = {
  "Grafik Dizayn": [
    "Dizaynerlar kuniga o‘rtacha 8-10 soat ranglar bilan ishlaydi.",
    "Figma dunyodagi eng mashhur dizayn vositasi.",
    "Yaxshi logo yaratish uchun 20-50 ta variant sinab ko‘riladi.",
    "Rang psixologiyasi dizaynda eng muhim narsa.",
    "Adobe Photoshop 1990-yilda chiqqan va hali ham standart.",
    "UI/UX dizaynerlar foydalanuvchi tajribasini 80% yaxshilashi mumkin.",
    "Grafik dizayn ko‘p mamlakatlarda eng talabgir kasblardan.",
    "Minimalizm so‘nggi 5 yilda eng katta trend.",
    "Yaxshi dizayn savdoni 200-400% oshirishi mumkin.",
    "Ko‘p muvaffaqiyatli dizaynerlar san’at maktabida o‘qimagan!",
  ],
  "Frontend": [
    "React dunyodagi eng mashhur frontend kutubxonasi.",
    "CSS Grid va Flexbox zamonaviy veb-dizaynni o‘zgartirdi.",
    "Frontendchi kuniga 100-300 qator kod yozishi mumkin.",
    "JavaScript eng ko‘p ishlatiladigan dasturlash tili.",
    "Responsive dizayn bugungi kunda majburiy.",
    "Vue.js va Svelte tezlikda Reactdan o‘zib ketmoqda.",
    "Animatsiyalar foydalanuvchi tajribasini 40% yaxshilaydi.",
    "TypeScript so‘nggi 3 yilda 300% o‘sdi.",
    "Yaxshi frontendchi foydalanuvchini birinchi o‘ringa qo‘yadi.",
    "Ko‘p kompaniyalar 'Jamstack' ga o‘tmoqda.",
  ],
  "Flutter": [
    "Flutter bitta kod bilan Android, iOS, Web va Desktop ilova yaratadi.",
    "Google tomonidan ishlab chiqilgan va tez o‘smoqda.",
    "Flutter ilovalari native ilovalardan 2 barobar tez.",
    "Dart tili o‘rganish uchun juda oson.",
    "Alibaba, BMW, Google Pay Flutterdan foydalanadi.",
    "Hot Reload kodni 1 soniyada yangilaydi.",
    "2023-yilda eng tez o‘suvchi framework bo‘ldi.",
    "100 000+ tayyor widgetlar mavjud.",
    "Flutter ilovalar hajmi kichik va batareya tejaydi.",
    "Kelajakda ko‘proq kompaniyalar Flutterga o‘tadi.",
  ],
  "Backend": [
    "Backend – sayt yoki ilovaning 'miyasi'.",
    "Node.js bilan JavaScriptda backend yozish mumkin.",
    "Ma'lumotlar bazasi backendning yuragi.",
    "REST API va GraphQL eng mashhur.",
    "Python (Django/FastAPI) eng tez rivojlanayotgan.",
    "Cloud xizmatlari backendni osonlashtirdi.",
    "Yaxshi backendchi millionlab foydalanuvchini boshqara oladi.",
    "Security backendning eng muhim qismi.",
    "Microservices zamonaviy trend.",
    "Backendchilar ko‘pincha eng yuqori maosh oladi.",
  ],
  "Kiberxavfsizlik": [
    "Har yili kiberhujumlar 30-50% oshmoqda.",
    "Ethical Hacker – eng qiziqarli va yuqori maoshli kasb.",
    "Ransomware hozirgi eng katta xavf.",
    "Ko‘p hujumlar oddiy parollar sababli sodir bo‘ladi.",
    "Kiberxavfsizlik mutaxassislari dunyoda juda kam.",
    "Bir muvaffaqiyatsiz hujum millionlab dollar zarar keltiradi.",
    "Zero Trust – yangi xavfsizlik modeli.",
    "Bug Bounty orqali millionlab dollar topish mumkin.",
    "AI kiberxavfsizlikda kelajakda asosiy rol o‘ynaydi.",
    "Har bir kompaniya endi kiberxavfsizlik mutaxassisiga muhtoj.",
  ],
};

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void showDirectionInfo(BuildContext context, String direction) {
    final info = directionInfo[direction]!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          direction,
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info["desc"]!,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _infoRow("Asboblar:", info["tools"]!),
              _infoRow("O‘rtacha maosh:", info["salary"]!),
              _infoRow("Talab:", info["demand"]!),
              _infoRow("Qiyinlik darajasi:", info["difficulty"]!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Yopish", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: " $value",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String dir) {
    switch (dir) {
      case "Grafik Dizayn":
        return Icons.design_services;
      case "Frontend":
        return Icons.web;
      case "Flutter":
        return Icons.phone_android;
      case "Backend":
        return Icons.storage;
      case "Kiberxavfsizlik":
        return Icons.security;
      default:
        return Icons.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Consumer<QuizProvider>(
                    builder: (context, quiz, _) => IconButton(
                      icon: Icon(
                        quiz.themeMode == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          quiz.toggleTheme(quiz.themeMode != ThemeMode.dark),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "IT Yo‘lim",
                  style: TextStyle(
                    fontSize: 60,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.black45,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "O‘zingizga eng mos IT yo‘nalishini toping!",
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Yo‘nalishlar haqida batafsil ma’lumot:",
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: directionInfo.keys.length,
                  itemBuilder: (context, index) {
                    final dir = directionInfo.keys.elementAt(index);
                    return GestureDetector(
                      onTap: () => showDirectionInfo(context, dir),
                      child: Card(
                        color: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getIcon(dir),
                                size: 50,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                dir,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Batafsil →",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<QuizProvider>(
                      context,
                      listen: false,
                    ).initializeQuiz();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const QuizScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 36),
                  label: const Text(
                    "Testni boshlash",
                    style: TextStyle(fontSize: 24),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 20,
                    ),
                    shape: const StadiumBorder(),
                    elevation: 15,
                  ),
                ),
                const SizedBox(height: 30),
                OutlinedButton.icon(
                  onPressed: () => Share.share(
                    "Siz qachon tushunib yetasiz IT kelajak kasb ekanligini saytga kiring va ozingizga mos IT yo‘nalishini toping! 🚀\n@codialuz",
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text("Do‘stlarga ulashish"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: Consumer<QuizProvider>(
          builder: (context, quiz, child) {
            final question = quiz.questions[quiz.currentQuestionIndex];
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Savol ${quiz.currentQuestionIndex + 1}/20",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.restart_alt,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            bool? confirm = await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: Colors.deepPurple.shade800,
                                title: const Text(
                                  "Qayta boshlash?",
                                  style: TextStyle(color: Colors.white),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Yo‘q"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Ha"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              quiz.reset();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WelcomeScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: (quiz.currentQuestionIndex + 1) / 20,
                    minHeight: 8,
                    color: Colors.amber,
                    backgroundColor: Colors.white24,
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            question.text,
                            style: const TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          Expanded(
                            child: ListView.builder(
                              itemCount: question.displayOptions.length,
                              itemBuilder: (context, i) {
                                final selected = quiz._selectedOption == i;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: AnimatedScale(
                                    scale: selected ? 1.04 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    child: GestureDetector(
                                      onTap: () =>
                                          quiz.selectOption(i, context),
                                      child: Card(
                                        elevation: selected ? 8 : 2,
                                        color: selected
                                            ? Colors.deepPurple.shade700
                                                  .withOpacity(0.75)
                                            : Colors.white.withOpacity(0.15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 20,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                selected
                                                    ? Icons.check_circle_rounded
                                                    : Icons.circle_outlined,
                                                color: selected
                                                    ? Colors
                                                          .greenAccent
                                                          .shade400
                                                    : Colors.white70,
                                                size: 28,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  question.displayOptions[i],
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (quiz.currentQuestionIndex > 0)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: quiz.previousQuestion,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Orqaga",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ResultScreen ni o'zgartirmagan holda qoldirdim (agar kerak bo'lsa keyinroq so'rashingiz mumkin)

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  IconData _getIcon(String dir) {
    switch (dir) {
      case "Grafik Dizayn":
        return Icons.design_services;
      case "Frontend":
        return Icons.web;
      case "Flutter":
        return Icons.phone_android;
      case "Backend":
        return Icons.storage;
      case "Kiberxavfsizlik":
        return Icons.security;
      default:
        return Icons.code;
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text: " $value",
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = Provider.of<QuizProvider>(context, listen: false);
    final topDirection = quiz.getTopDirection();
    // final facts = directionFacts[topDirection]!;  // agar facts ishlatmoqchi bo'lsangiz qayta qo'shing

    return Scaffold(
      body: BackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  "🎉 Natija tayyor!",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Sizga eng mos IT yo‘nalishi:",
                  style: TextStyle(fontSize: 24, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Text(
                  topDirection,
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                PieChart(
                  dataMap: quiz.dataMap,
                  chartRadius: MediaQuery.of(context).size.width / 1.7,
                  colorList: const [
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                    Colors.blue,
                    Colors.red,
                  ],
                  legendOptions: const LegendOptions(
                    legendPosition: LegendPosition.bottom,
                    legendTextStyle: TextStyle(color: Colors.white),
                  ),
                  chartValuesOptions: const ChartValuesOptions(
                    showChartValuesInPercentage: true,
                    chartValueStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getIcon(topDirection),
                              size: 40,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              topDirection,
                              style: const TextStyle(
                                fontSize: 32,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          directionInfo[topDirection]!["desc"]!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _infoRow(
                          "Asboblar:",
                          directionInfo[topDirection]!["tools"]!,
                        ),
                        _infoRow(
                          "O‘rtacha maosh:",
                          directionInfo[topDirection]!["salary"]!,
                        ),
                        _infoRow(
                          "Talab darajasi:",
                          directionInfo[topDirection]!["demand"]!,
                        ),
                        _infoRow(
                          "Qiyinlik darajasi:",
                          directionInfo[topDirection]!["difficulty"]!,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        quiz.reset();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomeScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text("Yana sinash"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Share.share(
                        "Mening IT yo‘nalishim: $topDirection! 🎯\nIT Yo‘lim testidan o‘tdim!",
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text("Ulashish"),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
