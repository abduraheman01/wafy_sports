import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/screens/match_detail_screen.dart';
import 'package:sports_app/config/app_config.dart';
import 'package:sports_app/widgets/safe_image.dart';

class LiveMatchCard extends StatelessWidget {
  final Match match;
  const LiveMatchCard({super.key, required this.match});
  static const Color newBlue = Color(0xFF002675);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);
    final cardWidth = isWeb ? 400.0 : 320.0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match))),
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: isWeb ? 16 : 10),
        child: Card(
          color: AppConfig.secondaryColor,
          elevation: 4,
          shadowColor: AppConfig.secondaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top section for Match Stage and Category
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match.matchStage,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    // ADDED: Display for the match category
                    Text(
                      match.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                // Middle section for teams and score
                Row(
                  children: [
                    Expanded(child: _buildTeamDisplay(match.homeTeamName, match.homeTeamLogo, context)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isWeb ? 12.0 : 8.0),
                      child: Text(
                        '${match.homeScore}:${match.awayScore}',
                        style: TextStyle(
                            fontSize: isWeb ? 42 : 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    Expanded(child: _buildTeamDisplay(match.awayTeamName, match.awayTeamLogo, context)),
                  ],
                ),
                // Bottom section for Live indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _LiveIndicator(), // Pulsating dot
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppConfig.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getGamePhaseDisplay(match.gamePhase),
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${match.currentMinute.toString().padLeft(2, '0')}:${match.currentSecond.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamDisplay(String name, String logoFileName, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TeamLogo(
          logoFileName: logoFileName,
          size: isWeb ? 55 : 45,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getGamePhaseDisplay(String phase) {
    switch (phase) {
      case 'first_half':
        return '1ST HALF';
      case 'halftime':
        return 'HALFTIME';
      case 'second_half':
        return '2ND HALF';
      case 'finished':
        return 'FINISHED';
      default:
        return '1ST HALF';
    }
  }
}

// Stateful widget for the pulsating "live" dot animation
class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppConfig.accentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppConfig.accentColor.withValues(alpha: 0.6),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}