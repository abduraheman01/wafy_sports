import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/screens/match_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:sports_app/widgets/custom_card.dart';
import 'package:sports_app/widgets/live_match_card.dart'; // FIXED: Add this import

class MatchCard extends StatelessWidget {
  final Match match;
  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    // Show a special dark card for live matches
    if (match.status == 'Live') {
      return LiveMatchCard(match: match);
    }

    // Use your white CustomCard for other matches
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match))),
      child: CustomCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: _buildTeamDisplay(
                    match.homeTeamName, match.homeTeamLogo)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    match.status == 'Finished'
                        ? '${match.homeScore} - ${match.awayScore}'
                        : DateFormat('HH:mm').format(match.date),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16),
                  ),
                  if (match.status == 'Finished')
                    Text(DateFormat('dd MMM').format(match.date),
                        style: const TextStyle(color: Colors.grey, fontSize: 12))
                ],
              ),
            ),
            Expanded(
                child: _buildTeamDisplay(
                    match.awayTeamName, match.awayTeamLogo,
                    isHome: false)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamDisplay(String name, String logoFileName,
      {bool isHome = true}) {
    return Row(
      mainAxisAlignment: isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isHome) ...[
          Image.asset('assets/images/$logoFileName',
              width: 35,
              height: 35,
              errorBuilder: (c, o, s) => const Icon(Icons.shield, size: 35)),
          const SizedBox(width: 12),
        ],
        Flexible(
            child: Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 16),
                overflow: TextOverflow.ellipsis)),
        if (isHome) ...[
          const SizedBox(width: 12),
          Image.asset('assets/images/$logoFileName',
              width: 35,
              height: 35,
              errorBuilder: (c, o, s) => const Icon(Icons.shield, size: 35)),
        ],
      ],
    );
  }
}