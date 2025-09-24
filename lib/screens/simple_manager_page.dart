import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/models/player_model.dart';
import 'package:sports_app/screens/live_match_control_panel.dart';
import 'package:sports_app/services/notification_service.dart';
import 'package:sports_app/config/app_config.dart';

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

  int _selectedNavIndex = 0;


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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: isWeb ? _buildWebDashboard(context) : _buildMobileLayout(context),
    );
  }

  Widget _buildWebDashboard(BuildContext context) {
    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConfig.primaryColor, AppConfig.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Manager Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildNavItem(Icons.sports_soccer, 'Live Matches', 0),
                    _buildNavItem(Icons.add_circle, 'Schedule Match', 1),
                    _buildNavItem(Icons.people, 'Players', 2),
                    _buildNavItem(Icons.analytics, 'Analytics', 3),
                    _buildNavItem(Icons.notifications_active, 'Notifications', 4),
                  ],
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.exit_to_app, size: 18),
                  label: const Text('Exit Manager'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main Content
        Expanded(
          child: Column(
            children: [
              // Top Bar
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      _getPageTitle(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppConfig.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 16,
                            color: AppConfig.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Mode',
                            style: TextStyle(
                              color: AppConfig.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area
              Expanded(
                child: _buildCurrentPage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMobileCard('Schedule Match', _buildScheduleForm()),
          const SizedBox(height: 16),
          _buildMobileCard('Add Player', _buildPlayerForm()),
          const SizedBox(height: 16),
          _buildMatchesList(),
          _buildPlayersList(),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedNavIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedNavIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppConfig.primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(
              color: AppConfig.primaryColor.withOpacity(0.3),
              width: 1,
            ) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppConfig.primaryColor : Colors.grey[600],
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppConfig.primaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedNavIndex) {
      case 0: return 'Live Matches';
      case 1: return 'Schedule Match';
      case 2: return 'Players Management';
      case 3: return 'Analytics';
      case 4: return 'Notifications';
      default: return 'Dashboard';
    }
  }

  Widget _buildCurrentPage() {
    switch (_selectedNavIndex) {
      case 0: return _buildLiveMatchesPage();
      case 1: return _buildScheduleMatchPage();
      case 2: return _buildPlayersPage();
      case 3: return _buildAnalyticsPage();
      case 4: return _buildNotificationsPage();
      default: return _buildLiveMatchesPage();
    }
  }

  Widget _buildLiveMatchesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWebCard(
            title: 'Active Matches',
            child: _buildMatchesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleMatchPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWebCard(
            title: 'Schedule New Match',
            child: _buildScheduleForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildWebCard(
                  title: 'Add New Player',
                  child: _buildPlayerForm(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildWebCard(
                  title: 'Players List',
                  child: _buildPlayersList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Matches', '24', Icons.sports_soccer, AppConfig.primaryColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Live Now', '2', Icons.live_tv, AppConfig.accentColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Players', '156', Icons.people, AppConfig.secondaryColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Categories', '3', Icons.category, Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildWebCard(
                  title: 'Recent Activity Feed',
                  child: Container(
                    height: 400,
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final activities = [
                          {'type': 'goal', 'text': 'Messi scored for Barcelona', 'time': '2 mins ago', 'icon': Icons.sports_soccer, 'color': Colors.green},
                          {'type': 'match', 'text': 'Real Madrid vs Barcelona started', 'time': '5 mins ago', 'icon': Icons.play_circle, 'color': AppConfig.primaryColor},
                          {'type': 'save', 'text': 'Goalkeeper made crucial save', 'time': '8 mins ago', 'icon': Icons.shield, 'color': Colors.blue},
                          {'type': 'card', 'text': 'Yellow card shown to Ramos', 'time': '12 mins ago', 'icon': Icons.warning, 'color': Colors.orange},
                          {'type': 'substitution', 'text': 'Player substitution made', 'time': '15 mins ago', 'icon': Icons.swap_horiz, 'color': Colors.purple},
                        ];
                        final activity = activities[index % activities.length];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (activity['color'] as Color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  activity['icon'] as IconData,
                                  color: activity['color'] as Color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity['text'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      activity['time'] as String,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildWebCard(
                      title: 'Quick Actions',
                      child: Column(
                        children: [
                          _buildQuickActionButton(
                            'Send Match Alert',
                            Icons.notifications,
                            AppConfig.primaryColor,
                            () {
                              NotificationService.instance.showMatchStartNotification(
                                'Real Madrid',
                                'Barcelona',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Match alert sent!')),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionButton(
                            'Goal Alert',
                            Icons.sports_soccer,
                            Colors.green,
                            () {
                              NotificationService.instance.showGoalNotification(
                                'Messi',
                                'Barcelona',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Goal alert sent!')),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionButton(
                            'System Status',
                            Icons.health_and_safety,
                            AppConfig.secondaryColor,
                            () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('System Status'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatusRow('Database', Icons.storage, Colors.green, 'Connected'),
                                      _buildStatusRow('Notifications', Icons.notifications,
                                        NotificationService.instance.isSupported ? Colors.green : Colors.red,
                                        NotificationService.instance.isSupported ? 'Supported' : 'Not Supported'),
                                      _buildStatusRow('PWA', Icons.install_mobile, Colors.green, 'Active'),
                                      _buildStatusRow('Web App', Icons.web, Colors.green, 'Online'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWebCard(
                      title: 'Match Categories',
                      child: Column(
                        children: [
                          _buildCategoryRow('Sub Junior', '8', AppConfig.primaryColor),
                          _buildCategoryRow('Junior', '10', AppConfig.secondaryColor),
                          _buildCategoryRow('Senior', '6', AppConfig.accentColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(String title, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStage,
                items: ['Group Stage', 'Knockout', 'Quarter Final', 'Semi Final', 'Final']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedStage = val!),
                decoration: InputDecoration(
                  labelText: 'Match Stage',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _homeTeamController,
                decoration: InputDecoration(
                  labelText: 'Home Team Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _awayTeamController,
                decoration: InputDecoration(
                  labelText: 'Away Team Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _homeLogoController,
                decoration: InputDecoration(
                  labelText: 'Home Logo File (e.g., team.png)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _awayLogoController,
                decoration: InputDecoration(
                  labelText: 'Away Logo File (e.g., team2.png)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectTime,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer),
                const SizedBox(width: 12),
                Text('Start Time: ${_selectedTime?.format(context) ?? 'Not Set'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveMatch,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Schedule Match', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _playerSelectedCategory,
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _playerSelectedCategory = val!),
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _playerNameController,
          decoration: InputDecoration(
            labelText: 'Player Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _playerTeamNameController,
          decoration: InputDecoration(
            labelText: 'Player\'s Team Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _playerTeamLogoController,
          decoration: InputDecoration(
            labelText: 'Team Logo File (e.g., team.png)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _savePlayer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Player', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
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

  Widget _buildNotificationsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWebCard(
            title: 'Notification Settings',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      NotificationService.instance.isPermissionGranted
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: NotificationService.instance.isPermissionGranted
                          ? AppConfig.primaryColor
                          : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Push Notifications',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            NotificationService.instance.isPermissionGranted
                                ? 'Notifications are enabled. Users can receive live updates.'
                                : 'Notifications are disabled. Click to request permission.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!NotificationService.instance.isPermissionGranted)
                      ElevatedButton(
                        onPressed: () async {
                          final granted = await NotificationService.instance.requestPermission();
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  granted
                                      ? 'Notification permission granted!'
                                      : 'Notification permission denied.',
                                ),
                                backgroundColor: granted ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Enable'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildWebCard(
            title: 'Test Notifications',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send Test Notification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Test the notification system with a sample message.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: NotificationService.instance.isSupported
                          ? () {
                              NotificationService.instance.sendTestNotification();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test notification sent!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : null,
                      child: const Text('Send Test'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Match Notification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Send a sample match start notification.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: NotificationService.instance.isSupported
                          ? () {
                              NotificationService.instance.showMatchStartNotification(
                                'Real Madrid',
                                'Barcelona',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Match notification sent!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : null,
                      child: const Text('Send Match'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Goal Notification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Send a sample goal notification.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: NotificationService.instance.isSupported
                          ? () {
                              NotificationService.instance.showGoalNotification(
                                'Lionel Messi',
                                'Barcelona',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Goal notification sent!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : null,
                      child: const Text('Send Goal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildWebCard(
            title: 'Browser Support',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      NotificationService.instance.isSupported
                          ? Icons.check_circle
                          : Icons.error,
                      color: NotificationService.instance.isSupported
                          ? Colors.green
                          : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            NotificationService.instance.isSupported
                                ? 'Browser supports notifications'
                                : 'Browser does not support notifications',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            NotificationService.instance.isSupported
                                ? 'This browser can display push notifications to users.'
                                : 'This browser cannot display notifications. Try using Chrome, Firefox, or Safari.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 18),
        label: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String title, IconData icon, Color color, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count matches',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}