import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // 🟢 À placer impérativement tout en haut !
import 'dart:convert'; // Permet de manipuler le format texte JSON
import 'dart:html'
    as html; // Permet de parler directement à la mémoire du navigateur Web

// 1. Modèle Utilisateur / Ami
class AppUser {
  final String id;
  final String pseudo;
  final String tag; // ex: #1234
  int xp;
  final Map<String, int> folderProgress; // folderId -> % de réussite

  AppUser({
    required this.id,
    required this.pseudo,
    required this.tag,
    this.xp = 0,
    this.folderProgress = const {},
  });

  String get displayName => '$pseudo$tag';
}

// 2. Enumération pour les Rôles de Partage
enum ShareRole { owner, editor, reader }

// 3. Modèle Flashcard (Mise à jour)

class AppData {
  // Profil de l'utilisateur connecté
  static AppUser? currentUser;

  // Liste des dossiers de l'utilisateur
  static List<Folder> folders = [];

  // Base de données simulée des amis du Leaderboard
  static List<AppUser> mockFriends = [
    AppUser(
      id: 'f1',
      pseudo: 'Thomas',
      tag: '#4821',
      xp: 2450,
      folderProgress: {'1': 80},
    ),
    AppUser(
      id: 'f2',
      pseudo: 'Sarah',
      tag: '#1105',
      xp: 3100,
      folderProgress: {'1': 95},
    ),
    AppUser(
      id: 'f3',
      pseudo: 'Alex',
      tag: '#9942',
      xp: 1200,
      folderProgress: {'1': 40},
    ),
  ];

  // Générateur de tag unique (ex: #5412)
  static String generateRandomTag() {
    final random = Random();
    int num = random.nextInt(9000) + 1000;
    return '#$num';
  }

  // Générateur de code à 6 lettres pour le partage
  static String generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Simulation d'un import de dossier via code à 6 lettres
  static Folder? importFolderByCode(String code, String currentUserId) {
    // Simulation : On crée un faux dossier distant "importé"
    // En Firebase, cela irait chercher le dossier correspondant au code
    if (code.length != 6) return null;

    // On simule qu'un code commençant par 'R' donne un rôle LECTEUR, sinon ÉDITEUR
    ShareRole roleAttribue = code.toUpperCase().startsWith('R')
        ? ShareRole.reader
        : ShareRole.editor;

    return Folder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Dossier Partagé ($code)',
      creatorId: 'distant_user_id',
      shareCode: code.toUpperCase(),
      currentUserRole: roleAttribue,
      cards: [
        Flashcard(
          id: 'c1',
          question: r'Calculer $$\lim_{x \to 0} \frac{\sin x}{x}$$',
          response: '1',
          nextReviewDate: DateTime.now(),
        ),
      ],
    );
  }
}

void main() {
  runApp(const MyApp());
}

// --- MODÈLES DE DONNÉES ---
class Flashcard {
  final String id;
  String question;
  String response;
  DateTime nextReviewDate;
  int currentIntervalIndex;
  int previousIntervalIndex;
  bool isInUrgencyMode;
  int urgencyStep;
  String? imageUrl;
  List<DrawingPoint?>? drawingPoints;

  Flashcard({
    required this.id,
    required this.question,
    required this.response,
    required this.nextReviewDate,
    this.currentIntervalIndex = 0,
    this.previousIntervalIndex = 0,
    this.isInUrgencyMode = false,
    this.urgencyStep = 0,
    this.imageUrl,
    this.drawingPoints,
  });

  // 💾 Convertit la carte en texte JSON pour la sauvegarder
  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'response': response,
    'nextReviewDate': nextReviewDate.toIso8601String(),
    'currentIntervalIndex': currentIntervalIndex,
    'previousIntervalIndex': previousIntervalIndex,
    'isInUrgencyMode': isInUrgencyMode,
    'urgencyStep': urgencyStep,
  };

  // 📂 Reconstruit la carte depuis le texte sauvegardé
  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'],
    question: json['question'],
    response: json['response'],
    nextReviewDate: DateTime.parse(json['nextReviewDate']),
    currentIntervalIndex: json['currentIntervalIndex'] ?? 0,
    previousIntervalIndex: json['previousIntervalIndex'] ?? 0,
    isInUrgencyMode: json['isInUrgencyMode'] ?? false,
    urgencyStep: json['urgencyStep'] ?? 0,
  );
}

class Folder {
  String id;
  String title;
  List<Flashcard> cards;
  List<Folder> subFolders;
  List<int> intervalProfile;
  String profileName;

  String creatorId;
  String shareCode;
  ShareRole currentUserRole;

  Folder({
    required this.id,
    required this.title,
    List<Flashcard>? cards,
    List<Folder>? subFolders,
    this.intervalProfile = const [1, 3, 7, 14],
    this.profileName = 'Standard (Long terme)',
    this.creatorId = 'local_user',
    this.shareCode = 'AAAAAA',
    this.currentUserRole = ShareRole.owner,
  }) : cards = cards ?? [],
       subFolders = subFolders ?? [];

  // 💾 Convertit le dossier (et tout son contenu) en JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'cards': cards.map((c) => c.toJson()).toList(),
    'subFolders': subFolders.map((s) => s.toJson()).toList(),
    'intervalProfile': intervalProfile,
    'profileName': profileName,
    'creatorId': creatorId,
    'shareCode': shareCode,
    'currentUserRole': currentUserRole.index, // On stocke l'index de l'enum
  };

  // 📂 Reconstruit le dossier (et tout son contenu) depuis le JSON
  factory Folder.fromJson(Map<String, dynamic> json) {
    var folder = Folder(
      id: json['id'],
      title: json['title'],
      intervalProfile: List<int>.from(json['intervalProfile'] ?? [1, 3, 7, 14]),
      profileName: json['profileName'] ?? 'Standard (Long terme)',
      creatorId: json['creatorId'] ?? 'local_user',
      shareCode: json['shareCode'] ?? 'AAAAAA',
      currentUserRole: ShareRole.values[json['currentUserRole'] ?? 0],
    );

    if (json['cards'] != null) {
      folder.cards = (json['cards'] as List)
          .map((c) => Flashcard.fromJson(c))
          .toList();
    }
    if (json['subFolders'] != null) {
      folder.subFolders = (json['subFolders'] as List)
          .map((s) => Folder.fromJson(s))
          .toList();
    }

    return folder;
  }

  int get cardsToReviewCount {
    final now = DateTime.now();
    int localCount = cards
        .where(
          (card) =>
              card.nextReviewDate.isBefore(now) ||
              card.nextReviewDate.isAtSameMomentAs(now) ||
              DateUtils.isSameDay(card.nextReviewDate, now),
        )
        .length;

    int subCount = 0;
    for (var sub in subFolders) {
      subCount += sub.cardsToReviewCount;
    }
    return localCount + subCount;
  }

  List<Flashcard> getAllCardsRecursive() {
    List<Flashcard> all = List.from(cards);
    for (var sub in subFolders) {
      all.addAll(sub.getAllCardsRecursive());
    }
    return all;
  }

  double get masteryPercentage {
    List<Flashcard> allCards = getAllCardsRecursive();
    if (allCards.isEmpty) return 0.0;

    double totalPoints = 0;
    int maxLevel = intervalProfile.length;

    for (var card in allCards) {
      if (card.currentIntervalIndex == 0 &&
          card.nextReviewDate.isAfter(DateTime.now())) {
        totalPoints += 1.0;
      } else {
        totalPoints += card.currentIntervalIndex;
      }
    }
    double percentage = totalPoints / (allCards.length * maxLevel);
    return percentage.clamp(0.0, 1.0);
  }
}

