import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/screens/match_detail_screen.dart';

class LiveMatchCard extends StatelessWidget {
  final Match match;
  const LiveMatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match))),
      child: Card(
        color: const Color(0xFF181829),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            children: [
              Text(match.matchStage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTeamDisplay(match.homeTeamName, match.homeTeamLogo),
                  Column(
                    children: [
                      Text(
                        '${match.homeScore} : ${match.awayScore}',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          match.time,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  _buildTeamDisplay(match.awayTeamName, match.awayTeamLogo),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamDisplay(String name, String logoFileName) {
    return Column(
      children: [
        Image.asset('assets/images/$logoFileName',
            width: 45,
            height: 45,
            errorBuilder: (c, o, s) =>
                const Icon(Icons.shield, size: 45, color: Colors.white)),
        const SizedBox(height: 8),
        Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14)),
      ],
    );
  }
}