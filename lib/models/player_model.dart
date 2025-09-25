import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String id;
  final String name;
  final String teamName;
  final String teamLogo;
  final String category;
  final int goals;
  final int saves;

  Player({
    required this.id,
    required this.name,
    required this.teamName,
    required this.teamLogo,
    required this.category,
    required this.goals,
    required this.saves,
  });

  factory Player.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Player(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      teamName: data['teamName']?.toString() ?? '',
      teamLogo: data['teamLogo']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Uncategorized',
      goals: int.tryParse(data['goals'].toString()) ?? 0,
      saves: int.tryParse(data['saves'].toString()) ?? 0,
    );
  }
}