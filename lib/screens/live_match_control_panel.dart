import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_app/models/match_model.dart';

class LiveMatchControlPanel extends StatelessWidget {
  final String matchId;
  const LiveMatchControlPanel({super.key, required this.matchId});

  DocumentReference get _matchRef =>
      FirebaseFirestore.instance.collection('matches').doc(matchId);

  void _updateScore(String field, int delta) {
    _matchRef.update({field: FieldValue.increment(delta)});
  }

  void _updateMinute(String currentTime, int delta) {
    int currentMinute = int.tryParse(currentTime.replaceAll("'", "")) ?? 0;
    int nextMinute = (currentMinute + delta).clamp(0, 120);
    _matchRef.update({'time': "$nextMinute'"});
  }

  void _showAddEventDialog(BuildContext context, String team) {
    final eventPlayerController = TextEditingController();
    final eventMinuteController = TextEditingController();
    String eventType = 'goal';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Add Event for ${team == 'home' ? 'Home' : 'Away'} Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: eventPlayerController, decoration: const InputDecoration(labelText: 'Player Name')),
              TextField(controller: eventMinuteController, decoration: const InputDecoration(labelText: 'Minute'), keyboardType: TextInputType.number),
              StatefulBuilder(builder: (context, setDialogState) {
                return DropdownButton<String>(
                  value: eventType,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    setDialogState(() => eventType = newValue!);
                  },
                  items: <String>['goal', 'yellow_card', 'red_card']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' ').toUpperCase())))
                      .toList(),
                );
              })
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  final newEvent = {
                    'type': eventType,
                    'player': eventPlayerController.text,
                    'minute': int.tryParse(eventMinuteController.text) ?? 0,
                    'team': team,
                  };
                  _matchRef.update({'events': FieldValue.arrayUnion([newEvent])});
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Add Event')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Match Controls')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _matchRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final match = Match.fromFirestore(snapshot.data!);
          final homeEvents = match.events.where((e) => e.team == 'home').toList();
          final awayEvents = match.events.where((e) => e.team == 'away').toList();

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('${match.homeTeamName} vs ${match.awayTeamName}', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                           Text(
                            match.time,
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.black)
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Minute:", style: TextStyle(fontSize: 18, color: Colors.black)),
                              IconButton(icon: const Icon(Icons.remove_circle, size: 30, color: Colors.redAccent), onPressed: () => _updateMinute(match.time, -1)),
                              IconButton(icon: const Icon(Icons.add_circle, size: 30, color: Colors.green), onPressed: () => _updateMinute(match.time, 1)),
                            ],
                          ),
                          const SizedBox(height: 10),
                           Wrap(
                            spacing: 10, alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton(onPressed: () => _matchRef.update({'time': 'HT'}), child: const Text('Half Time')),
                              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _matchRef.update({'status': 'Finished', 'time': 'FT'}), child: const Text('Full Time')),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildScoreController(context, match.homeTeamName, match.homeScore, 'homeScore', homeEvents, 'home')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildScoreController(context, match.awayTeamName, match.awayScore, 'awayScore', awayEvents, 'away')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreController(BuildContext context, String teamName, int score, String field, List<MatchEvent> events, String team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(teamName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
            Text(score.toString(), style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.black)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.remove), onPressed: () => _updateScore(field, -1)),
                IconButton(icon: const Icon(Icons.add), onPressed: () => _updateScore(field, 1)),
              ],
            ),
            const Divider(),
            const Text("Events", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            if (events.isEmpty) const Padding(padding: EdgeInsets.all(8.0), child: Text('No events', style: TextStyle(color: Colors.grey))),
            ...events.map((event) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(_getEventIcon(event.type), color: _getEventColor(event.type), size: 18),
              title: Text(event.player, style: const TextStyle(color: Colors.black, fontSize: 14)),
              trailing: Text("${event.minute}'", style: const TextStyle(color: Colors.black, fontSize: 14)),
            )).toList(),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
              onPressed: () => _showAddEventDialog(context, team),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'goal': return Icons.sports_soccer;
      case 'yellow_card': case 'red_card': return Icons.style;
      default: return Icons.event;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'goal': return Colors.green;
      case 'yellow_card': return Colors.yellow.shade800;
      case 'red_card': return Colors.red;
      default: return Colors.grey;
    }
  }
}