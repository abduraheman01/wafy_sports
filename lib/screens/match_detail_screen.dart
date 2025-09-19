import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_app/widgets/custom_card.dart';

class MatchDetailScreen extends StatelessWidget {
  final Match match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(match.matchStage), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').doc(match.id).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final updatedMatch = Match.fromFirestore(snapshot.data!);

          final homeEvents = updatedMatch.events.where((e) => e.team == 'home').toList();
          final awayEvents = updatedMatch.events.where((e) => e.team == 'away').toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CustomCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeamDisplay(updatedMatch.homeTeamName, updatedMatch.homeTeamLogo),
                    Column(
                      children: [
                        Text(
                          '${updatedMatch.homeScore} : ${updatedMatch.awayScore}',
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        if (updatedMatch.status == 'Live')
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              updatedMatch.time,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                    _buildTeamDisplay(updatedMatch.awayTeamName, updatedMatch.awayTeamLogo),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("Match Events", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 12),
              if (updatedMatch.events.isEmpty)
                const CustomCard(child: Center(child: Text("No events yet."))),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: homeEvents.map((event) => _buildEventTile(event, true)).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: awayEvents.map((event) => _buildEventTile(event, false)).toList(),
                    ),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  // Helper functions are now outside the build method for better organization

  Widget _buildTeamDisplay(String name, String logoFileName) {
    return Column(
      children: [
        Image.asset('assets/images/$logoFileName', width: 50, height: 50, errorBuilder: (c, o, s) => const Icon(Icons.shield, size: 50)),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }

  Widget _buildEventTile(MatchEvent event, bool isHome) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isHome) ...[
            Text("${event.minute}'"),
            const SizedBox(width: 8),
            Icon(_getEventIcon(event.type), color: _getEventColor(event.type), size: 18),
          ],
          Flexible(
            child: Text(
              event.player,
              textAlign: isHome ? TextAlign.start : TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          if (isHome) ...[
            const SizedBox(width: 8),
            Icon(_getEventIcon(event.type), color: _getEventColor(event.type), size: 18),
            const SizedBox(width: 8),
            Text("${event.minute}'"),
          ],
        ],
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'goal':
        return Icons.sports_soccer;
      case 'yellow_card':
      case 'red_card':
        return Icons.style; // Square card icon
      default:
        return Icons.event;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'goal':
        return Colors.green;
      case 'yellow_card':
        return Colors.amber;
      case 'red_card':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}