import 'package:flutter/material.dart';
import '../models/action_model.dart';
import '../models/artifact_model.dart';

class ActionSidebar extends StatefulWidget {
  final Duration? currentPosition;
  final List<ActionModel> actions;
  final ActionModel? selectedAction;
  final bool isEditMode;
  final ValueChanged<bool> onEditModeChanged;
  final ValueChanged<ActionModel> onActionSelected;
  final ValueChanged<ActionModel> onActionUpdated;
  final List<String> selectedActionTypes;
  final List<String> selectedPlayers;
  final ValueChanged<List<String>> onSelectedActionTypesChanged;
  final ValueChanged<List<String>> onSelectedPlayersChanged;
  final bool isolateSelected;
  final ValueChanged<bool> onIsolateSelectedChanged;

  final List<ActionModel>? playlist;
  final bool? isPlayingPlaylist;
  final bool? loopPlaylist;
  final ValueChanged<List<ActionModel>>? onPlaylistChanged;
  final ValueChanged<bool>? onLoopPlaylistChanged;
  final VoidCallback? onPlayPlaylistToggle;
  final VoidCallback? onSavePlaylist;
  final VoidCallback? onSavePlaylistAs;
  final VoidCallback? onLoadPlaylist;
  final ValueChanged<ActionModel>? onActionDeleted;
  final VoidCallback? onActionAdded;
  final int initialTabIndex;

  final List<ArtifactModel>? availablePlaylists;
  final String? currentPlaylistId;
  final ValueChanged<String>? onPlaylistSelected;
  final ValueChanged<String>? onCreateNewPlaylist;

  const ActionSidebar({
    super.key,
    this.currentPosition,
    required this.actions,
    required this.selectedAction,
    required this.isEditMode,
    required this.onEditModeChanged,
    required this.onActionSelected,
    required this.onActionUpdated,
    required this.selectedActionTypes,
    required this.selectedPlayers,
    required this.onSelectedActionTypesChanged,
    required this.onSelectedPlayersChanged,
    required this.isolateSelected,
    required this.onIsolateSelectedChanged,
    this.playlist,
    this.isPlayingPlaylist,
    this.loopPlaylist,
    this.onPlaylistChanged,
    this.onLoopPlaylistChanged,
    this.onPlayPlaylistToggle,
    this.onSavePlaylist,
    this.onSavePlaylistAs,
    this.onLoadPlaylist,
    this.onActionDeleted,
    this.onActionAdded,
    this.initialTabIndex = 0,
    this.availablePlaylists,
    this.currentPlaylistId,
    this.onPlaylistSelected,
    this.onCreateNewPlaylist,
  });

  @override
  State<ActionSidebar> createState() => _ActionSidebarState();
}

