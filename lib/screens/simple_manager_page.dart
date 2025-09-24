import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/models/player_model.dart';
import 'package:sports_app/screens/live_match_control_panel.dart';

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
  TimeOfDay? _selectedTime;
  // UPDATED: Default category and list
  String _selectedCategory = 'Sub Junior';
  String _selectedStage = 'Group Stage';

  // Controllers for Player Form
  final _playerNameController = TextEditingController();
  final _playerTeamNameController = TextEditingController();
  final _playerTeamLogoController = TextEditingController();
  // UPDATED: Default category
  String _playerSelectedCategory = 'Sub Junior';

  // ... (rest of the controllers are unchanged)
  final _eventPlayerController = TextEditingController();
  final _eventMinuteController = TextEditingController();
  final _updateTimeController = TextEditingController();
  final _penaltyHomeController = TextEditingController();
  final _penaltyAwayController = TextEditingController();

  final List<String> _categories = ['Sub Junior', 'Junior', 'Senior'];


  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveMatch() async {
    if (_homeTeamController.text.isEmpty ||
        _awayTeamController.text.isEmpty ||
        _homeLogoController.text.isEmpty ||
        _awayLogoController.text.isEmpty ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please fill all fields and select a time.")));
      return;
    }

    final matchDateTime =
        DateTime(2025, 9, 25, _selectedTime!.hour, _selectedTime!.minute);

    await FirebaseFirestore.instance.collection('matches').add({
      'category': _selectedCategory,
      'matchStage': _selectedStage,
      'status': 'Upcoming',
      'homeTeamName': _homeTeamController.text,
      'awayTeamName': _awayTeamController.text,
      'homeTeamLogo': _homeLogoController.text,
      'awayTeamLogo': _awayLogoController.text,
      'time':
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
      'homeScore': 0,
      'awayScore': 0,
      'date': Timestamp.fromDate(matchDateTime),
      'events': [],
    });

    _homeTeamController.clear();
    _awayTeamController.clear();
    _homeLogoController.clear();
    _awayLogoController.clear();
    setState(() => _selectedTime = null);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Match scheduled successfully!")));
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
      'category': _playerSelectedCategory,
      'goals': 0,
      'saves': 0,
    });

    _playerNameController.clear();
    _playerTeamNameController.clear();
    _playerTeamLogoController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Player added successfully!")));
  }
  
  // ... (dialog functions _showAddEventDialog and _showUpdateMatchDialog are unchanged)
  void _showAddEventDialog(String matchId) {
    String eventType = 'goal';
    String team = 'home';
    _eventPlayerController.clear();
    _eventMinuteController.clear();

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
                      // UPDATED: Using new category list
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                  const SizedBox(width: 16),
                   Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStage,
                      items: ['Group Stage', 'Knockout', 'Quarter Final', 'Semi Final', 'Final'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedStage = val!),
                      decoration: const InputDecoration(labelText: 'Match Stage'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _homeTeamController, decoration: const InputDecoration(labelText: 'Home Team Name')),
              TextField(controller: _awayTeamController, decoration: const InputDecoration(labelText: 'Away Team Name')),
              TextField(controller: _homeLogoController, decoration: const InputDecoration(labelText: 'Home Logo File (e.g., team.png)')),
              TextField(controller: _awayLogoController, decoration: const InputDecoration(labelText: 'Away Logo File (e.g., team2.png)')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Start Time: ${_selectedTime?.format(context) ?? 'Not Set'}'),
                trailing: const Icon(Icons.timer),
                onTap: _selectTime,
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _saveMatch, child: const Text('Schedule Match')),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            title: 'Add New Player',
            children: [
              DropdownButtonFormField<String>(
                value: _playerSelectedCategory,
                // UPDATED: Using new category list
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _playerSelectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(controller: _playerNameController, decoration: const InputDecoration(labelText: 'Player Name')),
              TextField(controller: _playerTeamNameController, decoration: const InputDecoration(labelText: 'Player\'s Team Name')),
              TextField(controller: _playerTeamLogoController, decoration: const InputDecoration(labelText: 'Team Logo File (e.g., team.png)')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _savePlayer, child: const Text('Save Player')),
            ],
          ),
          const Divider(height: 40),
          Text("Manage Existing Data", style: Theme.of(context).textTheme.headlineSmall),
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
      stream: FirebaseFirestore.instance.collection('matches').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Matches", style: Theme.of(context).textTheme.titleLarge),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final match = Match.fromFirestore(doc);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('${match.homeTeamName} vs ${match.awayTeamName}'),
                    subtitle: Text('${match.status} | Score: ${match.homeScore} - ${match.awayScore}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: match.status == 'Live' ? Colors.orange : Colors.green,
                          ),
                          child: Text(match.status == 'Live' ? 'Manage' : 'Go Live'),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => LiveMatchControlPanel(matchId: doc.id),
                            ));
                          },
                        ),
                         IconButton(
                          tooltip: 'Update Details',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showUpdateMatchDialog(match)),
                        IconButton(
                          tooltip: 'Add Event',
                          icon: const Icon(Icons.add_comment),
                          onPressed: () => _showAddEventDialog(doc.id)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => doc.reference.delete(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
              child: Text("Players", style: Theme.of(context).textTheme.titleLarge),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final player = Player.fromFirestore(doc);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(player.name),
                    subtitle: Text('Goals: ${player.goals}, Saves: ${player.saves}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(tooltip: 'Add Goal', icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => doc.reference.update({'goals': FieldValue.increment(1)})),
                        IconButton(tooltip: 'Add Save', icon: const Icon(Icons.shield, color: Colors.blue), onPressed: () => doc.reference.update({'saves': FieldValue.increment(1)})),
                        IconButton(tooltip: 'Delete Player', icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}