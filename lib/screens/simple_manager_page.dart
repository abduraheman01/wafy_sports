import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/models/player_model.dart';

class SimpleManagerPage extends StatefulWidget {
  const SimpleManagerPage({super.key});
  @override
  State<SimpleManagerPage> createState() => _SimpleManagerPageState();
}

class _SimpleManagerPageState extends State<SimpleManagerPage> {
  // Controllers for Match Form
  final _homeTeamController = TextEditingController();
  final _awayTeamController = TextEditingController();
  final _homeLogoController = TextEditingController();
  final _awayLogoController = TextEditingController();
  final _timeController = TextEditingController();
  String _selectedCategory = '6s';
  String _selectedStatus = 'Upcoming';
  String _selectedStage = 'Group Stage';

  // Controllers for Player Form
  final _playerNameController = TextEditingController();
  final _playerTeamNameController = TextEditingController();
  final _playerTeamLogoController = TextEditingController();

  // Controllers for Event Form
  final _eventPlayerController = TextEditingController();
  final _eventMinuteController = TextEditingController();

  // Controllers for Update Form
  final _updateTimeController = TextEditingController();
  final _penaltyHomeController = TextEditingController();
  final _penaltyAwayController = TextEditingController();

  void _saveMatch() async {
    if (_homeTeamController.text.isEmpty ||
        _awayTeamController.text.isEmpty ||
        _homeLogoController.text.isEmpty ||
        _awayLogoController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all match fields.")));
      return;
    }

    await FirebaseFirestore.instance.collection('matches').add({
      'category': _selectedCategory,
      'matchStage': _selectedStage,
      'status': _selectedStatus,
      'homeTeamName': _homeTeamController.text,
      'awayTeamName': _awayTeamController.text,
      'homeTeamLogo': _homeLogoController.text,
      'awayTeamLogo': _awayLogoController.text,
      'time': _timeController.text,
      'homeScore': 0,
      'awayScore': 0,
      'date': Timestamp.now(),
      'stats': {},
      'events': [],
    });

    _homeTeamController.clear();
    _awayTeamController.clear();
    _homeLogoController.clear();
    _awayLogoController.clear();
    _timeController.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Match added successfully!")));
  }

  void _savePlayer() async {
    if (_playerNameController.text.isEmpty ||
        _playerTeamNameController.text.isEmpty ||
        _playerTeamLogoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all player fields.")));
      return;
    }

    await FirebaseFirestore.instance.collection('players').add({
      'name': _playerNameController.text,
      'teamName': _playerTeamNameController.text,
      'teamLogo': _playerTeamLogoController.text,
      'goals': 0,
      'saves': 0,
    });

    _playerNameController.clear();
    _playerTeamNameController.clear();
    _playerTeamLogoController.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Player added successfully!")));
  }

