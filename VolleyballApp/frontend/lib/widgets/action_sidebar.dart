import 'package:flutter/material.dart';
import '../models/action_model.dart';

class ActionSidebar extends StatefulWidget {
  final List<ActionModel> actions;
  final ActionModel? selectedAction;
  final ValueChanged<ActionModel> onActionSelected;
  final ValueChanged<ActionModel> onActionUpdated;

  const ActionSidebar({
    super.key,
    required this.actions,
    required this.selectedAction,
    required this.onActionSelected,
    required this.onActionUpdated,
  });

  @override
  State<ActionSidebar> createState() => _ActionSidebarState();
}

class _ActionSidebarState extends State<ActionSidebar> {
  String _filterType = 'All';
  String _filterPlayer = 'All';

  @override
  Widget build(BuildContext context) {
    Set<String> actionTypes = widget.actions.map((e) => e.type).toSet();
    Set<String> playerIds = widget.actions.map((e) => e.playerId).toSet();
    
    List<ActionModel> filteredActions = widget.actions.where((a) {
      if (_filterType != 'All' && a.type != _filterType) return false;
      if (_filterPlayer != 'All' && a.playerId != _filterPlayer) return false;
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF161616),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Actions List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
          child: ListView.separated(
            itemCount: filteredActions.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white12),
            itemBuilder: (context, index) {
              final action = filteredActions[index];
              final isSelected = widget.selectedAction?.id == action.id;
              
              Color accentColor = Colors.purpleAccent;
              if (action.type.toUpperCase() == 'BUMP') accentColor = Colors.blueAccent;
              if (action.type.toUpperCase() == 'SET') accentColor = Colors.greenAccent;
              if (action.type.toUpperCase().contains('SPIKE') || action.type.toUpperCase() == 'ATTACK') accentColor = Colors.redAccent;
              
              return ListTile(
                selected: isSelected,
                selectedTileColor: accentColor.withValues(alpha: 0.2),
                title: Text(action.type, style: TextStyle(color: isSelected ? accentColor : Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Player: ${action.playerId} | At: ${Duration(milliseconds: action.startMs.round()).toString().split('.').first}', style: const TextStyle(color: Colors.white70)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                  onPressed: () => _editAction(context, action),
                ),
                onTap: () => widget.onActionSelected(action),
              );
            },
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
