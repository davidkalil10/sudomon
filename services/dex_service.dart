import 'dart:convert'; // Para decodificar o JSON
import 'dart:math';
import 'package:http/http.dart' as http; // Import do pacote HTTP
import '../models/monster.dart';

class DexService {
  static final DexService _instance = DexService._internal();
  factory DexService() => _instance;

  DexService._internal();

  final List<Monster> _allMonsters = [];
  final Random _random = Random();
  bool _isInitialized = false; // Controle para não carregar duas vezes

  // Configurações
  static const double shinyChance = 0.05;

  List<Monster> get allMonsters => List.unmodifiable(_allMonsters);
  bool get isInitialized => _isInitialized;

  // --- NOVO MÉTODO DE INICIALIZAÇÃO ---
  // Chamaremos isso na Splash Screen ou no main.dart
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final uri = Uri.parse("https://pokeapi.co/api/v2/pokemon?limit=151");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];

        // O 'results' é uma lista assim: [{name: "bulbasaur", url: "..."}, ...]
        // O índice + 1 é o ID (Kanto é perfeitamente ordenado de 1 a 151)

        for (int i = 0; i < results.length; i++) {
          final id = i + 1;
          final nameRaw = results[i]['name'].toString();

          // Formata o nome (API devolve "bulbasaur", queremos "Bulbasaur")
          final nameCapitalized = nameRaw[0].toUpperCase() + nameRaw.substring(1);

          _allMonsters.add(Monster(
            id: id,
            name: nameCapitalized,
          ));
        }

        _isInitialized = true;
        print("✅ Pokedex carregada com ${_allMonsters.length} monstros!");
      } else {
        throw Exception("Erro na API: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Erro ao carregar Pokedex: $e");
      // Fallback: Se der erro (sem internet), carrega genéricos para o app não travar
      _loadFallbackMonsters();
    }
  }

  void _loadFallbackMonsters() {
    if (_allMonsters.isNotEmpty) return;
    for (int i = 1; i <= 151; i++) {
      _allMonsters.add(Monster(id: i, name: "Monster #$i"));
    }
    _isInitialized = true;
  }

  // --- MÉTODOS DE GAMEPLAY (Mantidos Iguais) ---

  List<Monster> getMonstersForRound(int totalNeeded) {
    if (!_isInitialized) {
      // Segurança: se tentarem jogar antes de carregar, carrega o fallback na hora
      _loadFallbackMonsters();
    }

    // 1. Limpar estados da rodada anterior
    for (var m in _allMonsters) m.resetRoundState();

    // 2. Escolher o ALVO (Prioriza quem falta capturar)
    List<Monster> capturableCandidates = _allMonsters.where((m) {
      if (!m.isCaught) return true;
      if (!m.isCaughtShiny) return true;
      return false;
    }).toList();

    Monster target;
    if (capturableCandidates.isNotEmpty) {
      target = capturableCandidates[_random.nextInt(capturableCandidates.length)];
    } else {
      target = _allMonsters[_random.nextInt(_allMonsters.length)];
    }

    // 3. Shiny Chance
    if (_random.nextDouble() < shinyChance) {
      target.isShinyForThisRound = true;
    }

    // 4. Escolher Distrações
    List<Monster> pool = List.from(_allMonsters)..remove(target);
    pool.shuffle(_random);

    List<Monster> enemies = pool.take(totalNeeded - 1).toList();

    for (var enemy in enemies) {
      if (_random.nextDouble() < shinyChance) {
        enemy.isShinyForThisRound = true;
      }
    }

    return [target, ...enemies];
  }

  // Métodos de registro continuam iguais...
  void registerCapture(Monster monster) {
    monster.isCaught = true;
    if (monster.isShinyForThisRound) monster.isCaughtShiny = true;
  }
}