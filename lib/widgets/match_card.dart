import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/screens/match_detail_screen.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match))),
      child: Card(
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTeamDisplay(true, match.homeTeamName, match.homeTeamLogo),
              _buildScoreOrTimeDisplay(),
              _buildTeamDisplay(false, match.awayTeamName, match.awayTeamLogo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamDisplay(bool isHome, String name, String logo) {
    return Expanded(
      child: Row(
        mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isHome) ...[
            Flexible(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Image.asset('assets/images/$logo',
              width: 35,
              height: 35,
              errorBuilder: (c, o, s) => const Icon(Icons.shield, size: 35)),
          if (isHome) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreOrTimeDisplay() {
    bool isFinished = match.status == 'Finished';
    bool hasPenalties = isFinished && (match.penaltyHomeScore != null || match.penaltyAwayScore != null);

    return Container(
      width: 90,
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            isFinished
                ? '${match.homeScore} - ${match.awayScore}'
                : DateFormat('HH:mm').format(match.date),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
          if (hasPenalties)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                '(${match.penaltyHomeScore} - ${match.penaltyAwayScore}) Pens',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM').format(match.date),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            match.matchStage,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          // ADDED: Conditionally display "FT" for finished matches
          if (isFinished)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                'FT',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}