class _ActionSidebarState extends State<ActionSidebar> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};
  final String _sortOption = 'time_asc';
  String _filterType = 'All';
  String _filterPlayer = 'All';

  List<ActionModel> get _filteredActions {
    final filtered = widget.actions.where((a) {
      if (_filterType != 'All' && a.type != _filterType) {
        return false;
      }
      if (_filterPlayer != 'All' && a.playerId != _filterPlayer) {
        return false;
      }
      return true;
    }).toList();

    if (_sortOption == 'time_asc') {
      filtered.sort((a, b) => a.startMs.compareTo(b.startMs));
    } else if (_sortOption == 'time_desc') {
      filtered.sort((a, b) => b.startMs.compareTo(a.startMs));
    } else if (_sortOption == 'type') {
      filtered.sort((a, b) {
        int comp = a.type.compareTo(b.type);
        if (comp == 0) return a.startMs.compareTo(b.startMs);
        return comp;
      });
    } else if (_sortOption == 'player') {
      filtered.sort((a, b) {
        int comp = a.playerId.compareTo(b.playerId);
        if (comp == 0) return a.startMs.compareTo(b.startMs);
        return comp;
      });
    } else if (_sortOption == 'confidence') {
      filtered.sort((a, b) {
        int comp = b.confidence.compareTo(a.confidence); // malejąco
        if (comp == 0) return a.startMs.compareTo(b.startMs);
        return comp;
      });
    }

    return filtered;
  }

  @override
  void didUpdateWidget(ActionSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAction?.id != oldWidget.selectedAction?.id &&
        widget.selectedAction != null) {
      ActionModel? matchingParent;
      for (final a in widget.actions) {
        if (a.id == widget.selectedAction!.id) {
          matchingParent = a;
          break;
        }
        if (a.subActions.any((s) => s.id == widget.selectedAction!.id)) {
          matchingParent = a;
          break;
        }
      }

      if (matchingParent != null) {
        _filterType = matchingParent.type;
        if (_filterPlayer != 'All' &&
            matchingParent.playerId != _filterPlayer) {
          _filterPlayer = 'All';
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final key = _itemKeys[widget.selectedAction!.id];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment:
                0.3, // Przewija tak, by element był w 30% wysokości widoku
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Set<String> actionTypes = widget.actions.map((e) => e.type).toSet();
    Set<String> playerIds = widget.actions.map((e) => e.playerId).toSet();

    List<ActionModel> filteredActions = _filteredActions;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF161616),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Actions List',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Edit',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Switch(
                          value: widget.isEditMode,
                          onChanged: widget.onEditModeChanged,
                          activeThumbColor: Colors.purpleAccent,
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.isEditMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Isolate Selected',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Switch(
                          value: widget.isolateSelected,
                          onChanged: widget.onIsolateSelectedChanged,
                          activeThumbColor: Colors.cyanAccent,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: actionTypes.contains(_filterType)
                      ? _filterType
                      : 'All',
                  dropdownColor: const Color(0xFF2E2E2E),
                  decoration: const InputDecoration(
                    labelText: 'Filter by Action',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: ['All', ...actionTypes.toList()..sort()]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _filterType = v ?? 'All';
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: playerIds.contains(_filterPlayer)
                      ? _filterPlayer
                      : 'All',
                  dropdownColor: const Color(0xFF2E2E2E),
                  decoration: const InputDecoration(
                    labelText: 'Filter by Player #',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: ['All', ...playerIds.toList()..sort()]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _filterPlayer = v ?? 'All';
                    });
                  },
                ),
                if (widget.isEditMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ElevatedButton.icon(
                      onPressed: widget.onActionAdded,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Dodaj nową akcję'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent.withValues(
                          alpha: 0.2,
                        ),
                        foregroundColor: Colors.purpleAccent,
                        side: const BorderSide(color: Colors.purpleAccent),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const TabBar(
                  indicatorColor: Colors.purpleAccent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    Tab(text: 'Wszystkie'),
                    Tab(text: 'Playlista'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // ── ZAKŁADKA 1: Wszystkie akcje ──
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  child: filteredActions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.white30,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Brak akcji',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Zmień filtry lub dodaj nowe akcje.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: filteredActions.map((action) {
                            final isSelected =
                                widget.selectedAction?.id == action.id;
                            final key = _itemKeys.putIfAbsent(
                              action.id,
                              () => GlobalKey(),
                            );

                            Color accentColor = Colors.purpleAccent;
                            if (action.type.toUpperCase() == 'BUMP') {
                              accentColor = const Color(0xFF00FFCC);
                            }
                            if (action.type.toUpperCase() == 'SET') {
                              accentColor = Colors.greenAccent;
                            }
                            if (action.type.toUpperCase().contains('SPIKE') ||
                                action.type.toUpperCase() == 'ATTACK') {
                              accentColor = const Color(0xFFFF0055);
                            }

                            final timestamp = Duration(
                              milliseconds: action.startMs.round(),
                            ).toString().split('.').first;

                            return Padding(
                              key: key,
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Card(
                                color: isSelected
                                    ? const Color(0xFF2A2A35)
                                    : const Color(0xFF1E1E24),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                                elevation: isSelected ? 4 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? accentColor.withValues(alpha: 0.8)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => widget.onActionSelected(action),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (!widget.isEditMode &&
                                                widget.playlist != null)
                                              Checkbox(
                                                value: widget.playlist!.any(
                                                  (a) => a.id == action.id,
                                                ),
                                                activeColor:
                                                    Colors.purpleAccent,
                                                onChanged: (val) {
                                                  if (val == true) {
                                                    widget.onPlaylistChanged
                                                        ?.call([
                                                          ...widget.playlist!,
                                                          action,
                                                        ]);
                                                  } else {
                                                    widget.onPlaylistChanged
                                                        ?.call(
                                                          widget.playlist!
                                                              .where(
                                                                (a) =>
                                                                    a.id !=
                                                                    action.id,
                                                              )
                                                              .toList(),
                                                        );
                                                  }
                                                },
                                              ),
                                            Container(
                                              width: 4,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: accentColor,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    action.type.toUpperCase(),
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? accentColor
                                                          : Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      letterSpacing: 1.1,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Player: ${action.playerId}',
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  timestamp,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (widget.isEditMode)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        InkWell(
                                                          onTap: () =>
                                                              _editAction(
                                                                context,
                                                                action,
                                                              ),
                                                          child: const Row(
                                                            children: [
                                                              Text(
                                                                'EDIT',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white30,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 4,
                                                              ),
                                                              Icon(
                                                                Icons.edit,
                                                                color: Colors
                                                                    .white30,
                                                                size: 14,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        InkWell(
                                                          onTap: () async {
                                                            final bool?
                                                            confirm = await showDialog<bool>(
                                                              context: context,
                                                              builder: (context) => AlertDialog(
                                                                backgroundColor:
                                                                    const Color(
                                                                      0xFF1E1E24,
                                                                    ),
                                                                title: const Text(
                                                                  'Usuń akcję',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                                content: const Text(
                                                                  'Czy na pewno chcesz usunąć tę akcję?',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                          context,
                                                                          false,
                                                                        ),
                                                                    child: const Text(
                                                                      'Anuluj',
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .white54,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                          context,
                                                                          true,
                                                                        ),
                                                                    child: const Text(
                                                                      'Usuń',
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .redAccent,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            if (confirm ==
                                                                true) {
                                                              widget
                                                                  .onActionDeleted
                                                                  ?.call(
                                                                    action,
                                                                  );
                                                            }
                                                          },
                                                          child: const Row(
                                                            children: [
                                                              Text(
                                                                'DEL',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .redAccent,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 4,
                                                              ),
                                                              Icon(
                                                                Icons.delete,
                                                                color: Colors
                                                                    .redAccent,
                                                                size: 14,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        _buildSubActionsList(context, action),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                // ── ZAKŁADKA 2: Playlista ──
                Column(
                  children: [
                    if (widget.availablePlaylists != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue:
                                    widget.availablePlaylists!.any(
                                      (p) => p.id == widget.currentPlaylistId,
                                    )
                                    ? widget.currentPlaylistId
                                    : null,
                                dropdownColor: const Color(0xFF2E2E2E),
                                decoration: const InputDecoration(
                                  labelText: 'Aktywna playlista',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 0,
                                  ),
                                  labelStyle: TextStyle(color: Colors.white70),
                                ),
                                style: const TextStyle(color: Colors.white),
                                items: widget.availablePlaylists!
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p.id,
                                        child: Text(
                                          p.title,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    widget.onPlaylistSelected?.call(v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.playlist_add,
                                color: Colors.purpleAccent,
                              ),
                              tooltip: 'Nowa playlista...',
                              onPressed: () =>
                                  _showCreatePlaylistDialog(context),
                            ),
                          ],
                        ),
                      ),
                    if (!widget.isEditMode)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: widget.loopPlaylist ?? false,
                                  activeColor: Colors.purpleAccent,
                                  onChanged: (v) => widget.onLoopPlaylistChanged
                                      ?.call(v ?? false),
                                ),
                                const Text(
                                  'Odtwarzaj w pętli',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: widget.onPlayPlaylistToggle,
                              icon: Icon(
                                widget.isPlayingPlaylist == true
                                    ? Icons.stop
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                widget.isPlayingPlaylist == true
                                    ? 'Stop'
                                    : 'Play',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    widget.isPlayingPlaylist == true
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!widget.isEditMode)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PopupMenuButton<String>(
                              tooltip: 'Opcje zapisu playlisty',
                              icon: const Icon(
                                Icons.save_alt,
                                color: Colors.greenAccent,
                                size: 20,
                              ),
                              color: const Color(0xFF2A2A3E),
                              onSelected: (v) {
                                if (v == 'save') {
                                  widget.onSavePlaylist?.call();
                                }
                                if (v == 'save_as') {
                                  widget.onSavePlaylistAs?.call();
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'save',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.save,
                                        color: Colors.greenAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Zapisz obok wideo',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'save_as',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.save_as,
                                        color: Colors.lightBlueAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Zapisz jako...',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.folder_open,
                                color: Colors.amberAccent,
                                size: 20,
                              ),
                              tooltip: 'Wczytaj playlistę...',
                              onPressed: widget.onLoadPlaylist,
                            ),
                          ],
                        ),
                      ),
                    if ((widget.playlist?.length ?? 0) == 0)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.playlist_play,
                                size: 48,
                                color: Colors.white30,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Pusta playlista',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Zaznacz akcje z zakładki "Wszystkie"\nlub wczytaj zapisaną playlistę.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ReorderableListView.builder(
                          itemCount: widget.playlist?.length ?? 0,
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex < newIndex) newIndex -= 1;
                            final currentPlaylist = List<ActionModel>.from(
                              widget.playlist ?? [],
                            );
                            final item = currentPlaylist.removeAt(oldIndex);
                            currentPlaylist.insert(newIndex, item);
                            widget.onPlaylistChanged?.call(currentPlaylist);
                          },
                          itemBuilder: (context, index) {
                            final action = widget.playlist![index];
                            Color accentColor = Colors.purpleAccent;
                            if (action.type.toUpperCase() == 'BUMP') {
                              accentColor = const Color(0xFF00FFCC);
                            }
                            if (action.type.toUpperCase() == 'SET') {
                              accentColor = Colors.greenAccent;
                            }
                            if (action.type.toUpperCase().contains('SPIKE') ||
                                action.type.toUpperCase() == 'ATTACK') {
                              accentColor = const Color(0xFFFF0055);
                            }
                            final isSelected =
                                widget.selectedAction?.id == action.id;

                            return Card(
                              key: ValueKey(action.id + index.toString()),
                              color: isSelected
                                  ? const Color(0xFF2A2A35)
                                  : const Color(0xFF1E1E24),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ListTile(
                                onTap: () => widget.onActionSelected(action),
                                leading: Icon(
                                  Icons.drag_handle,
                                  color: Colors.white30,
                                ),
                                title: Text(
                                  action.type,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Player: ${action.playerId}',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip:
                                      'Usuń z playlisty / Remove from playlist',
                                  onPressed: () {
                                    final newPlaylist = List<ActionModel>.from(
                                      widget.playlist!,
                                    );
                                    newPlaylist.removeAt(index);
                                    widget.onPlaylistChanged?.call(newPlaylist);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.selectedAction != null)
            _buildFocusManagementPanel(context, widget.selectedAction!),
        ],
      ),
    );
  }

  void _editAction(BuildContext context, ActionModel action) {
    final typeController = TextEditingController(text: action.type);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Edytuj typ akcji',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue:
                    kVolleyballActions.contains(
                      typeController.text.toUpperCase(),
                    )
                    ? typeController.text.toUpperCase()
                    : kVolleyballActions.first,
                dropdownColor: const Color(0xFF3A3A3A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Typ akcji',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                items: kVolleyballActions.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    typeController.text = newValue;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                final newAction = action.copyWith(
                  type: typeController.text,
                );
                widget.onActionUpdated(newAction);
                Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.purpleAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubActionsList(BuildContext context, ActionModel parentAction) {
    if (parentAction.subActions.isEmpty) {
      if (widget.isEditMode) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 16.0),
          child: InkWell(
            onTap: () => _showAddSubActionDialog(context, parentAction),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 14,
                  color: Colors.blueAccent,
                ),
                SizedBox(width: 4),
                Text(
                  'Dodaj pod-akcję',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white12, height: 16),
        ...parentAction.subActions.map((sub) {
          Color subColor = Colors.grey;
          if (sub.type.toUpperCase() == 'SERVE' ||
              sub.type.toUpperCase().contains('SERVE')) {
            subColor = Colors.orangeAccent;
          }
          if (sub.type.toUpperCase() == 'RECEIVE' ||
              sub.type.toUpperCase() == 'BUMP') {
            subColor = const Color(0xFF00FFCC);
          }
          if (sub.type.toUpperCase() == 'SET') {
            subColor = Colors.greenAccent;
          }
          if (sub.type.toUpperCase().contains('SPIKE') ||
              sub.type.toUpperCase() == 'ATTACK') {
            subColor = const Color(0xFFFF0055);
          }
          if (sub.type.toUpperCase() == 'BLOCK') {
            subColor = Colors.purpleAccent;
          }
          if (sub.type.toUpperCase() == 'DIG') {
            subColor = Colors.blueAccent;
          }

          final subTimestamp = Duration(
            milliseconds: sub.startMs.round(),
          ).toString().split('.').first;

          final isSubSelected = widget.selectedAction?.id == sub.id;

          return Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 6.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isSubSelected ? const Color(0xFF2A2438) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSubSelected ? Colors.purpleAccent.withValues(alpha: 0.4) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: subColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => widget.onActionSelected(sub),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.type.toUpperCase(),
                            style: TextStyle(
                              color: subColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Player: ${sub.playerId} • $subTimestamp',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white70),
                    tooltip: 'Odtwórz pod-akcję',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => widget.onActionSelected(sub),
                  ),
                  if (widget.isEditMode) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 14, color: Colors.white30),
                      tooltip: 'Edytuj pod-akcję',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditSubActionDialog(context, parentAction, sub),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 14, color: Colors.redAccent),
                      tooltip: 'Usuń pod-akcję',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _deleteSubAction(context, parentAction, sub),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        if (widget.isEditMode)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 16.0),
            child: InkWell(
              onTap: () => _showAddSubActionDialog(context, parentAction),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Colors.blueAccent),
                  SizedBox(width: 2),
                  Text(
                    'Dodaj pod-akcję',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showAddSubActionDialog(BuildContext context, ActionModel parent) {
    final parentStartSec = parent.startMs / 1000.0;
    final parentEndSec = parent.endMs / 1000.0;

    double initialStartSec = parentStartSec;
    if (widget.currentPosition != null) {
      final curPosSec = widget.currentPosition!.inMilliseconds / 1000.0;
      if (curPosSec >= parentStartSec && curPosSec <= parentEndSec) {
        initialStartSec = curPosSec;
      }
    }
    double initialEndSec = (initialStartSec + 2.0).clamp(
      parentStartSec,
      parentEndSec,
    );

    final typeController = TextEditingController(text: 'RECEIVE');
    final playerController = TextEditingController();
    final startController = TextEditingController(
      text: initialStartSec.toStringAsFixed(2),
    );
    final endController = TextEditingController(
      text: initialEndSec.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'Dodaj pod-akcję (${parent.type})',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Przedział rodzica: ${parentStartSec.toStringAsFixed(2)}s - ${parentEndSec.toStringAsFixed(2)}s',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: 'RECEIVE',
                  dropdownColor: const Color(0xFF3A3A3A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Typ pod-akcji',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  items: kVolleyballActions.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) typeController.text = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: playerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Numer/ID gracza',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Start (s)',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Koniec (s)',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Anuluj',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                final type = typeController.text;
                final player = playerController.text.trim().isEmpty
                    ? 'Unknown'
                    : playerController.text.trim();
                final startSec =
                    double.tryParse(startController.text) ?? initialStartSec;
                final endSec =
                    double.tryParse(endController.text) ?? initialEndSec;

                final subStartMs = (startSec * 1000.0).clamp(
                  parent.startMs,
                  parent.endMs,
                );
                final subEndMs = (endSec * 1000.0).clamp(
                  subStartMs,
                  parent.endMs,
                );

                final sub = ActionModel(
                  id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                  type: type,
                  startMs: subStartMs,
                  endMs: subEndMs,
                  playerBox: [0.0, 0.0, 0.0, 0.0],
                  playerId: player,
                  confidence: 1.0,
                );

                final newSubs = List<ActionModel>.from(parent.subActions)
                  ..add(sub);

                final updatedParent = parent.copyWith(
                  subActions: newSubs,
                );

                widget.onActionUpdated(updatedParent);
                Navigator.pop(context);
              },
              child: const Text(
                'Zapisz',
                style: TextStyle(color: Colors.purpleAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditSubActionDialog(
    BuildContext context,
    ActionModel parent,
    ActionModel sub,
  ) {
    final parentStartSec = parent.startMs / 1000.0;
    final parentEndSec = parent.endMs / 1000.0;

    final typeController = TextEditingController(text: sub.type);
    final playerController = TextEditingController(text: sub.playerId);
    final startController = TextEditingController(
      text: (sub.startMs / 1000.0).toStringAsFixed(2),
    );
    final endController = TextEditingController(
      text: (sub.endMs / 1000.0).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'Edytuj pod-akcję (${parent.type})',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Przedział rodzica: ${parentStartSec.toStringAsFixed(2)}s - ${parentEndSec.toStringAsFixed(2)}s',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      kVolleyballActions.contains(sub.type.toUpperCase())
                      ? sub.type.toUpperCase()
                      : kVolleyballActions.first,
                  dropdownColor: const Color(0xFF3A3A3A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Typ pod-akcji',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  items: kVolleyballActions.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) typeController.text = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: playerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Numer/ID gracza',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Start (s)',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Koniec (s)',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Anuluj',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                final type = typeController.text;
                final player = playerController.text.trim().isEmpty
                    ? 'Unknown'
                    : playerController.text.trim();
                final startSec =
                    double.tryParse(startController.text) ??
                    (sub.startMs / 1000.0);
                final endSec =
                    double.tryParse(endController.text) ?? (sub.endMs / 1000.0);

                final subStartMs = (startSec * 1000.0).clamp(
                  parent.startMs,
                  parent.endMs,
                );
                final subEndMs = (endSec * 1000.0).clamp(
                  subStartMs,
                  parent.endMs,
                );

                final updatedFocuses = sub.playerFocuses.map((f) {
                  if (f.id == sub.activeFocusId) {
                    return f.copyWith(playerId: player);
                  }
                  return f;
                }).toList();

                final updatedSub = sub.copyWith(
                  type: type,
                  startMs: subStartMs,
                  endMs: subEndMs,
                  playerId: player,
                  playerFocuses: updatedFocuses,
                );

                final newSubs = List<ActionModel>.from(parent.subActions);
                final idx = newSubs.indexWhere((s) => s.id == sub.id);
                if (idx != -1) {
                  newSubs[idx] = updatedSub;
                }

                final updatedParent = parent.copyWith(
                  subActions: newSubs,
                );

                widget.onActionUpdated(updatedParent);
                Navigator.pop(context);
              },
              child: const Text(
                'Zapisz',
                style: TextStyle(color: Colors.purpleAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteSubAction(
    BuildContext context,
    ActionModel parent,
    ActionModel sub,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: const Text(
            'Usuń pod-akcję',
            style: TextStyle(color: Colors.white),
          ),
          content: Text('Czy na pewno chcesz usunąć pod-akcję: ${sub.type}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Anuluj',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                final newSubs = List<ActionModel>.from(parent.subActions)
                  ..removeWhere((s) => s.id == sub.id);

                final updatedParent = parent.copyWith(
                  subActions: newSubs,
                );
                widget.onActionUpdated(updatedParent);
                Navigator.pop(context);
              },
              child: const Text(
                'Usuń',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Nowa playlista',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Nazwa playlisty',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.purpleAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Anuluj',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  widget.onCreateNewPlaylist?.call(nameController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Utwórz',
                style: TextStyle(color: Colors.purpleAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFocusManagementPanel(BuildContext context, ActionModel selectedAction) {
    // Find parent action if it's a sub-action
    ActionModel? parentAction;
    for (final a in widget.actions) {
      if (a.subActions.any((sub) => sub.id == selectedAction.id)) {
        parentAction = a;
        break;
      }
    }

    final isSubAction = parentAction != null;

    Color accentColor = Colors.purpleAccent;
    final typeUpper = selectedAction.type.toUpperCase();
    if (typeUpper == 'BUMP') {
      accentColor = const Color(0xFF00FFCC);
    } else if (typeUpper == 'SET') {
      accentColor = Colors.greenAccent;
    } else if (typeUpper.contains('SPIKE') || typeUpper == 'ATTACK') {
      accentColor = const Color(0xFFFF0055);
    }

    final timestamp = Duration(
      milliseconds: selectedAction.startMs.round(),
    ).toString().split('.').first;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        border: Border(
          top: BorderSide(
            color: Colors.purpleAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.center_focus_weak, size: 16, color: Colors.purpleAccent),
                  const SizedBox(width: 8),
                  Text(
                    isSubAction ? 'Śledzenie pod-akcji (PIP)' : 'Śledzenie akcji (PIP)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (widget.isEditMode)
                TextButton.icon(
                  onPressed: () => _addPlayerFocus(context, selectedAction, parentAction: parentAction),
                  icon: const Icon(Icons.add, size: 14, color: Colors.purpleAccent),
                  label: const Text(
                    'Dodaj',
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Badge showing action info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedAction.type.toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(width: 1, height: 10, color: Colors.white24),
                const SizedBox(width: 6),
                Text(
                  'Player: ${selectedAction.playerId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(width: 6),
                Container(width: 1, height: 10, color: Colors.white24),
                const SizedBox(width: 6),
                Text(
                  timestamp,
                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Focuses List with Max Height
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView(
              shrinkWrap: true,
              children: selectedAction.playerFocuses.map((focus) {
                final isActive = focus.id == selectedAction.activeFocusId;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF2A2438) : const Color(0xFF16161C),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive ? Colors.purpleAccent.withValues(alpha: 0.5) : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _updateActionFocuses(
                            selectedAction,
                            selectedAction.playerFocuses,
                            focus.id,
                            parentAction: parentAction,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive ? Colors.purpleAccent : Colors.white30,
                                width: 2,
                              ),
                            ),
                            child: isActive
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.purpleAccent,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            _updateActionFocuses(
                              selectedAction,
                              selectedAction.playerFocuses,
                              focus.id,
                              parentAction: parentAction,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  focus.name,
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.white70,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Gracz: ${focus.playerId}',
                                  style: TextStyle(
                                    color: isActive ? Colors.purpleAccent.withValues(alpha: 0.8) : Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.isEditMode) ...[
                        IconButton(
                          icon: const Icon(Icons.edit, size: 14, color: Colors.white30),
                          tooltip: 'Edytuj obszar śledzenia',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _editPlayerFocus(context, selectedAction, focus, parentAction: parentAction),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 14,
                            color: selectedAction.playerFocuses.length > 1
                                ? Colors.redAccent.withValues(alpha: 0.7)
                                : Colors.white12,
                          ),
                          tooltip: 'Usuń obszar śledzenia',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: selectedAction.playerFocuses.length > 1
                              ? () => _deletePlayerFocus(context, selectedAction, focus, parentAction: parentAction)
                              : null,
                        ),
                        const SizedBox(width: 12),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _updateActionFocuses(
    ActionModel action,
    List<PlayerFocusModel> focuses,
    String? activeFocusId, {
    ActionModel? parentAction,
  }) {
    final updatedAction = action.copyWith(
      playerFocuses: focuses,
      activeFocusId: activeFocusId,
    );

    if (parentAction != null) {
      final newSubs = parentAction.subActions.map((sub) {
        if (sub.id == action.id) {
          return updatedAction;
        }
        return sub;
      }).toList();
      final updatedParent = parentAction.copyWith(subActions: newSubs);
      widget.onActionUpdated(updatedParent);
    } else {
      widget.onActionUpdated(updatedAction);
    }
  }

  void _addPlayerFocus(
    BuildContext context,
    ActionModel action, {
    ActionModel? parentAction,
  }) {
    final nameController = TextEditingController(text: 'Focus ${action.playerFocuses.length + 1}');
    final playerController = TextEditingController(text: action.playerId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Dodaj obszar śledzenia', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Nazwa (np. Atak / Obrona)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: playerController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'ID Zawodnika',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final playerId = playerController.text.trim().isEmpty ? 'Unknown' : playerController.text.trim();
                if (name.isNotEmpty) {
                  final activeFocus = action.playerFocuses.firstWhere(
                    (f) => f.id == action.activeFocusId,
                    orElse: () => action.playerFocuses.first,
                  );
                  final newBox = List<double>.from(activeFocus.playerBox);

                  final newFocus = PlayerFocusModel(
                    id: 'focus_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    playerBox: newBox,
                    playerId: playerId,
                  );

                  final newFocuses = List<PlayerFocusModel>.from(action.playerFocuses)..add(newFocus);
                  _updateActionFocuses(
                    action,
                    newFocuses,
                    newFocus.id,
                    parentAction: parentAction,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Dodaj', style: TextStyle(color: Colors.purpleAccent)),
            ),
          ],
        );
      },
    );
  }

  void _editPlayerFocus(
    BuildContext context,
    ActionModel action,
    PlayerFocusModel focus, {
    ActionModel? parentAction,
  }) {
    final nameController = TextEditingController(text: focus.name);
    final playerController = TextEditingController(text: focus.playerId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Edytuj obszar śledzenia', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Nazwa',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: playerController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'ID Zawodnika',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final playerId = playerController.text.trim().isEmpty ? 'Unknown' : playerController.text.trim();
                if (name.isNotEmpty) {
                  final newFocuses = action.playerFocuses.map((f) {
                    if (f.id == focus.id) {
                      return f.copyWith(name: name, playerId: playerId);
                    }
                    return f;
                  }).toList();

                  _updateActionFocuses(
                    action,
                    newFocuses,
                    action.activeFocusId,
                    parentAction: parentAction,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Zapisz', style: TextStyle(color: Colors.purpleAccent)),
            ),
          ],
        );
      },
    );
  }

  void _deletePlayerFocus(
    BuildContext context,
    ActionModel action,
    PlayerFocusModel focus, {
    ActionModel? parentAction,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Usuń obszar śledzenia?', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Text(
            'Czy na pewno chcesz usunąć "${focus.name}"?',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final newFocuses = List<PlayerFocusModel>.from(action.playerFocuses)
                  ..removeWhere((f) => f.id == focus.id);

                String? newActiveId = action.activeFocusId;
                if (newActiveId == focus.id) {
                  newActiveId = newFocuses.isNotEmpty ? newFocuses.first.id : null;
                }

                _updateActionFocuses(
                  action,
                  newFocuses,
                  newActiveId,
                  parentAction: parentAction,
                );
                Navigator.pop(context);
              },
              child: const Text('Usuń', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
