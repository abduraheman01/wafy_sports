import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/screens/match_detail_screen.dart';

class LiveMatchCard extends StatelessWidget {
  final Match match;
  const LiveMatchCard({super.key, required this.match});
  static const Color newBlue = Color(0xFF002675);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match))),
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 10),
        child: Card(
          color: newBlue,
          elevation: 4,
          shadowColor: newBlue.withOpacity(0.3),
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
                    Expanded(child: _buildTeamDisplay(match.homeTeamName, match.homeTeamLogo)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${match.homeScore}:${match.awayScore}',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    Expanded(child: _buildTeamDisplay(match.awayTeamName, match.awayTeamLogo)),
                  ],
                ),
                // Bottom section for Live indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _LiveIndicator(), // Pulsating dot
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      match.time,
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

  Widget _buildTeamDisplay(String name, String logoFileName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/$logoFileName',
          width: 45,
          height: 45,
          color: Colors.white,
          errorBuilder: (c, o, s) => const Icon(Icons.shield, size: 45, color: Colors.white),
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
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}