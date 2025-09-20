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
  String _selectedCategory = '6s';
  String _selectedStage = 'Group Stage';

  // Controllers for Player Form
  final _playerNameController = TextEditingController();
  final _playerTeamNameController = TextEditingController();
  final _playerTeamLogoController = TextEditingController();

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
      'goals': 0,
      'saves': 0,
    });

    _playerNameController.clear();
    _playerTeamNameController.clear();
    _playerTeamLogoController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Player added successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager Page')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Schedule New Match for Sep 25, 2025',
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStage,
                      items: [
                        'Group Stage',
                        'Knockout',
                        'Quarter Final',
                        'Semi Final',
                        'Final'
                      ]
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedStage = val!),
                      decoration:
                          const InputDecoration(labelText: 'Match Stage'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Start Time: ${_selectedTime?.format(context) ?? 'Not Set'}'),
                trailing: const Icon(Icons.timer),
                onTap: _selectTime,
              ),
              const SizedBox(height: 12),
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
                  decoration:
                      const InputDecoration(labelText: 'Player\'s Team Name')),
              TextField(
                  controller: _playerTeamLogoController,
                  decoration: const InputDecoration(
                      labelText: 'Team Logo File (e.g., team.png)')),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _savePlayer, child: const Text('Save Player')),
            ],
          ),
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
      stream:
          FirebaseFirestore.instance.collection('matches').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final match = Match.fromFirestore(doc);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title:
                    Text('${match.homeTeamName} vs ${match.awayTeamName}'),
                subtitle: Text(
                    '${match.status} | Score: ${match.homeScore} - ${match.awayScore}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            match.status == 'Live' ? Colors.orange : Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(match.status == 'Live' ? 'Manage' : 'Go Live'),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              LiveMatchControlPanel(matchId: doc.id),
                        ));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => doc.reference.delete(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

   Widget _buildPlayersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('players').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return ListView.builder(
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
                subtitle:
                    Text('Goals: ${player.goals}, Saves: ${player.saves}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        tooltip: 'Add Goal',
                        icon: const Icon(Icons.add_circle, color: Colors.green),
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
          },
        );
      },
    );
  }
}