  void _showAddEventDialog(String matchId) {
    String eventType = 'goal';
    String team = 'home';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Match Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _eventPlayerController,
                  decoration: const InputDecoration(labelText: 'Player Name')),
              TextField(
                  controller: _eventMinuteController,
                  decoration: const InputDecoration(labelText: 'Minute'),
                  keyboardType: TextInputType.number),
              StatefulBuilder(builder: (context, setDialogState) {
                return Column(
                  children: [
                    DropdownButton<String>(
                      value: eventType,
                      onChanged: (String? newValue) {
                        setDialogState(() => eventType = newValue!);
                      },
                      items: <String>['goal', 'yellow_card', 'red_card']
                          .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.replaceAll('_', ' ').toUpperCase())))
                          .toList(),
                    ),
                    DropdownButton<String>(
                      value: team,
                      onChanged: (String? newValue) {
                        setDialogState(() => team = newValue!);
                      },
                      items: <String>['home', 'away']
                          .map((v) =>
                              DropdownMenuItem(value: v, child: Text(v.toUpperCase())))
                          .toList(),
                    ),
                  ],
                );
              })
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  final newEvent = {
                    'type': eventType,
                    'player': _eventPlayerController.text,
                    'minute': int.tryParse(_eventMinuteController.text) ?? 0,
                    'team': team,
                  };
                  FirebaseFirestore.instance
                      .collection('matches')
                      .doc(matchId)
                      .update({
                    'events': FieldValue.arrayUnion([newEvent])
                  });
                  _eventPlayerController.clear();
                  _eventMinuteController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Add Event')),
          ],
        );
      },
    );
  }

  void _showUpdateMatchDialog(Match match) {
    _updateTimeController.text = match.time;
    _penaltyHomeController.text = match.penaltyHomeScore?.toString() ?? '';
    _penaltyAwayController.text = match.penaltyAwayScore?.toString() ?? '';
    String currentStatus = match.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text("Update: ${match.homeTeamName} vs ${match.awayTeamName}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(builder: (context, setDialogState) {
                  return DropdownButtonFormField<String>(
                    value: currentStatus,
                    items: ['Upcoming', 'Live', 'Finished']
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        FirebaseFirestore.instance
                            .collection('matches')
                            .doc(match.id)
                            .update({'status': val});
                        setDialogState(() => currentStatus = val);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  );
                }),
                TextField(
                  controller: _updateTimeController,
                  decoration: const InputDecoration(
                      labelText: 'Time (e.g., HT, 85\', FT)'),
                  onSubmitted: (value) => FirebaseFirestore.instance
                      .collection('matches')
                      .doc(match.id)
                      .update({'time': value}),
                ),
                const SizedBox(height: 20),
                const Text("Penalty Shootout (if any)"),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: _penaltyHomeController,
                            decoration:
                                const InputDecoration(labelText: 'Home Pen.'),
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                            controller: _penaltyAwayController,
                            decoration:
                                const InputDecoration(labelText: 'Away Pen.'),
                            keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  child: const Text("Update Penalty Score"),
                  onPressed: () {
                    final int? homePen =
                        int.tryParse(_penaltyHomeController.text);
                    final int? awayPen =
                        int.tryParse(_penaltyAwayController.text);
                    FirebaseFirestore.instance
                        .collection('matches')
                        .doc(match.id)
                        .update({
                      'penaltyHomeScore': homePen,
                      'penaltyAwayScore': awayPen
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Penalties Updated!")));
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager Page')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Schedule New Match',
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: ['6s', '5s', '7s']
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: ['Upcoming', 'Live', 'Finished']
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedStatus = val!),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _selectedStage,
                items: [
                  'Group Stage',
                  'Knockout',
                  'Quarter Final',
                  'Semi Final',
                  'Final'
                ]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStage = val!),
                decoration: const InputDecoration(labelText: 'Match Stage'),
              ),
              TextField(
                  controller: _homeTeamController,
                  decoration:
                      const InputDecoration(labelText: 'Home Team Name')),
              TextField(
                  controller: _awayTeamController,
                  decoration:
                      const InputDecoration(labelText: 'Away Team Name')),
              TextField(
                  controller: _homeLogoController,
                  decoration: const InputDecoration(
                      labelText: 'Home Logo File (e.g., team.png)')),
              TextField(
                  controller: _awayLogoController,
                  decoration: const InputDecoration(
                      labelText: 'Away Logo File (e.g., team2.png)')),
              TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                      labelText: 'Time / Date Text (e.g., Tomorrow, 12:30 am)')),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _saveMatch, child: const Text('Schedule Match')),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
              title: 'Add New Player',
              children: [
                TextField(
                    controller: _playerNameController,
                    decoration: const InputDecoration(labelText: 'Player Name')),
                TextField(
                    controller: _playerTeamNameController,
                    decoration: const InputDecoration(
                        labelText: 'Player\'s Team Name')),
                TextField(
                    controller: _playerTeamLogoController,
                    decoration: const InputDecoration(
                        labelText: 'Team Logo File (e.g., team.png)')),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: _savePlayer, child: const Text('Save Player')),
              ]),
          const Divider(height: 40),
          Text("Manage Existing Data",
              style: Theme.of(context).textTheme.headlineSmall),
          _buildMatchesList(),
          _buildPlayersList(),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child:
                  Text("Matches", style: Theme.of(context).textTheme.titleLarge),
            ),
            ...snapshot.data!.docs.map((doc) {
              final match = Match.fromFirestore(doc);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title:
                      Text('${match.homeTeamName} vs ${match.awayTeamName}'),
                  subtitle:
                      Text('Score: ${match.homeScore} - ${match.awayScore}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildScoreButton(doc.id, 'homeScore', 1),
                      _buildScoreButton(doc.id, 'homeScore', -1),
                      const VerticalDivider(),
                      _buildScoreButton(doc.id, 'awayScore', 1),
                      _buildScoreButton(doc.id, 'awayScore', -1),
                      const VerticalDivider(),
                      IconButton(
                          tooltip: 'Update Details',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showUpdateMatchDialog(match)),
                      IconButton(
                          tooltip: 'Add Event',
                          icon: const Icon(Icons.add_comment),
                          onPressed: () => _showAddEventDialog(doc.id)),
                      IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => doc.reference.delete()),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildPlayersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('players').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child:
                  Text("Players", style: Theme.of(context).textTheme.titleLarge),
            ),
            ...snapshot.data!.docs.map((doc) {
              final player = Player.fromFirestore(doc);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(player.name),
                  subtitle:
                      Text('Goals: ${player.goals}, Saves: ${player.saves}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          tooltip: 'Add Goal',
                          icon:
                              const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => doc.reference
                              .update({'goals': FieldValue.increment(1)})),
                      IconButton(
                          tooltip: 'Add Save',
                          icon: const Icon(Icons.shield, color: Colors.blue),
                          onPressed: () => doc.reference
                              .update({'saves': FieldValue.increment(1)})),
                      IconButton(
                          tooltip: 'Delete Player',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => doc.reference.delete()),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildScoreButton(String docId, String field, int amount) {
    return IconButton(
      icon: Icon(amount > 0 ? Icons.add : Icons.remove),
      onPressed: () => FirebaseFirestore.instance
          .collection('matches')
          .doc(docId)
          .update({field: FieldValue.increment(amount)}),
    );
  }
}