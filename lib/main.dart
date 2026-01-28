import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => QuizProvider(), child: const MyApp()),
  );
}

/// ----------------------------
/// Responsive helpers
/// ----------------------------
class R {
  static double w(BuildContext c) => MediaQuery.sizeOf(c).width;
  static double h(BuildContext c) => MediaQuery.sizeOf(c).height;

  static bool isPhone(BuildContext c) => w(c) < 600;
  static bool isTablet(BuildContext c) => w(c) >= 600 && w(c) < 1024;
  static bool isDesktop(BuildContext c) => w(c) >= 1024;

  /// Web/desktop’da kontent cho‘zilib ketmasin
  static double maxContentWidth(BuildContext c) {
    if (isDesktop(c)) return 860;
    if (isTablet(c)) return 720;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext c) {
    final width = w(c);
    if (width >= 1024) return const EdgeInsets.all(28);
    if (width >= 600) return const EdgeInsets.all(22);
    return const EdgeInsets.all(18);
  }

  static int gridCountForDirections(BuildContext c) {
    final width = w(c);
    if (width >= 1024) return 3;
    if (width >= 700) return 3;
    return 2;
  }

  static double titleSize(BuildContext c) {
    if (isDesktop(c)) return 56;
    if (isTablet(c)) return 52;
    return 44;
  }
}

Future<void> shareOrCopy(BuildContext context, String text) async {
  try {
    await Share.share(text);
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ulashish ishlamadi, matn nusxa olindi ✅")),
      );
    }
  }
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

/// ----------------------------
/// Background + centered content wrapper
/// ----------------------------
class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  // Telefon uchun rasm (URL)
  static const String mobileBg =
      "https://i.pinimg.com/originals/0a/5a/66/0a5a66c087f6d9b6419e0e8d8c9387d4.png?nii=t";

  // Kompyuter/Web uchun rasm (URL)
  static const String desktopBg =
      "https://static.vecteezy.com/system/resources/previews/055/176/498/non_2x/a-futuristic-blue-screen-with-a-digital-background-vector.jpg";

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bgUrl = (size.width < 700) ? mobileBg : desktopBg;

    // ✅ FIX: Stack + Positioned.fill — fon har doim ekran bo‘ylab “cover”
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            bgUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.black54),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Kontent web’da “chayilib ketmasin” uchun
class CenteredContent extends StatelessWidget {
  final Widget child;

  const CenteredContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final maxW = R.maxContentWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: child,
      ),
    );
  }
}

