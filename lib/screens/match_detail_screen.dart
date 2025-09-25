import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchDetailScreen extends StatefulWidget {
  final Match match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  static const Color newBlue = Color(0xFF002675);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').doc(widget.match.id).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final updatedMatch = Match.fromFirestore(snapshot.data!);

          return Column(
            children: [
              _buildCustomHeader(context),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildMatchCard(context, updatedMatch),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                      child: Text(
                        "Match Events",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    _buildEventsList(updatedMatch),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        color: newBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(Match updatedMatch) {
    if (updatedMatch.events.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: Text("No events yet.")),
        ),
      );
    }

    final homeEvents = updatedMatch.events.where((e) => e.team == 'home').toList();
    final awayEvents = updatedMatch.events.where((e) => e.team == 'away').toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
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
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Match updatedMatch) {
    final bool hasPenalties = updatedMatch.status == 'Finished' && (updatedMatch.penaltyHomeScore != null || updatedMatch.penaltyAwayScore != null);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Text(
              updatedMatch.category,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              updatedMatch.matchStage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildTeamDisplay(updatedMatch.homeTeamName, updatedMatch.homeTeamLogo)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Text(
                        '${updatedMatch.homeScore} : ${updatedMatch.awayScore}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (hasPenalties)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Pens: ${updatedMatch.penaltyHomeScore} - ${updatedMatch.penaltyAwayScore}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (updatedMatch.status == 'Live')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(30)),
                          child: Text(
                            updatedMatch.time,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(child: _buildTeamDisplay(updatedMatch.awayTeamName, updatedMatch.awayTeamLogo)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamDisplay(String name, String logoFileName) {
    return Column(
      children: [
        Image.asset('assets/images/$logoFileName', width: 60, height: 60, errorBuilder: (c, o, s) => const Icon(Icons.shield, size: 60)),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }

    Widget _buildEventTile(MatchEvent event, bool isHome) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
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
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'goal':
        return Icons.sports_soccer;
      case 'yellow_card':
      case 'red_card':
        return Icons.style;
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