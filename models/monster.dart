class Monster {
  final int id;
  final String name;

  // -- Estado Persistente (Salvo no futuro) --
  bool isSeen;
  bool isCaught;
  bool isCaughtShiny;

  // -- Estado Temporário (Apenas para a partida atual) --
  bool isShinyForThisRound;

  Monster({
    required this.id,
    required this.name,
    this.isSeen = false,
    this.isCaught = false,
    this.isCaughtShiny = false,
    this.isShinyForThisRound = false,
  });

  // Reseta o estado temporário antes de uma nova partida
  void resetRoundState() {
    isShinyForThisRound = false;
  }

  // Gera a URL direta da imagem (Normal ou Shiny)
  String get imageUrl {
    const baseUrl = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon";

    if (isShinyForThisRound) {
      return "$baseUrl/shiny/$id.png";
    } else {
      return "$baseUrl/$id.png";
    }
  }
}