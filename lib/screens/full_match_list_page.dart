import 'package:flutter/material.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/widgets/match_card.dart';

class FullMatchListPage extends StatelessWidget {
  final String title;
  final List<Match> matches;

  const FullMatchListPage({
    super.key,
    required this.title,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return MatchCard(match: matches[index]);
        },
      ),
    );
  }
}