class DrawingPoint {
  final Offset
  offset; // On garde bien 'offset' pour correspondre à ton constructeur originel
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

// 🔄 REMPLACE LA CLASSE DE LA LIGNE 98 PAR CELLE-CI :
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

// 📍 NOUVEAUTÉ V2 : Dessinateur dédié aux schémas fixes des Flashcards
class StudioPainter extends CustomPainter {
  final List<Offset?> points;
  StudioPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.deepPurple
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StudioPainter oldDelegate) =>
      oldDelegate.points != points;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  int _xp = 210;
  int _streak = 5;

  List<Folder> _rootFolders = [];
  final List<int> _xpHistory = [40, 80, 10, 110, 50, 0, 0];

  final List<Map<String, dynamic>> _allPrograms = [
    {
      'name': 'Standard (Long terme)',
      'profile': [1, 3, 7, 14],
    },
    {
      'name': 'Intensif (Examen proche)',
      'profile': [1, 2, 4, 7],
    },
    {
      'name': 'Serein (Rythme cool)',
      'profile': [2, 5, 10, 20],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDataFromBrowser(); // 📂 On charge les données sauvegardées au démarrage !
  }

  // 📂 Fonction pour charger les dossiers depuis le navigateur web
  void _loadDataFromBrowser() {
    try {
      final savedFoldersText = html.window.localStorage['flashlearn_folders'];
      final savedXpText = html.window.localStorage['flashlearn_xp'];

      if (savedFoldersText != null) {
        final List<dynamic> decoded = jsonDecode(savedFoldersText);
        setState(() {
          _rootFolders = decoded.map((f) => Folder.fromJson(f)).toList();
        });
      } else {
        // Si aucune sauvegarde n'existe, on met ton dossier de Mathématiques par défaut
        _rootFolders.add(
          Folder(
            id: '1',
            title: 'Mathématiques',
            intervalProfile: [1, 3, 7, 14],
            profileName: 'Standard (Long terme)',
            subFolders: [
              Folder(
                id: '1-1',
                title: 'Analyse - Intégrales',
                intervalProfile: [1, 3, 7, 14],
                profileName: 'Standard (Long terme)',
                cards: [
                  Flashcard(
                    id: 'm1',
                    question:
                        r"Formule de l'intégration par parties ?\n$$\int u'v = [uv] - \int uv'$$",
                    response: r"Dérivée du produit : $$(uv)' = u'v + uv'$$",
                    nextReviewDate: DateTime.now().subtract(
                      const Duration(minutes: 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      if (savedXpText != null) {
        setState(() {
          _xp = int.parse(savedXpText);
        });
      }
    } catch (e) {
      print("Erreur de chargement : $e");
    }

    // Synchro avec le gestionnaire global
    AppData.folders = _rootFolders;
  }

  // 💾 Fonction pour sauvegarder l'état actuel dans le navigateur web
  void _saveDataToBrowser() {
    try {
      final String encodedFolders = jsonEncode(
        _rootFolders.map((f) => f.toJson()).toList(),
      );
      html.window.localStorage['flashlearn_folders'] = encodedFolders;
      html.window.localStorage['flashlearn_xp'] = _xp.toString();
    } catch (e) {
      print("Erreur de sauvegarde : $e");
    }
  }

  void _gainXp(int amount) {
    setState(() {
      _xp += amount;
      if (AppData.currentUser != null) {
        AppData.currentUser!.xp = _xp;
      }
      _xpHistory[DateTime.now().weekday - 1] += amount;
    });
    _saveDataToBrowser(); // 💾 Sauvegarde automatique dès qu'on gagne de l'XP !
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlashLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      home: AdaptiveDashboard(
        isDarkMode: _isDarkMode,
        onThemeChanged: (value) => setState(() => _isDarkMode = value),
        rootFolders: _rootFolders,
        xp: _xp,
        streak: _streak,
        xpHistory: _xpHistory,
        onXpGain: _gainXp,
        programs: _allPrograms,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final List<Folder> rootFolders;
  final int xp, streak;
  final List<int> xpHistory;
  final Function(int) onXpGain;
  final List<Map<String, dynamic>> programs;

  const MainNavigationScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.rootFolders,
    required this.xp,
    required this.streak,
    required this.xpHistory,
    required this.onXpGain,
    required this.programs,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        rootFolders: widget.rootFolders,
        streak: widget.streak,
        onXpGain: widget.onXpGain,
        programs: widget.programs,
      ),
      StatsScreen(
        xp: widget.xp,
        streak: widget.streak,
        xpHistory: widget.xpHistory,
      ),
      SocialScreen(
        onFolderImported: (newFolder) {
          setState(() {
            AppData.folders.add(newFolder);
          });
        },
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.deepPurple,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Dossiers'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Classement',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final List<Folder> rootFolders;
  final int streak;
  final Function(int) onXpGain;
  final List<Map<String, dynamic>> programs;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.rootFolders,
    required this.streak,
    required this.onXpGain,
    required this.programs,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Folder> _navigationHistory = [];

  List<Folder> get _currentFolderList {
    if (_navigationHistory.isEmpty) return widget.rootFolders;
    return _navigationHistory.last.subFolders;
  }

  List<Flashcard> get _currentCardList {
    if (_navigationHistory.isEmpty) return [];
    return _navigationHistory.last.cards;
  }

  void _showImportDialog(BuildContext context) {
    final contentController = TextEditingController();
    final String currentTargetName = _navigationHistory.isNotEmpty
        ? _navigationHistory.last.title
        : 'la Racine (Global)';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('📥 Injecter des cartes dans : $currentTargetName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Les cartes générées par l\'IA avec syntaxe ' +
                    r'$$\frac{a}{b}$$' +
                    ' ou ' +
                    r'$$\int$$' +
                    ' s\'ajouteront directement ici.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Colle le bloc de texte de l\'IA ici',
                  hintText:
                      r'Format attendu :'
                      '\n'
                      r'Q: Question avec $$\alpha$$'
                      '\n'
                      r'R: Réponse avec $$\frac{1}{2}$$\n---',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (contentController.text.isNotEmpty) {
                List<Flashcard> parsedCards = [];
                List<String> blocks = contentController.text.split('---');

                for (var block in blocks) {
                  var lines = block.trim().split('\n');
                  String q = '', r = '';
                  for (var line in lines) {
                    if (line.trim().startsWith('Q:'))
                      q = line.replaceFirst('Q:', '').trim();
                    if (line.trim().startsWith('R:'))
                      r = line.replaceFirst('R:', '').trim();
                  }
                  if (q.isNotEmpty && r.isNotEmpty) {
                    parsedCards.add(
                      Flashcard(
                        id: DateTime.now().toString() + q.hashCode.toString(),
                        question: q,
                        response: r,
                        nextReviewDate: DateTime.now(),
                      ),
                    );
                  }
                }

                if (parsedCards.isNotEmpty) {
                  setState(() {
                    if (_navigationHistory.isNotEmpty) {
                      _navigationHistory.last.cards.addAll(parsedCards);
                    } else {
                      final defaultFolder = Folder(
                        id: DateTime.now().toString(),
                        title: 'Cartes Importées',
                        profileName: 'Standard (Long terme)',
                        cards: parsedCards,
                      );
                      widget.rootFolders.add(defaultFolder);
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '📥 ${parsedCards.length} cartes ajoutées avec succès !',
                      ),
                    ),
                  );
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Injecter les cartes'),
          ),
        ],
      ),
    );
  }

  void _showCustomProgramDialog(
    BuildContext context,
    Function(Map<String, dynamic>) onSave,
  ) {
    final nameController = TextEditingController();
    final p1 = TextEditingController(text: '1');
    final p2 = TextEditingController(text: '3');
    final p3 = TextEditingController(text: '7');
    final p4 = TextEditingController(text: '14');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✨ Créer ton programme'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de ton rythme',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Délais de répétition (en jours) :',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: p1,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Niv 1'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: p2,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Niv 2'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: p3,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Niv 3'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: p4,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Niv 4'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final customProg = {
                  'name': '⭐ ${nameController.text}',
                  'profile': [
                    int.tryParse(p1.text) ?? 1,
                    int.tryParse(p2.text) ?? 3,
                    int.tryParse(p3.text) ?? 7,
                    int.tryParse(p4.text) ?? 14,
                  ],
                };
                onSave(customProg);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    Map<String, dynamic> selectedPlanning = widget.programs.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            _navigationHistory.isEmpty
                ? 'Nouveau Dossier'
                : 'Nouveau Sous-Dossier',
          ),
          content: SingleChildScrollView(
            // 🟢 AJOUTÉ : Rend le formulaire scrollable sur le Web
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Électromagnétisme',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Programme :',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Créer',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        _showCustomProgramDialog(context, (newProg) {
                          setState(() {
                            widget.programs.add(newProg);
                          });
                          setDialogState(() {
                            selectedPlanning = newProg;
                          });
                        });
                      },
                    ),
                  ],
                ),
                DropdownButton<Map<String, dynamic>>(
                  value: selectedPlanning,
                  isExpanded: true,
                  items: widget.programs
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p, child: Text(p['name'])),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedPlanning = v!),
                ),
              ],
            ),
          ), // 🟢 AJOUTÉ : Fermeture du SingleChildScrollView
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    final newFolder = Folder(
                      id: DateTime.now().toString(),
                      title: controller.text,
                      intervalProfile: selectedPlanning['profile'],
                      profileName: selectedPlanning['name'],
                    );
                    _currentFolderList.add(newFolder);
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subFolders = _currentFolderList;
    final directCards = _currentCardList;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🔥 FlashLearn',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  'Streak: ${widget.streak}j',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                IconButton(
                  icon: Icon(
                    widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                    color: Colors.white,
                  ),
                  onPressed: () => widget.onThemeChanged(!widget.isDarkMode),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_navigationHistory.isNotEmpty)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.deepPurple,
                    ),
                    onPressed: () =>
                        setState(() => _navigationHistory.removeLast()),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _navigationHistory.clear()),
                            child: const Text(
                              'Home',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ..._navigationHistory
                              .map(
                                (folder) => Row(
                                  children: [
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          int idx = _navigationHistory.indexOf(
                                            folder,
                                          );
                                          _navigationHistory.removeRange(
                                            idx + 1,
                                            _navigationHistory.length,
                                          );
                                        });
                                      },
                                      child: Text(
                                        folder.title,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _navigationHistory.isEmpty
                      ? 'Mes Dossiers'
                      : _navigationHistory.last.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.blue),
                      tooltip: 'Importation Magique (IA)',
                      onPressed: () => _showImportDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.create_new_folder,
                        color: Colors.deepPurple,
                      ),
                      tooltip: 'Nouveau dossier',
                      onPressed: () => _showAddFolderDialog(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: (subFolders.isEmpty && directCards.isEmpty)
                  ? const Center(
                      child: Text(
                        'Dossier vide. Importe des cartes ou crée des sous-dossiers.',
                      ),
                    )
                  : ListView(
                      children: [
                        if (subFolders.isNotEmpty) ...[
                          ...List.generate(subFolders.length, (index) {
                            final folder = subFolders[index];
                            final int reviewCount = folder.cardsToReviewCount;
                            final double mastery = folder.masteryPercentage;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: const Icon(
                                  Icons.folder,
                                  size: 40,
                                  color: Colors.amber,
                                ),
                                title: Text(
                                  folder.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📅 Rythme : ${folder.profileName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      reviewCount > 0
                                          ? '⏳ $reviewCount cartes à réviser'
                                          : '🚀 Mode Libre disponible !',
                                      style: TextStyle(
                                        color: reviewCount > 0
                                            ? Colors.orange.shade800
                                            : Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: mastery,
                                            backgroundColor: widget.isDarkMode
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade200,
                                            color: Colors.deepPurpleAccent,
                                            minHeight: 8,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('${(mastery * 100).toInt()}%'),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.green,
                                        size: 30,
                                      ),
                                      tooltip: 'Réviser ce dossier',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FolderOptionsScreen(
                                                  folder: folder,
                                                  onXpGain: widget.onXpGain,
                                                  allPrograms: widget.programs,
                                                ),
                                          ),
                                        ).then((_) => setState(() {}));
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Supprimer',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext ctx) {
                                            return AlertDialog(
                                              title: const Text(
                                                '⚠️ Supprimer le dossier ?',
                                              ),
                                              content: Text(
                                                'Es-tu sûr de vouloir supprimer "${folder.title}" ? Cette action est irréversible et supprimera tout son contenu.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text('Annuler'),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: () {
                                                    setState(() {
                                                      subFolders.removeAt(
                                                        index,
                                                      );
                                                    });
                                                    Navigator.pop(ctx);
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Dossier "${folder.title}" supprimé.',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Supprimer',
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () => setState(
                                  () => _navigationHistory.add(folder),
                                ),
                              ),
                            );
                          }),
                        ],
                        if (directCards.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '📝 Cartes contenues dans ce dossier :',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          ...List.generate(directCards.length, (idx) {
                            final card = directCards[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              child: ListTile(
                                title: ScientificText(
                                  text: card.question,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: ScientificText(
                                  text: card.response,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      setState(() => directCards.removeAt(idx)),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (widget.rootFolders.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Créez d\'abord un dossier principal pour y ranger vos cartes !',
                ),
              ),
            );
            return;
          }

          Folder targetFolder = _navigationHistory.isNotEmpty
              ? _navigationHistory.last
              : widget.rootFolders.first;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditCardScreen(
                defaultFolder: targetFolder,
                allFolders: widget.rootFolders,
              ),
            ),
          ).then((_) {
            setState(() {});
          });
        },
        label: const Text('Créer une carte'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  final int xp;
  final int streak;
  final List<int> xpHistory;
  const StatsScreen({
    super.key,
    required this.xp,
    required this.streak,
    required this.xpHistory,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    int maxXp = xpHistory.reduce((curr, next) => curr > next ? curr : next);
    if (maxXp < 50) maxXp = 50;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Tableau de Bord'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé d\'activité',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.deepPurple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'XP Total',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$xp ✨',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Série active',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$streak jours 🔥',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'XP gagnés cette semaine',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  double percentage = xpHistory[index] / maxXp;
                  double barHeight = percentage * 110;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 16,
                        child: Text(
                          '${xpHistory[index]}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 18,
                        height: barHeight < 5 ? 5 : barHeight,
                        decoration: BoxDecoration(
                          color: DateTime.now().weekday - 1 == index
                              ? Colors.orange
                              : Colors.deepPurple.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 16,
                        child: Text(
                          days[index],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FolderOptionsScreen extends StatefulWidget {
  final Folder folder;
  final Function(int) onXpGain;
  final List<Map<String, dynamic>> allPrograms;

  const FolderOptionsScreen({
    super.key,
    required this.folder,
    required this.onXpGain,
    required this.allPrograms,
  });

  @override
  State<FolderOptionsScreen> createState() => _FolderOptionsScreenState();
}

class _FolderOptionsScreenState extends State<FolderOptionsScreen> {
  void _showChangeProgramDialog(BuildContext context) {
    Map<String, dynamic> selectedProg = widget.allPrograms.firstWhere(
      (p) => p['name'] == widget.folder.profileName,
      orElse: () => widget.allPrograms.first,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Changer de rythme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sélectionne un nouveau programme pour ce dossier :',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButton<Map<String, dynamic>>(
                value: selectedProg,
                isExpanded: true,
                items: widget.allPrograms
                    .map(
                      (p) => DropdownMenuItem(value: p, child: Text(p['name'])),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedProg = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.folder.profileName = selectedProg['name'];
                  widget.folder.intervalProfile = List<int>.from(
                    selectedProg['profile'],
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rythme actuel : ${widget.folder.profileName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'Lancer la Révision globale',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewScreen(
                        folder: widget.folder,
                        onXpGain: widget.onXpGain,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  side: const BorderSide(color: Colors.deepPurple),
                ),
                icon: const Icon(Icons.settings, color: Colors.deepPurple),
                label: const Text(
                  '⚙️ Gérer / Éditer les cartes',
                  style: TextStyle(fontSize: 18, color: Colors.deepPurple),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ManageCardsScreen(folder: widget.folder),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: const Text('Modifier le programme de révision'),
                onPressed: () => _showChangeProgramDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onProfileCreated;
  const OnboardingScreen({Key? key, required this.onProfileCreated})
    : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pseudoController = TextEditingController();

  void _createProfile() {
    if (_pseudoController.text.trim().isEmpty) return;

    setState(() {
      AppData.currentUser = AppUser(
        id: 'local_user',
        pseudo: _pseudoController.text.trim(),
        tag: AppData.generateRandomTag(),
        xp: 0,
      );
    });
    widget.onProfileCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text(
                'Bienvenue !',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisis un pseudo pour commencer tes révisions.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pseudoController,
                decoration: InputDecoration(
                  labelText: 'Mon Pseudo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _createProfile,
                  child: const Text(
                    'Créer mon profil',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialScreen extends StatefulWidget {
  final Function(Folder) onFolderImported;
  const SocialScreen({Key? key, required this.onFolderImported})
    : super(key: key);

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _codeController = TextEditingController();
  final _friendController = TextEditingController();

  void _handleImportCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le code doit faire 6 lettres.')),
      );
      return;
    }

    final newFolder = AppData.importFolderByCode(
      code,
      AppData.currentUser?.id ?? '',
    );
    if (newFolder != null) {
      widget.onFolderImported(newFolder);
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dossier importé en mode : ${newFolder.currentUserRole == ShareRole.reader ? "Lecteur seul" : "Éditeur"}',
          ),
        ),
      );
    }
  }

  void _addFriend() {
    final name = _friendController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      AppData.mockFriends.add(
        AppUser(
          id: DateTime.now().toString(),
          pseudo: name,
          tag: AppData.generateRandomTag(),
          xp: 0,
        ),
      );
    });
    _friendController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = AppData.currentUser;
    // On fusionne l'utilisateur actuel et ses faux amis pour faire le classement par XP
    List<AppUser> leaderboard = [
      if (user != null) user,
      ...AppData.mockFriends,
    ];
    leaderboard.sort((a, b) => b.xp.compareTo(a.xp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté & Partage'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte Mon Profil
            if (user != null)
              Card(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          user.pseudo[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${user.xp} XP accumulés',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Section Importation de dossier à 6 lettres
            const Text(
              'Importer un dossier partagé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ex: R5X9T1 (R... = Lecture seule)',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _handleImportCode,
                  child: const Text('Importer'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section Leaderboard
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Classement des Amis (XP)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.deepPurple),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Ajouter un ami'),
                      content: TextField(
                        controller: _friendController,
                        decoration: const InputDecoration(
                          hintText: 'Pseudo de ton ami',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _addFriend();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                bool isMe = entry.id == user?.id;
                return ListTile(
                  leading: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: index == 0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                  title: Text(
                    entry.displayName,
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    '${entry.xp} XP',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  tileColor: isMe
                      ? Colors.deepPurple.withValues(alpha: 0.05)
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdaptiveDashboard extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final List<Folder> rootFolders;
  final int xp, streak;
  final List<int> xpHistory;
  final Function(int) onXpGain;
  final List<Map<String, dynamic>> programs;

  const AdaptiveDashboard({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.rootFolders,
    required this.xp,
    required this.streak,
    required this.xpHistory,
    required this.onXpGain,
    required this.programs,
  }) : super(key: key);

  @override
  State<AdaptiveDashboard> createState() => _AdaptiveDashboardState();
}

class _AdaptiveDashboardState extends State<AdaptiveDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Cette liste utilise TES vrais écrans déjà présents dans tes 2000 lignes
    final List<Widget> screens = [
      HomeScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        rootFolders: widget.rootFolders,
        streak: widget.streak,
        onXpGain: widget.onXpGain,
        programs: widget.programs,
      ),
      StatsScreen(
        xp: widget.xp,
        streak: widget.streak,
        xpHistory: widget.xpHistory,
      ),
      SocialScreen(
        onFolderImported: (newFolder) {
          setState(() {
            AppData.folders.add(newFolder);
          });
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.05),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) =>
                      setState(() => _selectedIndex = index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(
                    color: Colors.deepPurple,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.style_outlined),
                      selectedIcon: Icon(Icons.style),
                      label: Text('Dossiers'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Stats'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.emoji_events_outlined),
                      selectedIcon: Icon(Icons.emoji_events),
                      label: Text('Classement'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: screens[_selectedIndex]),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: screens[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.deepPurple,
              type: BottomNavigationBarType.fixed,
              onTap: (int index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.style_outlined),
                  activeIcon: Icon(Icons.style),
                  label: 'Dossiers',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  activeIcon: Icon(Icons.bar_chart),
                  label: 'Stats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_outlined),
                  activeIcon: Icon(Icons.emoji_events),
                  label: 'Classement',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// --- ÉCRAN DE GESTION ET MODIFICATION DES CARTES ---
class ManageCardsScreen extends StatefulWidget {
  final Folder folder;
  const ManageCardsScreen({super.key, required this.folder});
  @override
  State<ManageCardsScreen> createState() => _ManageCardsScreenState();
}

class _ManageCardsScreenState extends State<ManageCardsScreen> {
  void _undoLastStroke(
    List<DrawingPoint?> pointsList,
    VoidCallback updateState,
  ) {
    if (pointsList.isEmpty) return;

    // Supprime le dernier élément null s'il y en a un à la fin
    if (pointsList.last == null) {
      pointsList.removeLast();
    }

    // Supprime tous les points du dernier trait jusqu'au précédent 'null'
    while (pointsList.isNotEmpty && pointsList.last != null) {
      pointsList.removeLast();
    }

    updateState();
  }

  void _editCardDialog(BuildContext context, Flashcard card) {
    final qController = TextEditingController(text: card.question);
    final rController = TextEditingController(text: card.response);
    bool isDrawMode = card.drawingPoints != null;
    List<DrawingPoint?> localDrawingPoints = card.drawingPoints != null
        ? List<DrawingPoint?>.from(card.drawingPoints!)
        : [];

    // Vérification du droit d'édition
    bool isReader = widget.folder.currentUserRole == ShareRole.reader;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isReader ? 'Détails de la carte' : 'Modifier la carte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qController,
                  decoration: const InputDecoration(labelText: 'Question'),
                  maxLines: 2,
                  enabled: !isReader, // Désactivé si lecteur seul
                ),
                const SizedBox(height: 12),
                if (!isDrawMode)
                  TextField(
                    controller: rController,
                    decoration: const InputDecoration(labelText: 'Réponse'),
                    maxLines: 2,
                    enabled: !isReader, // Désactivé si lecteur seul
                  )
                else ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isReader ? 'Schéma :' : 'Modifier le schéma :',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 200,
                    width: 340,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Builder(
                            builder: (editCtx) => GestureDetector(
                              onPanUpdate: isReader
                                  ? null
                                  : (details) {
                                      // Bloqué si lecteur seul
                                      setDialogState(() {
                                        RenderBox renderBox =
                                            editCtx.findRenderObject()
                                                as RenderBox;
                                        localDrawingPoints.add(
                                          DrawingPoint(
                                            offset: renderBox.globalToLocal(
                                              details.globalPosition,
                                            ),
                                            paint: Paint()
                                              ..color = Colors.white
                                              ..isAntiAlias = true
                                              ..strokeWidth = 3.0
                                              ..strokeCap = StrokeCap.round,
                                          ),
                                        );
                                      });
                                    },
                              onPanEnd: isReader
                                  ? null
                                  : (details) => setDialogState(
                                      () => localDrawingPoints.add(null),
                                    ),
                              child: CustomPaint(
                                painter: DrawingPainter(
                                  points: localDrawingPoints,
                                ),
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (!isReader) // Masque les contrôles d'effacement pour le lecteur seul
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.undo, color: Colors.orange),
                          label: const Text(
                            'Annuler trait',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: localDrawingPoints.isEmpty
                              ? null
                              : () => _undoLastStroke(
                                  localDrawingPoints,
                                  () => setDialogState(() {}),
                                ),
                        ),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Effacer tout',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                          onPressed: () =>
                              setDialogState(() => localDrawingPoints.clear()),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isReader ? 'Fermer' : 'Annuler'),
            ),
            if (!isReader) // Le bouton Sauvegarder apparaît uniquement pour les créateurs/éditeurs
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    card.question = qController.text;
                    if (isDrawMode) {
                      card.drawingPoints = localDrawingPoints.isNotEmpty
                          ? localDrawingPoints
                          : null;
                      card.response = '';
                    } else {
                      card.response = rController.text;
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Sauvegarder'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isReader = widget.folder.currentUserRole == ShareRole.reader;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des cartes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: widget.folder.cards.isEmpty
          ? const Center(
              child: Text('Aucune carte directement dans ce dossier.'),
            )
          : ListView.builder(
              itemCount: widget.folder.cards.length,
              itemBuilder: (ctx, idx) {
                final card = widget.folder.cards[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: ScientificText(
                      text: card.question,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (card.drawingPoints == null)
                          ScientificText(text: card.response),
                        if (card.imageUrl != null &&
                            card.imageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              card.imageUrl!,
                              height: 60,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ] else if (card.drawingPoints != null &&
                            card.drawingPoints!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              height: 60,
                              width: 100,
                              color: Colors.black,
                              child: CustomPaint(
                                painter: MiniDrawingPainter(
                                  card.drawingPoints!,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Si l'utilisateur est lecteur, l'icône devient un œil (visualisation) au lieu d'un crayon
                        IconButton(
                          icon: Icon(
                            isReader ? Icons.visibility : Icons.edit,
                            color: Colors.blue,
                          ),
                          onPressed: () => _editCardDialog(context, card),
                        ),
                        // Masquage complet du bouton supprimer pour le rôle Lecteur seul
                        if (!isReader)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(
                              () => widget.folder.cards.removeAt(idx),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class MiniDrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  MiniDrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Étape 1 : Dessiner le fond noir de la miniature
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Étape 2 : Trouver les limites du dessin original pour le recentrer
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (var p in points) {
      if (p != null) {
        if (p.offset.dx < minX) minX = p.offset.dx;
        if (p.offset.dx > maxX) maxX = p.offset.dx;
        if (p.offset.dy < minY) minY = p.offset.dy;
        if (p.offset.dy > maxY) maxY = p.offset.dy;
      }
    }

    if (minX == double.infinity) return;

    double drawingWidth = maxX - minX;
    double drawingHeight = maxY - minY;
    if (drawingWidth == 0) drawingWidth = 1;
    if (drawingHeight == 0) drawingHeight = 1;

    // Calcul du facteur d'échelle pour que ça rentre dans la miniature (avec une marge de 4px)
    double scaleX = (size.width - 8) / drawingWidth;
    double scaleY = (size.height - 8) / drawingHeight;
    double scale = scaleX < scaleY ? scaleX : scaleY;
    if (scale > 1.0) scale = 1.0; // Ne pas agrandir si c'est déjà petit

    // Centrage
    double offsetX = (size.width - (drawingWidth * scale)) / 2 - (minX * scale);
    double offsetY =
        (size.height - (drawingHeight * scale)) / 2 - (minY * scale);

    // Étape 3 : Dessiner les lignes mises à l'échelle
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        Paint paint = Paint()
          ..color = Colors.white
          ..isAntiAlias = true
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        Offset p1 = Offset(
          (points[i]!.offset.dx * scale) + offsetX,
          (points[i]!.offset.dy * scale) + offsetY,
        );
        Offset p2 = Offset(
          (points[i + 1]!.offset.dx * scale) + offsetX,
          (points[i + 1]!.offset.dy * scale) + offsetY,
        );
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ScientificText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const ScientificText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    if (text.contains('\$\$')) {
      List<String> parts = text.split('\$\$');
      List<Widget> textWidgets = [];

      for (int i = 0; i < parts.length; i++) {
        if (parts[i].trim().isEmpty) continue;

        if (i % 2 != 0) {
          String formula = parts[i];

          if (formula.contains('\\frac{')) {
            try {
              int numStart = formula.indexOf('\\frac{') + 6;
              int numEnd = formula.indexOf('}', numStart);
              String numerator = formula.substring(numStart, numEnd);

              int denStart = formula.indexOf('{', numEnd) + 1;
              int denEnd = formula.indexOf('}', denStart);
              String denominator = formula.substring(denStart, denEnd);

              textWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        numerator,
                        style: (style ?? const TextStyle()).copyWith(
                          fontSize: 15,
                          fontFamily: 'Times New Roman',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 20 + (numerator.length * 4),
                        height: 1.5,
                        color: style?.color ?? Colors.black,
                      ),
                      Text(
                        denominator,
                        style: (style ?? const TextStyle()).copyWith(
                          fontSize: 15,
                          fontFamily: 'Times New Roman',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              continue;
            } catch (_) {}
          }

          String cleanFormula = formula
              .replaceAll('\\int', '∫')
              .replaceAll('\\alpha', 'α')
              .replaceAll('\\beta', 'β')
              .replaceAll('\\gamma', 'γ')
              .replaceAll('\\Delta', 'Δ')
              .replaceAll('\\lambda', 'λ')
              .replaceAll('\\Omega', 'Ω');
          textWidgets.add(
            Text(
              cleanFormula,
              style: (style ?? const TextStyle()).copyWith(
                fontFamily: 'Times New Roman',
                fontStyle: FontStyle.italic,
                fontSize: 18,
                color: Colors.deepPurpleAccent,
              ),
            ),
          );
        } else {
          textWidgets.add(Text(parts[i], style: style));
        }
      }
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: textWidgets,
      );
    }

    return Text(text, textAlign: TextAlign.center, style: style);
  }
}

class ReviewScreen extends StatefulWidget {
  final Folder folder;
  final Function(int) onXpGain;
  const ReviewScreen({super.key, required this.folder, required this.onXpGain});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<Flashcard> _reviewQueue = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  double _dragHorizontalOffset = 0.0;
  bool _isFreeTrainingMode = false;
  bool _showCanvas = false;
  List<DrawingPoint?> _drawingPoints = [];

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    List<Flashcard> allCards = widget.folder.getAllCardsRecursive();
    final now = DateTime.now();
    _reviewQueue = allCards
        .where(
          (card) =>
              card.nextReviewDate.isBefore(now) ||
              DateUtils.isSameDay(card.nextReviewDate, now),
        )
        .toList();
    if (_reviewQueue.isEmpty) {
      _reviewQueue = List.from(allCards);
      _isFreeTrainingMode = true;
    } else {
      _isFreeTrainingMode = false;
    }
    _currentIndex = 0;
  }

  void _undoLastStroke() {
    if (_drawingPoints.isEmpty) return;
    setState(() {
      if (_drawingPoints.last == null) {
        _drawingPoints.removeLast();
      }
      while (_drawingPoints.isNotEmpty && _drawingPoints.last != null) {
        _drawingPoints.removeLast();
      }
    });
  }

  void _handleCardAction(bool isCorrect) {
    if (_reviewQueue.isEmpty || _currentIndex >= _reviewQueue.length) {
      Navigator.pop(context);
      return;
    }

    final card = _reviewQueue[_currentIndex];
    final now = DateTime.now();
    final profile = widget.folder.intervalProfile;

    setState(() {
      if (!isCorrect) {
        if (!card.isInUrgencyMode) {
          card.previousIntervalIndex = card.currentIntervalIndex;
          card.isInUrgencyMode = true;
        }
        card.urgencyStep = 0;
        card.currentIntervalIndex = 0;
        card.nextReviewDate = now.add(const Duration(days: 1));
      } else {
        if (card.isInUrgencyMode) {
          if (card.urgencyStep == 0) {
            card.urgencyStep = 1;
            card.nextReviewDate = now.add(const Duration(days: 2));
          } else if (card.urgencyStep == 1) {
            card.isInUrgencyMode = false;
            card.urgencyStep = 0;
            card.currentIntervalIndex = card.previousIntervalIndex;

            int daysToAdd =
                profile[card.currentIntervalIndex.clamp(0, profile.length - 1)];
            card.nextReviewDate = now.add(Duration(days: daysToAdd));
          }
        } else {
          if (card.currentIntervalIndex < profile.length - 1) {
            card.currentIntervalIndex++;
          }
          int daysToAdd = profile[card.currentIntervalIndex];
          card.nextReviewDate = now.add(Duration(days: daysToAdd));
        }
      }

      if (_currentIndex < _reviewQueue.length - 1) {
        _currentIndex++;
        _showAnswer = false;
        _dragHorizontalOffset = 0.0;
        _drawingPoints.clear();
      } else {
        widget.onXpGain(_isFreeTrainingMode ? 15 : 50);
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewQueue.isEmpty || _currentIndex >= _reviewQueue.length) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.folder.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isFreeTrainingMode
                      ? '💪 Entraînement fini !'
                      : '🎉 Session Validée !',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isFreeTrainingMode
                      ? 'Dossier révisé en mode libre.'
                      : 'Félicitations, +50 XP cumulés !',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentCard = _reviewQueue[_currentIndex];
    Color backdropColor = Colors.transparent;
    if (_dragHorizontalOffset > 20)
      backdropColor = Colors.green.withValues(
        alpha: (_dragHorizontalOffset / 200).clamp(0.0, 0.85),
      );
    else if (_dragHorizontalOffset < -20)
      backdropColor = Colors.red.withValues(
        alpha: (_dragHorizontalOffset.abs() / 200).clamp(0.0, 0.85),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.folder.title} (${_currentIndex + 1}/${_reviewQueue.length})',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCanvas ? Icons.gesture : Icons.border_color,
              color: _showCanvas ? Colors.orange : Colors.deepPurple,
            ),
            tooltip: 'Ardoise magique',
            onPressed: () => setState(() => _showCanvas = !_showCanvas),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: backdropColor)),
          Center(
            child: GestureDetector(
              onTap: () {
                if (!_showCanvas) setState(() => _showAnswer = !_showAnswer);
              },
              onHorizontalDragUpdate: (d) {
                if (!_showCanvas)
                  setState(() => _dragHorizontalOffset += d.delta.dx);
              },
              onHorizontalDragEnd: (d) {
                if (_showCanvas) return;
                if (_dragHorizontalOffset > 120)
                  _handleCardAction(true);
                else if (_dragHorizontalOffset < -120)
                  _handleCardAction(false);
                else
                  setState(() => _dragHorizontalOffset = 0.0);
              },
              child: Transform.translate(
                offset: Offset(_dragHorizontalOffset, 0),
                child: Transform.rotate(
                  angle: _dragHorizontalOffset / 1000,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    width: double.infinity,
                    height: 320,
                    decoration: BoxDecoration(
                      color: _showAnswer
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showAnswer ? 'RÉPONSE' : 'QUESTION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ScientificText(
                            text: _showAnswer
                                ? currentCard.response
                                : currentCard.question,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_showAnswer &&
                              currentCard.imageUrl != null &&
                              currentCard.imageUrl!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                // 🕵️ Clic sur l'image -> Ouvre le zoom plein écran sur fond noir
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog.fullscreen(
                                    backgroundColor: Colors.black,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: InteractiveViewer(
                                            maxScale: 4.0, // Zoom jusqu'à 4x
                                            child: Image.network(
                                              currentCard.imageUrl!,
                                              fit: BoxFit.contain,
                                              errorBuilder: (c, e, s) =>
                                                  const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 60,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                        // Bouton pour fermer le zoom en haut à droite
                                        Positioned(
                                          top: 40,
                                          right: 20,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    currentCard.imageUrl!,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ] else if (_showAnswer &&
                              currentCard.drawingPoints != null &&
                              currentCard.drawingPoints!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              height: 200, // Même taille que la zone d'édition
                              width: 340, // Même taille que la zone d'édition
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CustomPaint(
                                  painter: DrawingPainter(
                                    points: currentCard.drawingPoints!,
                                  ),
                                  size: const Size(340, 200),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_showCanvas)
            Positioned(
              bottom: 20,
              left: 24,
              right: 24,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Builder(
                        builder: (canvasContext) => GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              RenderBox renderBox =
                                  canvasContext.findRenderObject() as RenderBox;
                              Offset localPosition = renderBox.globalToLocal(
                                details.globalPosition,
                              );
                              _drawingPoints.add(
                                DrawingPoint(
                                  offset: localPosition,
                                  paint: Paint()
                                    ..color = Colors.white
                                    ..isAntiAlias = true
                                    ..strokeWidth = 4.0
                                    ..strokeCap = StrokeCap.round,
                                ),
                              );
                            });
                          },
                          onPanEnd: (details) =>
                              setState(() => _drawingPoints.add(null)),
                          child: CustomPaint(
                            painter: DrawingPainter(points: _drawingPoints),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo, color: Colors.orange),
                            tooltip: 'Annuler trait',
                            onPressed: _drawingPoints.isEmpty
                                ? null
                                : _undoLastStroke,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                setState(() => _drawingPoints.clear()),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                setState(() => _showCanvas = false),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      left: 12,
                      child: Text(
                        '🎨 Dessine ta formule au doigt !',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_showCanvas)
            Positioned(
              bottom: 260,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Faux'),
                    onPressed: () => _handleCardAction(false),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text('Vérifier'),
                    onPressed: () => setState(() => _showAnswer = !_showAnswer),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Correct'),
                    onPressed: () => _handleCardAction(true),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class EditCardScreen extends StatefulWidget {
  final Folder defaultFolder;
  final List<Folder> allFolders;

  const EditCardScreen({
    super.key,
    required this.defaultFolder,
    required this.allFolders,
  });

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  final _questionController = TextEditingController();
  final _responseController = TextEditingController();
  final _imageController = TextEditingController();
  late Folder _selectedFolder;
  bool _showGreekKeyboard = false;
  bool _drawOnCardMode = false;
  List<DrawingPoint?> _cardDrawingPoints = [];
  TextEditingController? _activeController;
  bool _showLowercase =
      true; // 🎯 Placé ici pour que l'état Min/Maj soit conservé au clic !

  @override
  void initState() {
    super.initState();
    _selectedFolder = widget.defaultFolder;
    _activeController = _questionController;
  }

  void _undoLastStroke() {
    if (_cardDrawingPoints.isEmpty) return;
    setState(() {
      if (_cardDrawingPoints.last == null) {
        _cardDrawingPoints.removeLast();
      }
      while (_cardDrawingPoints.isNotEmpty && _cardDrawingPoints.last != null) {
        _cardDrawingPoints.removeLast();
      }
    });
  }

  void _insertAtCursor(String code) {
    if (_activeController == null) return;

    final controller = _activeController!;
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      controller.text = text + code;
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final newText = text.replaceRange(start, end, code);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + code.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> greekLettersLowercase = [
      'α',
      'β',
      'γ',
      'δ',
      'ε',
      'ζ',
      'η',
      'θ',
      'ι',
      'κ',
      'λ',
      'μ',
      'ν',
      'ξ',
      'ο',
      'π',
      'ρ',
      'σ',
      'τ',
      'υ',
      'φ',
      'χ',
      'ψ',
      'ω',
    ];

    final List<String> greekLettersUppercase = [
      'A',
      'B',
      'Γ',
      'Δ',
      'E',
      'Z',
      'H',
      'Θ',
      'I',
      'K',
      'Λ',
      'M',
      'N',
      'Ξ',
      'O',
      'Π',
      'P',
      'Σ',
      'T',
      'Υ',
      'Φ',
      'X',
      'Ψ',
      'Ω',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Flashcard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_questionController.text.isNotEmpty &&
                  (_responseController.text.isNotEmpty ||
                      _cardDrawingPoints.isNotEmpty)) {
                _selectedFolder.cards.add(
                  Flashcard(
                    id: DateTime.now().toString(),
                    question: _questionController.text,
                    response: _responseController.text,
                    nextReviewDate: DateTime.now(),
                    imageUrl: _imageController.text.isNotEmpty
                        ? _imageController.text
                        : null,
                    drawingPoints: _cardDrawingPoints.isNotEmpty
                        ? List.from(_cardDrawingPoints)
                        : null,
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: const Text(
                      'Dossier cible actuel :',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      _selectedFolder.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.folder_shared,
                      size: 20,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _questionController,
                    onTap: () =>
                        setState(() => _activeController = _questionController),
                    decoration: const InputDecoration(
                      labelText: 'Question',
                      hintText: r'Tape ton texte ou tes $$maths$$',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  if (!_drawOnCardMode) ...[
                    TextField(
                      controller: _responseController,
                      onTap: () => setState(
                        () => _activeController = _responseController,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Réponse',
                        hintText: r'Utilise $$\frac{a}{b}$$ pour une fraction',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _imageController,
                      onTap: () =>
                          setState(() => _activeController = _imageController),
                      decoration: const InputDecoration(
                        labelText: 'URL d\'une image/schéma (Optionnel)',
                        hintText: 'https://exemple.com/schema.png',
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Dessine ton schéma/réponse ci-dessous :',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: SizedBox(
                        height: 200,
                        width: 340,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange, width: 2),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Builder(
                                builder: (editCanvasCtx) => GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      RenderBox renderBox =
                                          editCanvasCtx.findRenderObject()
                                              as RenderBox;
                                      _cardDrawingPoints.add(
                                        DrawingPoint(
                                          offset: renderBox.globalToLocal(
                                            details.globalPosition,
                                          ),
                                          paint: Paint()
                                            ..color = Colors.white
                                            ..isAntiAlias = true
                                            ..strokeWidth = 3.0
                                            ..strokeCap = StrokeCap.round,
                                        ),
                                      );
                                    });
                                  },
                                  onPanEnd: (details) => setState(
                                    () => _cardDrawingPoints.add(null),
                                  ),
                                  child: CustomPaint(
                                    painter: DrawingPainter(
                                      points: _cardDrawingPoints,
                                    ),
                                    size: Size(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const Text(
                    '👁️ Aperçu temps réel (Format Web LaTeX) :',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Q: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: ScientificText(
                                text: _questionController.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!_drawOnCardMode)
                          Row(
                            children: [
                              const Text(
                                'R: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: ScientificText(
                                  text: _responseController.text,
                                ),
                              ),
                            ],
                          )
                        else
                          const Row(
                            children: [
                              const Text(
                                'R: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '[Schéma dessiné à la main]',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton(
                  child: Text(
                    'αβ',
                    style: TextStyle(
                      fontSize: 18,
                      color: _showGreekKeyboard ? Colors.orange : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _showGreekKeyboard = !_showGreekKeyboard),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.horizontal_rule,
                    color: Colors.deepPurple,
                  ),
                  tooltip: 'Fraction LaTeX',
                  onPressed: () => _insertAtCursor(r'$$\frac{a}{b}$$'),
                ),
                IconButton(
                  icon: const Icon(Icons.functions, color: Colors.deepPurple),
                  tooltip: 'Intégrale LaTeX',
                  onPressed: () => _insertAtCursor(r'$$\int_{a}^{b}$$'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _drawOnCardMode = !_drawOnCardMode;
                    if (!_drawOnCardMode) _cardDrawingPoints.clear();
                  }),
                  icon: Icon(
                    _drawOnCardMode ? Icons.keyboard : Icons.brush,
                    size: 18,
                  ),
                  label: Text(
                    _drawOnCardMode ? 'Texte' : 'Dessiner Rép.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (_showGreekKeyboard)
            Container(
              height: 140, // Écran compact
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bouton MAJ/min compact
                  InkWell(
                    onTap: () =>
                        setState(() => _showLowercase = !_showLowercase),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 40,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            _showLowercase ? 'MAJ' : 'MIN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // La Grille ultra-compacte de 9 colonnes
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 9, // 9 touches par ligne
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                      childAspectRatio: 1.0,
                      children: [
                        for (var code
                            in (_showLowercase
                                ? greekLettersLowercase
                                : greekLettersUppercase))
                          InkWell(
                            onTap: () {
                              // Concaténation propre avec échappement explicite des symboles dollars
                              String textToInsert = (code.length == 1)
                                  ? '\$\$' + code + '\$\$'
                                  : code;
                              _insertAtCursor(textToInsert);
                              setState(() => _showGreekKeyboard = false);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  // 🟢 CORRIGÉ : Nettoyage simple et sécurisé avec un raw string global r'$$'
                                  code.replaceAll(r'$$', ''),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
