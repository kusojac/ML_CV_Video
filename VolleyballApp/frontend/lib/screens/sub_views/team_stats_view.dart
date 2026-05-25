import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/artifact_model.dart';
import '../../models/action_model.dart';
import '../../services/project_data_service.dart';
import '../../theme/kinetic_theme.dart';

class TeamStatsView extends StatefulWidget {
  const TeamStatsView({super.key});

  @override
  State<TeamStatsView> createState() => _TeamStatsViewState();
}

class _TeamStatsViewState extends State<TeamStatsView> {
  final ProjectDataService _dataService = ProjectDataService();
  bool _loading = true;
  
  // Statystyki globalne
  final Map<String, int> _actionTypeCounts = {};
  final Map<String, Map<String, int>> _playerActionTypeCounts = {}; // playerId -> {type -> count}
  final Map<String, int> _playerTotalCounts = {}; // playerId -> total
  
  String? _selectedPlayerId;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final videos = _dataService.artifacts
          .where((a) => a.type == ArtifactType.video)
          .toList();

      for (var video in videos) {
        final path = video.filePath;
        final base = path.substring(0, path.lastIndexOf('.'));
        final analysisFile = File('${base}_analysis.json');
        
        if (analysisFile.existsSync()) {
          final content = await analysisFile.readAsString();
          final jsonResponse = jsonDecode(content);
          final actionsJson = jsonResponse['actions'] as List?;
          if (actionsJson != null) {
            for (var actJson in actionsJson) {
              final action = ActionModel.fromJson(actJson);
              final type = action.type.toUpperCase();
              final pId = action.playerId.isNotEmpty ? action.playerId : 'Nieznany';

              // 1. Zliczaj typ akcji globalnie
              _actionTypeCounts[type] = (_actionTypeCounts[type] ?? 0) + 1;

              // 2. Zliczaj akcje gracza
              _playerTotalCounts[pId] = (_playerTotalCounts[pId] ?? 0) + 1;

              if (!_playerActionTypeCounts.containsKey(pId)) {
                _playerActionTypeCounts[pId] = {};
              }
              _playerActionTypeCounts[pId]![type] = (_playerActionTypeCounts[pId]![type] ?? 0) + 1;

              // Zrób to samo dla sub-akcji
              for (var sub in action.subActions) {
                final subType = sub.type.toUpperCase();
                final subPid = sub.playerId.isNotEmpty ? sub.playerId : pId; // domyślnie rodzic

                _actionTypeCounts[subType] = (_actionTypeCounts[subType] ?? 0) + 1;
                _playerTotalCounts[subPid] = (_playerTotalCounts[subPid] ?? 0) + 1;
                
                if (!_playerActionTypeCounts.containsKey(subPid)) {
                  _playerActionTypeCounts[subPid] = {};
                }
                _playerActionTypeCounts[subPid]![subType] = (_playerActionTypeCounts[subPid]![subType] ?? 0) + 1;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Błąd ładowania statystyk: $e');
    }

    if (mounted) {
      setState(() {
        _loading = false;
        // Wybierz pierwszego gracza domyślnie, jeśli lista nie jest pusta
        final sortedPlayers = _playerTotalCounts.keys.toList()
          ..sort((a, b) => (_playerTotalCounts[b] ?? 0).compareTo(_playerTotalCounts[a] ?? 0));
        if (sortedPlayers.isNotEmpty) {
          _selectedPlayerId = sortedPlayers.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: KineticTheme.secondary),
      );
    }

    final totalActions = _actionTypeCounts.values.fold(0, (sum, val) => sum + val);

    final sortedPlayers = _playerTotalCounts.keys.toList()
      ..sort((a, b) => (_playerTotalCounts[b] ?? 0).compareTo(_playerTotalCounts[a] ?? 0));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statystyki zespołowe',
            style: KineticTheme.getDisplayFont(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: KineticTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zbiorcze zestawienie efektywności i wystąpień akcji taktycznych na podstawie wszystkich przeanalizowanych klipów wideo.',
            style: KineticTheme.getDisplayFont(
              fontSize: 16,
              color: KineticTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          if (totalActions == 0)
            _buildEmptyState()
          else
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lewa strona: Ogólny rozkład akcji (Wykresy słupkowe)
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: KineticTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: KineticTheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rozkład akcji (Suma: $totalActions)',
                            style: KineticTheme.getDisplayFont(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: KineticTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: ListView(
                              children: _actionTypeCounts.entries.map((entry) {
                                final pct = totalActions > 0 ? entry.value / totalActions : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20.0),
                                  child: _buildProgressBar(
                                    label: entry.key,
                                    value: entry.value,
                                    percent: pct,
                                    color: _colorForType(entry.key),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  
                  // Prawa strona: Statystyki graczy
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analiza indywidualna zawodników',
                          style: KineticTheme.getDisplayFont(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: KineticTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Lista zawodników
                              Expanded(
                                flex: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: KineticTheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: KineticTheme.outlineVariant),
                                  ),
                                  child: ListView.separated(
                                    itemCount: sortedPlayers.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1, color: KineticTheme.outlineVariant),
                                    itemBuilder: (context, index) {
                                      final pId = sortedPlayers[index];
                                      final total = _playerTotalCounts[pId] ?? 0;
                                      final isSelected = pId == _selectedPlayerId;
                                      return ListTile(
                                        dense: true,
                                        selected: isSelected,
                                        selectedColor: KineticTheme.primary,
                                        title: Text(
                                          pId,
                                          style: KineticTheme.getDisplayFont(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? KineticTheme.primary : KineticTheme.onSurface,
                                          ),
                                        ),
                                        trailing: Text(
                                          '$total akcji',
                                          style: KineticTheme.getMonoFont(
                                            color: isSelected ? KineticTheme.primary : KineticTheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedPlayerId = pId;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Szczegóły wybranego zawodnika
                              Expanded(
                                flex: 6,
                                child: _selectedPlayerId == null
                                    ? const SizedBox.shrink()
                                    : Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: KineticTheme.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: KineticTheme.outlineVariant),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ZAWODNIK: $_selectedPlayerId',
                                              style: KineticTheme.getMonoFont(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: KineticTheme.secondary,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Wykonane akcje: ${_playerTotalCounts[_selectedPlayerId] ?? 0}',
                                              style: KineticTheme.getDisplayFont(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: KineticTheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Expanded(
                                              child: ListView(
                                                children: (_playerActionTypeCounts[_selectedPlayerId!] ?? {})
                                                    .entries
                                                    .map((entry) {
                                                  final pTotal = _playerTotalCounts[_selectedPlayerId] ?? 1;
                                                  final pct = entry.value / pTotal;
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 14.0),
                                                    child: _buildPlayerBar(
                                                      label: entry.key,
                                                      value: entry.value,
                                                      percent: pct,
                                                      color: _colorForType(entry.key),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
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
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, color: KineticTheme.onSurfaceVariant.withAlpha(50), size: 80),
          const SizedBox(height: 16),
          Text(
            'Brak danych statystycznych',
            style: KineticTheme.getDisplayFont(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: KineticTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rozpocznij analizę wideo i oznacz akcje (np. Atak, Zagrywka), aby zapełnić ten ekran.',
            textAlign: TextAlign.center,
            style: KineticTheme.getDisplayFont(
              fontSize: 14,
              color: KineticTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'SERVE':
      case 'ZAGRYWKA':
        return KineticTheme.primary;
      case 'ATTACK':
      case 'ATAK':
        return KineticTheme.primaryContainer;
      case 'BLOCK':
      case 'BLOK':
        return KineticTheme.secondary;
      case 'DIG':
      case 'OBRONA':
        return KineticTheme.secondaryContainer;
      case 'SET':
      case 'ROZGRANIE':
        return const Color(0xFF00C853);
      case 'BUMP':
      case 'PRZYJĘCIE':
        return const Color(0xFFFFAB00);
      default:
        return KineticTheme.outline;
    }
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: KineticTheme.getMonoFont(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: KineticTheme.onSurface,
              ),
            ),
            Text(
              '$value (${(percent * 100).toStringAsFixed(1)}%)',
              style: KineticTheme.getMonoFont(
                fontSize: 12,
                color: KineticTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 12,
            backgroundColor: KineticTheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerBar({
    required String label,
    required int value,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: KineticTheme.getMonoFont(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: KineticTheme.onSurface,
              ),
            ),
            Text(
              '$value (${(percent * 100).round()}%)',
              style: KineticTheme.getMonoFont(
                fontSize: 11,
                color: KineticTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: KineticTheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
