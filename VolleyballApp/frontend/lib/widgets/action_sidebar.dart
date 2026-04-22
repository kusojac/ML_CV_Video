import 'package:flutter/material.dart';
import '../models/action_model.dart';

class ActionSidebar extends StatefulWidget {
  final List<ActionModel> actions;
  final ActionModel? selectedAction;
  final bool isEditMode;
  final ValueChanged<bool> onEditModeChanged;
  final ValueChanged<ActionModel> onActionSelected;
  final ValueChanged<ActionModel> onActionUpdated;
  final String filterType;
  final String filterPlayer;
  final ValueChanged<String> onFilterTypeChanged;
  final ValueChanged<String> onFilterPlayerChanged;
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

  const ActionSidebar({
    super.key,
    required this.actions,
    required this.selectedAction,
    required this.isEditMode,
    required this.onEditModeChanged,
    required this.onActionSelected,
    required this.onActionUpdated,
    required this.filterType,
    required this.filterPlayer,
    required this.onFilterTypeChanged,
    required this.onFilterPlayerChanged,
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
  });

  @override
  State<ActionSidebar> createState() => _ActionSidebarState();
}

class _ActionSidebarState extends State<ActionSidebar> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  List<ActionModel> get _filteredActions {
    return widget.actions.where((a) {
      if (widget.filterType != 'All' && a.type != widget.filterType) return false;
      if (widget.filterPlayer != 'All' && a.playerId != widget.filterPlayer) return false;
      return true;
    }).toList();
  }

  @override
  void didUpdateWidget(ActionSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAction?.id != oldWidget.selectedAction?.id && widget.selectedAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final key = _itemKeys[widget.selectedAction!.id];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.3, // Przewija tak, by element był w 30% wysokości widoku
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
                  const Text('Actions List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Row(
                    children: [
                      const Text('Edit Mode', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                      const Text('Isolate Selected', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                initialValue: actionTypes.contains(widget.filterType) ? widget.filterType : 'All',
                dropdownColor: const Color(0xFF2E2E2E),
                decoration: const InputDecoration(
                  labelText: 'Filter by Action',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                items: ['All', ...actionTypes.toList()..sort()]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  widget.onFilterTypeChanged(v ?? 'All');
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: playerIds.contains(widget.filterPlayer) ? widget.filterPlayer : 'All',
                dropdownColor: const Color(0xFF2E2E2E),
                decoration: const InputDecoration(
                  labelText: 'Filter by Player #',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                items: ['All', ...playerIds.toList()..sort()]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  widget.onFilterPlayerChanged(v ?? 'All');
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
                      backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
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
                child: Column(
              children: filteredActions.map((action) {
                final isSelected = widget.selectedAction?.id == action.id;
                final key = _itemKeys.putIfAbsent(action.id, () => GlobalKey());
                
                Color accentColor = Colors.purpleAccent;
                if (action.type.toUpperCase() == 'BUMP') accentColor = const Color(0xFF00FFCC);
                if (action.type.toUpperCase() == 'SET') accentColor = Colors.greenAccent;
                if (action.type.toUpperCase().contains('SPIKE') || action.type.toUpperCase() == 'ATTACK') accentColor = const Color(0xFFFF0055);

                final timestamp = Duration(milliseconds: action.startMs.round()).toString().split('.').first;

                return Padding(
                  key: key,
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Card(
                    color: isSelected ? const Color(0xFF2A2A35) : const Color(0xFF1E1E24),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    elevation: isSelected ? 4 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? accentColor.withValues(alpha: 0.8) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => widget.onActionSelected(action),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (!widget.isEditMode && widget.playlist != null)
                              Checkbox(
                                value: widget.playlist!.any((a) => a.id == action.id),
                                activeColor: Colors.purpleAccent,
                                onChanged: (val) {
                                  if (val == true) {
                                    widget.onPlaylistChanged?.call([...widget.playlist!, action]);
                                  } else {
                                    widget.onPlaylistChanged?.call(
                                        widget.playlist!.where((a) => a.id != action.id).toList());
                                  }
                                },
                              ),
                            Container(
                              width: 4,
                              height: 36,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action.type.toUpperCase(),
                                style: TextStyle(color: isSelected ? accentColor : Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Player: ${action.playerId}',
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timestamp,
                              style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            if (widget.isEditMode)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _editAction(context, action),
                                      child: const Row(
                                        children: [
                                          Text('EDIT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                                          SizedBox(width: 4),
                                          Icon(Icons.edit, color: Colors.white30, size: 14),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () => widget.onActionDeleted?.call(action),
                                      child: const Row(
                                        children: [
                                          Text('DEL', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                          SizedBox(width: 4),
                                          Icon(Icons.delete, color: Colors.redAccent, size: 14),
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
                              onChanged: (v) => widget.onLoopPlaylistChanged?.call(v ?? false),
                            ),
                            const Text('Odtwarzaj w pętli', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: widget.onPlayPlaylistToggle,
                          icon: Icon(widget.isPlayingPlaylist == true ? Icons.stop : Icons.play_arrow),
                          label: Text(widget.isPlayingPlaylist == true ? 'Stop' : 'Play'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isPlayingPlaylist == true ? Colors.redAccent : Colors.greenAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!widget.isEditMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton<String>(
                          tooltip: 'Opcje zapisu playlisty',
                          icon: const Icon(Icons.save_alt, color: Colors.greenAccent, size: 20),
                          color: const Color(0xFF2A2A3E),
                          onSelected: (v) {
                            if (v == 'save') widget.onSavePlaylist?.call();
                            if (v == 'save_as') widget.onSavePlaylistAs?.call();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'save',
                              child: Row(children: [
                                Icon(Icons.save, color: Colors.greenAccent, size: 18),
                                SizedBox(width: 10),
                                Text('Zapisz obok wideo', style: TextStyle(color: Colors.white)),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'save_as',
                              child: Row(children: [
                                Icon(Icons.save_as, color: Colors.lightBlueAccent, size: 18),
                                SizedBox(width: 10),
                                Text('Zapisz jako...', style: TextStyle(color: Colors.white)),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.folder_open, color: Colors.amberAccent, size: 20),
                          tooltip: 'Wczytaj playlistę...',
                          onPressed: widget.onLoadPlaylist,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: widget.playlist?.length ?? 0,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final currentPlaylist = List<ActionModel>.from(widget.playlist ?? []);
                      final item = currentPlaylist.removeAt(oldIndex);
                      currentPlaylist.insert(newIndex, item);
                      widget.onPlaylistChanged?.call(currentPlaylist);
                    },
                    itemBuilder: (context, index) {
                      final action = widget.playlist![index];
                      Color accentColor = Colors.purpleAccent;
                      if (action.type.toUpperCase() == 'BUMP') accentColor = const Color(0xFF00FFCC);
                      if (action.type.toUpperCase() == 'SET') accentColor = Colors.greenAccent;
                      if (action.type.toUpperCase().contains('SPIKE') || action.type.toUpperCase() == 'ATTACK') accentColor = const Color(0xFFFF0055);
                      final isSelected = widget.selectedAction?.id == action.id;

                      return Card(
                        key: ValueKey(action.id + index.toString()),
                        color: isSelected ? const Color(0xFF2A2A35) : const Color(0xFF1E1E24),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          onTap: () => widget.onActionSelected(action),
                          leading: Icon(Icons.drag_handle, color: Colors.white30),
                          title: Text(action.type, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                          subtitle: Text('Player: ${action.playerId}', style: const TextStyle(color: Colors.white54)),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () {
                              final newPlaylist = List<ActionModel>.from(widget.playlist!);
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
          title: const Text('Edytuj typ akcji', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: kVolleyballActions.contains(typeController.text.toUpperCase()) 
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
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final newAction = ActionModel(
                  id: action.id,
                  type: typeController.text,
                  startMs: action.startMs,
                  endMs: action.endMs,
                  playerBox: action.playerBox,
                  playerId: action.playerId,
                  confidence: action.confidence,
                );
                widget.onActionUpdated(newAction);
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.purpleAccent)),
            ),
          ],
        );
      },
    );
  }
}
