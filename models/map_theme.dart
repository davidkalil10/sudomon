import 'package:flutter/material.dart';

class MapTheme {
  final String id;
  final String name;
  final String backgroundAsset; // A textura base (Zona Segura)
  final List<String> zoneVariations; // As texturas das outras zonas
  final String obstacleAsset; // O que é a "pedra" neste bioma? (Árvore, Rocha, Cristal)
  final Color fallbackColor; // Cor de segurança caso a imagem não carregue

  const MapTheme({
    required this.id,
    required this.name,
    required this.backgroundAsset,
    required this.zoneVariations,
    required this.obstacleAsset,
    this.fallbackColor = Colors.grey,
  });

  // Método inteligente para pegar a textura baseada no ID da zona
  String getAssetForZone(int zoneId) {
    // Zona 0 (geralmente onde o player começa visualmente)
    // Mas lembre-se: no seu gerador, as cores já estão embaralhadas!
    // Então aqui só mapeamos: ID 0 -> Asset X, ID 1 -> Asset Y.

    if (zoneId == 0) return backgroundAsset;

    // Usa matemática (módulo) para nunca estourar a lista,
    // mesmo se tivermos 10 zonas e só 3 texturas.
    int index = (zoneId - 1) % zoneVariations.length;
    return zoneVariations[index];
  }
}

// --- LISTA DE BIOMAS DO JOGO ---
class AppThemes {
  static const List<MapTheme> all = [
    // TEMA 1: FLORESTA (Clássico)
    MapTheme(
      id: 'forest',
      name: 'Floresta Viridian',
      backgroundAsset: 'assets/tiles/grass_light.png', // Grama Clara
      zoneVariations: [
        'assets/tiles/grass_dark.png',    // Grama Escura
        'assets/tiles/grass_flowers.png', // Grama com Flores
        'assets/tiles/dirt.png',          // Terra
        'assets/tiles/sand.png',          // Areia
      ],
      obstacleAsset: 'assets/tiles/bush.png', // Arbusto
      fallbackColor: Color(0xFFC8E6C9), // Verde claro
    ),

    // TEMA 2: CAVERNA (Mt. Moon)
    MapTheme(
      id: 'cave',
      name: 'Caverna Escura',
      backgroundAsset: 'assets/tiles/rock_floor.png',
      zoneVariations: [
        'assets/tiles/rock_floor_cracked.png',
        'assets/tiles/dirt_dark.png',
        'assets/tiles/mud.png',
        'assets/tiles/gravel.png',
      ],
      obstacleAsset: 'assets/tiles/rock.png', // Pedra
      fallbackColor: Color(0xFFCFD8DC), // Cinza
    ),

    // TEMA 3: GELO (Seafoam Islands)
    MapTheme(
      id: 'ice',
      name: 'Ilhas Seafoam',
      backgroundAsset: 'assets/tiles/ice.png',
      zoneVariations: [
        'assets/tiles/ice_cracked.png',
        'assets/tiles/snow.png',
        'assets/tiles/water.png',
        'assets/tiles/ice_dark.png',
      ],
      obstacleAsset: 'assets/tiles/crystal.png', // Cristal de Gelo
      fallbackColor: Color(0xFFE1F5FE), // Azul gelo
    ),
  ];

  // Sorteia um tema aleatório
  static MapTheme get random => all[DateTime.now().microsecond % all.length];
}