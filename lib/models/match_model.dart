import 'package:cloud_firestore/cloud_firestore.dart';

class MatchEvent {
  final int minute;
  final String player;
  final String type;
  final String team;

  MatchEvent({required this.minute, required this.player, required this.type, required this.team});

  factory MatchEvent.fromMap(Map<String, dynamic> map) {
    return MatchEvent(
      minute: int.tryParse(map['minute'].toString()) ?? 0,
      player: map['player']?.toString() ?? 'Unknown',
      type: map['type']?.toString() ?? 'goal',
      team: map['team']?.toString() ?? 'home',
    );
  }
}

class Match {
  final String id;
  final String status;
  final String matchStage;
  final String homeTeamName;
  final String awayTeamName;
  final String homeTeamLogo;
  final String awayTeamLogo;
  final int homeScore;
  final int awayScore;
  final int? penaltyHomeScore;
  final int? penaltyAwayScore;
  final String time;
  final DateTime date;
  final List<MatchEvent> events;

  Match({
    required this.id,
    required this.status,
    required this.matchStage,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
    required this.homeScore,
    required this.awayScore,
    this.penaltyHomeScore,
    this.penaltyAwayScore,
    required this.time,
    required this.date,
    required this.events,
  });

  factory Match.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    var eventsList = (data['events'] as List<dynamic>?)
            ?.map((eventData) => MatchEvent.fromMap(eventData as Map<String, dynamic>))
            .toList() ?? [];

    return Match(
      id: doc.id,
      status: data['status']?.toString() ?? 'Upcoming',
      matchStage: data['matchStage']?.toString() ?? 'Group Stage',
      homeTeamName: data['homeTeamName']?.toString() ?? '',
      awayTeamName: data['awayTeamName']?.toString() ?? '',
      homeTeamLogo: data['homeTeamLogo']?.toString() ?? '',
      awayTeamLogo: data['awayTeamLogo']?.toString() ?? '',
      homeScore: int.tryParse(data['homeScore'].toString()) ?? 0,
      awayScore: int.tryParse(data['awayScore'].toString()) ?? 0,
      penaltyHomeScore: int.tryParse(data['penaltyHomeScore']?.toString() ?? ''),
      penaltyAwayScore: int.tryParse(data['penaltyAwayScore']?.toString() ?? ''),
      time: data['time']?.toString() ?? '0\'',
      date: (data['date'] as Timestamp? ?? Timestamp.now()).toDate(),
      events: eventsList,
    );
  }
}