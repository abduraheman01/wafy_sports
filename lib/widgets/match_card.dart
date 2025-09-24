import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/screens/match_detail_screen.dart';
import 'package:sports_app/config/app_config.dart';
import 'package:sports_app/widgets/safe_image.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);
    final isFinished = match.status == 'Finished';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match))),
      child: Container(
        margin: EdgeInsets.only(
          bottom: 16,
          left: isWeb ? 32 : 16,
          right: isWeb ? 32 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isFinished
                ? Colors.grey.withOpacity(0.2)
                : AppConfig.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            children: [
              // Match stage and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFinished
                          ? Colors.grey.withOpacity(0.1)
                          : AppConfig.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      match.matchStage,
                      style: TextStyle(
                        color: isFinished ? Colors.grey[700] : AppConfig.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM, HH:mm').format(match.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isWeb ? 24 : 20),
              // Teams and score
              Row(
                children: [
                  _buildModernTeamDisplay(true, match.homeTeamName, match.homeTeamLogo, context),
                  _buildModernScoreDisplay(context),
                  _buildModernTeamDisplay(false, match.awayTeamName, match.awayTeamLogo, context),
                ],
              ),
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

  Widget _buildModernTeamDisplay(bool isHome, String name, String logo, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: isWeb ? 60 : 50,
            height: isWeb ? 60 : 50,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TeamLogo(
                logoFileName: logo,
                size: isWeb ? 60 : 50,
              ),
            ),
          ),
          SizedBox(height: isWeb ? 12 : 8),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isWeb ? 16 : 14,
              color: const Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernScoreDisplay(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);
    final isFinished = match.status == 'Finished';
    final hasPenalties = isFinished && (match.penaltyHomeScore != null || match.penaltyAwayScore != null);

    return Container(
      width: isWeb ? 120 : 100,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isFinished
                  ? const Color(0xFFF8F9FA)
                  : AppConfig.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFinished
                    ? Colors.grey.withOpacity(0.2)
                    : AppConfig.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              isFinished
                  ? '${match.homeScore} : ${match.awayScore}'
                  : DateFormat('HH:mm').format(match.date),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isFinished ? const Color(0xFF1A1A1A) : AppConfig.primaryColor,
                fontSize: isWeb ? 20 : 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (hasPenalties) ...[
            const SizedBox(height: 8),
            Text(
              'Penalties: ${match.penaltyHomeScore} - ${match.penaltyAwayScore}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (isFinished) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConfig.accentColor.withOpacity(0.15),
                    Colors.green.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConfig.accentColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                'FULL TIME',
                style: TextStyle(
                  color: Colors.green[800],
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}