/// ----------------------------
/// Provider
/// ----------------------------
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
  int? get selectedOption => _selectedOption;

  void initializeQuiz() {
    _shuffledQuestions = List.from(originalQuestions)..shuffle();

    for (final q in _shuffledQuestions) {
      q.shuffleOptions();
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

    // ✅ Endi index emas, bevosita kategoriya (shuffle bo‘lsa ham buzilmaydi)
    final category = currentQuestion.displayOptions[displayIndex].category;

    scores[category] = (scores[category] ?? 0) + 1;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!context.mounted) return;

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

  // ixtiyoriy: durang bo‘lsa random tanlaydi
  String getTopDirection() {
    final maxVal = scores.values.reduce((a, b) => a > b ? a : b);
    final tops = scores.entries.where((e) => e.value == maxVal).toList();
    tops.shuffle();
    return tops.first.key;
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

/// ----------------------------
/// Question model
/// ----------------------------
class OptionItem {
  final String text;
  final String category;
  const OptionItem(this.text, this.category);
}

class Question {
  final String text;
  final List<OptionItem> options;

  late List<OptionItem> _shuffled;

  Question(this.text, this.options) {
    _shuffled = List.from(options);
  }

  List<OptionItem> get displayOptions => _shuffled;

  void shuffleOptions() {
    _shuffled = List.from(options)..shuffle();
  }
}

/// ----------------------------
/// Questions (20 ta)
/// ----------------------------
List<Question> originalQuestions = [
  Question(
    "Bo‘sh vaqtingizda ko‘proq nimani qilib ketib qolganingizni sezmay qolasiz?",
    const [
      OptionItem("Biror narsani chiroyliroq qilib ko‘rish bilan", "Grafik Dizayn"),
      OptionItem("Atrofimdagi narsalarni tartibga solish bilan", "Frontend"),
      OptionItem("Turli xil ishlarni navbatma-navbat qilib", "Flutter"),
      OptionItem("Bosh qotiradigan masalalar bilan", "Backend"),
      OptionItem("Hamma narsa joyida ekanini tekshirib", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Yangi joyga kirganingizda nimasi tezroq ko‘zingizga tashlanadi?",
    const [
      OptionItem("Qanday bezatilgani", "Grafik Dizayn"),
      OptionItem("Qanchalik qulay ekanligi", "Frontend"),
      OptionItem("Qanday harakat bo‘layotgani", "Flutter"),
      OptionItem("Ichki tartibi", "Backend"),
      OptionItem("Xavfsiz yoki yo‘qligi", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Biror buyum sizga yoqishi uchun nimasi muhimroq?",
    const [
      OptionItem("Ko‘rinishi", "Grafik Dizayn"),
      OptionItem("Qulayligi", "Frontend"),
      OptionItem("Har xil holatga mosligi", "Flutter"),
      OptionItem("Uzoq xizmat qilishi", "Backend"),
      OptionItem("Ishonch berishi", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Do‘stlaringiz muammo bo‘lsa sizga qachon murojaat qilishadi?",
    const [
      OptionItem("Biror narsani chiroyli qilib berish kerak bo‘lsa", "Grafik Dizayn"),
      OptionItem("Qanday qulay ishlatishni tushunmay qolishsa", "Frontend"),
      OptionItem("Biror ishni tezda qilib berish kerak bo‘lsa", "Flutter"),
      OptionItem("Boshlari qotib qolsa", "Backend"),
      OptionItem("Ishonchli maslahat kerak bo‘lsa", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Biror ishni qilayotganda qaysi holat sizga ko‘proq yoqadi?",
    const [
      OptionItem("Natija ko‘zni quvontirsa", "Grafik Dizayn"),
      OptionItem("Odamlar qiynalmasdan foydalansa", "Frontend"),
      OptionItem("Jarayon zeriktirmasa", "Flutter"),
      OptionItem("Hamma narsa o‘z o‘rnida bo‘lsa", "Backend"),
      OptionItem("Xavotir bo‘lmasa", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Biror narsa ishlamay qolsa, odatda nima qilasiz?",
    const [
      OptionItem("Tashqi tomondan o‘zgartirib ko‘raman", "Grafik Dizayn"),
      OptionItem("Qanday ishlatilishini qayta ko‘rib chiqaman", "Frontend"),
      OptionItem("Qayta-qayta sinab ko‘raman", "Flutter"),
      OptionItem("Nega bunday bo‘lganini o‘ylab ko‘raman", "Backend"),
      OptionItem("Xavf yo‘qmi deb tekshiraman", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Quyidagilardan qaysi biri sizni tezroq bezovta qiladi?",
    const [
      OptionItem("Betartiblik", "Grafik Dizayn"),
      OptionItem("Noqulaylik", "Frontend"),
      OptionItem("Sekinlik", "Flutter"),
      OptionItem("Tushunarsizlik", "Backend"),
      OptionItem("Ishonchsizlik", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Qaysi muhitda o‘zingizni erkinroq his qilasiz?",
    const [
      OptionItem("Ilhom beradigan joyda", "Grafik Dizayn"),
      OptionItem("Hammasi aniq bo‘lgan joyda", "Frontend"),
      OptionItem("Harakat ko‘p bo‘lgan joyda", "Flutter"),
      OptionItem("Sokin va jim joyda", "Backend"),
      OptionItem("Nazoratli joyda", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Film yoki serial ko‘rayotganda nimasi sizni ko‘proq tortadi?",
    const [
      OptionItem("Tasvir va muhit", "Grafik Dizayn"),
      OptionItem("Tushunarli voqealar", "Frontend"),
      OptionItem("Ritmi va tezligi", "Flutter"),
      OptionItem("Mantiqiy bog‘liqlik", "Backend"),
      OptionItem("Sirli tomonlari", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Sizni qaysi holat ko‘proq xursand qiladi?",
    const [
      OptionItem("Ko‘zimga yoqadigan natija", "Grafik Dizayn"),
      OptionItem("Odamlar rozi bo‘lishi", "Frontend"),
      OptionItem("Ishlar tez yurishi", "Flutter"),
      OptionItem("Muammo yechilishi", "Backend"),
      OptionItem("Xotirjamlik bo‘lishi", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Biror ishni boshlashdan oldin ichingizda qaysi savol paydo bo‘ladi?",
    const [
      OptionItem("Chiroyli chiqadimi?", "Grafik Dizayn"),
      OptionItem("Odamlar tushuna oladimi?", "Frontend"),
      OptionItem("Tez bitadimi?", "Flutter"),
      OptionItem("Ichida nima bo‘lyapti?", "Backend"),
      OptionItem("Muammo chiqmaydimi?", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Qaysi vaziyatda o‘zingizni foydaliroq his qilasiz?",
    const [
      OptionItem("Biror narsani bezab bersam", "Grafik Dizayn"),
      OptionItem("Biror ishni osonlashtirsam", "Frontend"),
      OptionItem("Ishlar tezlashsa", "Flutter"),
      OptionItem("Chalkashlikni yo‘qotsam", "Backend"),
      OptionItem("Xavfni oldini olsam", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Quyidagi ishlarning qaysi biri sizga yaqinroq?",
    const [
      OptionItem("Tasavvur qilish", "Grafik Dizayn"),
      OptionItem("Tushuntirib berish", "Frontend"),
      OptionItem("Harakat qilish", "Flutter"),
      OptionItem("Tahlil qilish", "Backend"),
      OptionItem("Kuzatib turish", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Biror narsani baholayotganda nimaga qaraysiz?",
    const [
      OptionItem("Ko‘zimga yoqadimi", "Grafik Dizayn"),
      OptionItem("Foydalanish osonmi", "Frontend"),
      OptionItem("Qanday ishlaydi", "Flutter"),
      OptionItem("Ichidan puxtami", "Backend"),
      OptionItem("Ishonchlimi", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Qachon o‘zingizdan mamnun bo‘lasiz?",
    const [
      OptionItem("Natija chiroyli bo‘lsa", "Grafik Dizayn"),
      OptionItem("Odamlar qiynalmasa", "Frontend"),
      OptionItem("Ish tez bitsa", "Flutter"),
      OptionItem("Muammo qolmasa", "Backend"),
      OptionItem("Xavotir bo‘lmasa", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Yangi narsaga munosabatingiz qanday?",
    const [
      OptionItem("Ko‘zimga yoqsa sinab ko‘raman", "Grafik Dizayn"),
      OptionItem("Qulay bo‘lsa yetarli", "Frontend"),
      OptionItem("Oson bo‘lsa yoqadi", "Flutter"),
      OptionItem("Mantiqli bo‘lsa qiziq", "Backend"),
      OptionItem("Xavfsiz bo‘lsa ishonaman", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Siz uchun yaxshi bajarilgan ish nimasi bilan bilinadi?",
    const [
      OptionItem("Ko‘rinishi bilan", "Grafik Dizayn"),
      OptionItem("Oson ishlatilishi bilan", "Frontend"),
      OptionItem("Muammosiz ishlashi bilan", "Flutter"),
      OptionItem("Ichidan puxta bo‘lishi bilan", "Backend"),
      OptionItem("Xotirjamlik berishi bilan", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Qaysi holatda ko‘proq asabiylashasiz?",
    const [
      OptionItem("Didga to‘g‘ri kelmasa", "Grafik Dizayn"),
      OptionItem("Noqulay bo‘lsa", "Frontend"),
      OptionItem("Sekin bo‘lsa", "Flutter"),
      OptionItem("Tushunarsiz bo‘lsa", "Backend"),
      OptionItem("Xavf sezilsa", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Agar biror ish sizga topshirilsa, nimaga ko‘proq e’tibor berasiz?",
    const [
      OptionItem("Qanday ko‘rinishiga", "Grafik Dizayn"),
      OptionItem("Odamlar qanday ishlatishiga", "Frontend"),
      OptionItem("Qanchalik tez bajarilishiga", "Flutter"),
      OptionItem("Ichki tartibiga", "Backend"),
      OptionItem("Xavfsizligiga", "Kiberxavfsizlik"),
    ],
  ),
  Question(
    "Sizni eng ko‘p qoniqtiradigan holat qaysi?",
    const [
      OptionItem("Natija ko‘zni quvontirsa", "Grafik Dizayn"),
      OptionItem("Hamma tushunsa", "Frontend"),
      OptionItem("Ishlar tez yursa", "Flutter"),
      OptionItem("Hamma narsa joyida bo‘lsa", "Backend"),
      OptionItem("Xotirjam bo‘lsam", "Kiberxavfsizlik"),
    ],
  ),
];

final Map<String, Map<String, String>> directionInfo = {
  "Grafik Dizayn": {
    "desc": "Logolar, bannerlar, UI/UX dizaynlar yaratish. Eng ijodiy IT yo‘nalishi!",
    "tools": "Figma, Adobe XD, Photoshop, Illustrator",
    "salary": "O‘rtacha: 200-700\$ (junior-mid)",
    "demand": "Juda yuqori",
    "difficulty": "O‘rganish oson, ijod talab qiladi",
  },
  "Frontend": {
    "desc": "Veb-saytlarning ko‘rinadigan qismini yaratish. Foydalanuvchi bilan bevosita aloqa!",
    "tools": "HTML, CSS, JavaScript, React, Vue",
    "salary": "O‘rtacha: 300-900\$",
    "demand": "Doimiy talab",
    "difficulty": "O‘rtacha qiyinlik",
  },
  "Flutter": {
    "desc": "Bitta kod bilan Android va iOS ilovalari yasash. Mobil dunyoning kelajagi!",
    "tools": "Dart, Flutter SDK",
    "salary": "O‘rtacha: 300-1000\$",
    "demand": "Tez o‘sib borayotgan",
    "difficulty": "O‘rtacha, Dartni o‘rganish kerak",
  },
  "Backend": {
    "desc": "Server, ma'lumotlar bazasi va logikani boshqarish. Saytning 'miyasi'!",
    "tools": "Python, Node.js, Java, PHP, SQL",
    "salary": "O‘rtacha: 300-1500\$",
    "demand": "Juda yuqori",
    "difficulty": "Qiyinroq, mantiq talab qiladi",
  },
  "Kiberxavfsizlik": {
    "desc": "Tizimlarni xakerlardan himoya qilish. Kelajakning eng muhim va yuqori maoshli sohasi!",
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

/// ----------------------------
/// Welcome
/// ----------------------------
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
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info["desc"]!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 14),
                _infoRow("Asboblar:", info["tools"]!),
                _infoRow("O‘rtacha maosh:", info["salary"]!),
                _infoRow("Talab:", info["demand"]!),
                _infoRow("Qiyinlik:", info["difficulty"]!),
              ],
            ),
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
                fontSize: 15,
              ),
            ),
            TextSpan(
              text: " $value",
              style: const TextStyle(color: Colors.white, fontSize: 15),
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
    final pad = R.pagePadding(context);

    return Scaffold(
      body: BackgroundContainer(
        child: SafeArea(
          child: CenteredContent(
            child: SingleChildScrollView(
              padding: pad,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "IT Yo‘lim",
                    style: TextStyle(
                      fontSize: R.titleSize(context),
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          blurRadius: 20,
                          color: Colors.black45,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "O‘zingizga eng mos IT yo‘nalishini toping!",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    "Yo‘nalishlar haqida batafsil ma’lumot:",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: R.gridCountForDirections(context),
                      childAspectRatio: R.isPhone(context) ? 1.15 : 1.35,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: directionInfo.keys.length,
                    itemBuilder: (context, index) {
                      final dir = directionInfo.keys.elementAt(index);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => showDirectionInfo(context, dir),
                        child: Card(
                          color: Colors.white.withOpacity(0.14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_getIcon(dir),
                                    size: 44, color: Colors.amber),
                                const SizedBox(height: 10),
                                Text(
                                  dir,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Batafsil →",
                                  style: TextStyle(
                                    fontSize: 13,
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
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Provider.of<QuizProvider>(context, listen: false)
                              .initializeQuiz();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const QuizScreen()),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 30),
                        label: const Text(
                          "Testni boshlash",
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 16,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 10,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => shareOrCopy(
                          context,
                          "Siz qachon tushunib yetasiz IT kelajak kasb ekanligini? Saytga kiring va o‘zingizga mos IT yo‘nalishini toping! 🚀\n@codialuz",
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text("Do‘stlarga ulashish"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// Quiz
/// ----------------------------
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: SafeArea(
          child: CenteredContent(
            child: Consumer<QuizProvider>(
              builder: (context, quiz, child) {
                final question = quiz.questions[quiz.currentQuestionIndex];

                return Padding(
                  padding: R.pagePadding(context),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Savol ${quiz.currentQuestionIndex + 1}/20",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              if (quiz.currentQuestionIndex > 0)
                                IconButton(
                                  tooltip: "Orqaga",
                                  onPressed: quiz.previousQuestion,
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                ),
                              IconButton(
                                tooltip: "Qayta boshlash",
                                icon: const Icon(Icons.restart_alt,
                                    color: Colors.white),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor:
                                      Colors.deepPurple.shade800,
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
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (quiz.currentQuestionIndex + 1) / 20,
                          minHeight: 10,
                          color: Colors.amber,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Card(
                          color: Colors.white.withOpacity(0.10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Text(
                                  question.text,
                                  style: TextStyle(
                                    fontSize: R.isPhone(context) ? 20 : 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: question.displayOptions.length,
                                    itemBuilder: (context, i) {
                                      final selected = quiz.selectedOption == i;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: AnimatedScale(
                                          scale: selected ? 1.03 : 1.0,
                                          duration:
                                          const Duration(milliseconds: 160),
                                          curve: Curves.easeOut,
                                          child: InkWell(
                                            borderRadius:
                                            BorderRadius.circular(16),
                                            onTap: () =>
                                                quiz.selectOption(i, context),
                                            child: Card(
                                              elevation: selected ? 10 : 2,
                                              color: selected
                                                  ? Colors.deepPurple.shade700
                                                  .withOpacity(0.78)
                                                  : Colors.white
                                                  .withOpacity(0.14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(16),
                                              ),
                                              child: Padding(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 16,
                                                  horizontal: 16,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      selected
                                                          ? Icons
                                                          .check_circle_rounded
                                                          : Icons
                                                          .circle_outlined,
                                                      color: selected
                                                          ? Colors.greenAccent
                                                          .shade400
                                                          : Colors.white70,
                                                      size: 26,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        question
                                                            .displayOptions[i]
                                                            .text,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.white,
                                                          height: 1.25,
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
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// Result
/// ----------------------------
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
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: " $value",
              style: const TextStyle(color: Colors.white, fontSize: 15),
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

    final allFacts = List<String>.from(directionFacts[topDirection] ?? const [])
      ..shuffle();
    final visibleFacts = allFacts.take(4).toList();

    final size = MediaQuery.sizeOf(context);
    final isPhone = R.isPhone(context);

    // ✅ FIX: telefon uchun chartni kattaroq qilamiz
    final chartSize = isPhone
        ? math.min(380.0, size.width * 0.95)
        : math.min(420.0, math.max(260.0, size.width * 0.62));

    return Scaffold(
      body: BackgroundContainer(
        child: SafeArea(
          child: CenteredContent(
            child: SingleChildScrollView(
              padding: R.pagePadding(context),
              child: Column(
                children: [
                  Text(
                    "🎉 Natija tayyor!",
                    style: TextStyle(
                      fontSize: R.isPhone(context) ? 30 : 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Sizga eng mos IT yo‘nalishi:",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topDirection,
                    style: TextStyle(
                      fontSize: R.isPhone(context) ? 36 : 44,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  // ✅ FIX: telefonda legend pie ichida bo‘lsa doira kichrayib ketadi.
                  // Shuning uchun: telefon -> legendni o‘chirib, pastga alohida chiqaramiz.
                  Column(
                    children: [
                      SizedBox(
                        width: chartSize,
                        height: chartSize,
                        child: PieChart(
                          dataMap: quiz.dataMap,
                          chartRadius: chartSize / 2,
                          colorList: const [
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                            Colors.blue,
                            Colors.red,
                          ],
                          legendOptions: LegendOptions(
                            showLegends: !isPhone,
                            legendPosition: LegendPosition.bottom,
                            legendTextStyle:
                            const TextStyle(color: Colors.white),
                          ),
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValuesInPercentage: true,
                            chartValueStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (isPhone) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: quiz.dataMap.entries.map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                "${e.key}: ${e.value.toInt()}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),

                  Card(
                    color: Colors.white.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_getIcon(topDirection),
                                  size: 38, color: Colors.amber),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  topDirection,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            directionInfo[topDirection]?["desc"] ??
                                "Ma'lumot topilmadi.",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            "Asboblar:",
                            directionInfo[topDirection]?["tools"] ?? "-",
                          ),
                          _infoRow(
                            "O‘rtacha maosh:",
                            directionInfo[topDirection]?["salary"] ?? "-",
                          ),
                          _infoRow(
                            "Talab:",
                            directionInfo[topDirection]?["demand"] ?? "-",
                          ),
                          _infoRow(
                            "Qiyinlik:",
                            directionInfo[topDirection]?["difficulty"] ?? "-",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Card(
                    color: Colors.white.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb,
                                  color: Colors.amber, size: 30),
                              SizedBox(width: 10),
                              Text(
                                "Qiziqarli faktlar",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (visibleFacts.isEmpty)
                            const Text(
                              "Faktlar topilmadi.",
                              style: TextStyle(color: Colors.white),
                            ),
                          ...visibleFacts.map(
                                (fact) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "• ",
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 22,
                                      height: 1.4,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      fact,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          quiz.reset();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WelcomeScreen()),
                          );
                        },
                        icon: const Icon(Icons.restart_alt),
                        label: const Text("Yana sinash"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => shareOrCopy(
                          context,
                          "Mening IT yo‘nalishim: $topDirection! 🎯\nIT Yo‘lim testidan o‘tdim!",
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text("Ulashish"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
