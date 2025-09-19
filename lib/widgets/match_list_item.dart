import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:intl/intl.dart';
import 'package:sports_app/screens/match_detail_screen.dart';

class MatchListItem extends StatelessWidget {
  final Match match;
  const MatchListItem({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match))),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
      ),
    );
  }

  Widget _buildTeamDisplay(String name, String logoFileName,
      {bool isHome = true}) {
    return Row(
      mainAxisAlignment: isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isHome) ...[
          Image.asset('assets/logos/$logoFileName',
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
          Image.asset('assets/logos/$logoFileName',
              width: 35,
              height: 35,
              errorBuilder: (c, o, s) => const Icon(Icons.shield, size: 35)),
        ],
      ],
    );
  }
}