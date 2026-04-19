import 'package:flutter/material.dart';
import '../models/action_model.dart';

class ActionSidebar extends StatefulWidget {
  final List<ActionModel> actions;
  final ActionModel? selectedAction;
  final bool isEditMode;
  final ValueChanged<bool> onEditModeChanged;
  final ValueChanged<ActionModel> onActionSelected;
  final ValueChanged<ActionModel> onActionUpdated;

  const ActionSidebar({
    super.key,
    required this.actions,
    required this.selectedAction,
    required this.isEditMode,
    required this.onEditModeChanged,
    required this.onActionSelected,
    required this.onActionUpdated,
  });

  @override
  State<ActionSidebar> createState() => _ActionSidebarState();
}

class _ActionSidebarState extends State<ActionSidebar> {
  String _filterType = 'All';
  String _filterPlayer = 'All';
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  List<ActionModel> get _filteredActions {
    return widget.actions.where((a) {
      if (_filterType != 'All' && a.type != _filterType) return false;
      if (_filterPlayer != 'All' && a.playerId != _filterPlayer) return false;
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

    return Column(
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: actionTypes.contains(_filterType) ? _filterType : 'All',
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
                  setState(() => _filterType = v ?? 'All');
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: playerIds.contains(_filterPlayer) ? _filterPlayer : 'All',
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
                  setState(() => _filterPlayer = v ?? 'All');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
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
                              InkWell(
                                onTap: () => _editAction(context, action),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Text('EDIT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                                      SizedBox(width: 4),
                                      Icon(Icons.edit, color: Colors.white30, size: 14),
                                    ],
                                  ),
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
        ),
      ],
    );
  }

  void _editAction(BuildContext context, ActionModel action) {
    final typeController = TextEditingController(text: action.type);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Edit Action', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Action Type', labelStyle: TextStyle(color: Colors.white70)),
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
