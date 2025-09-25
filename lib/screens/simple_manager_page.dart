import 'dart:async';
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
    try {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedTime = picked;
        });

        // Show confirmation feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Time selected: ${picked.format(context)}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting time: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                color: Colors.grey.withValues(alpha: 0.1),
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                      color: Colors.grey.withValues(alpha: 0.1),
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
                        color: AppConfig.accentColor.withValues(alpha: 0.1),
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
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SPORTIFY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Manager Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConfig.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: AppConfig.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppConfig.primaryColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(icon: Icon(Icons.sports_soccer), text: 'Matches'),
                  Tab(icon: Icon(Icons.person_add), text: 'Players'),
                  Tab(icon: Icon(Icons.list), text: 'Manage'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMobileMatchTab(),
                  _buildMobilePlayerTab(),
                  _buildMobileManageTab(),
                ],
              ),
            ),
          ],
        ),
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
            color: isSelected ? AppConfig.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(
              color: AppConfig.primaryColor.withValues(alpha: 0.3),
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
                                  color: (activity['color'] as Color).withValues(alpha: 0.1),
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
            color: Colors.grey.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.1),
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
            color: Colors.grey.withValues(alpha: 0.08),
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
            color: Colors.grey.withValues(alpha: 0.1),
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
        print('Matches StreamBuilder - Connection State: ${snapshot.connectionState}');
        print('Matches StreamBuilder - Has Data: ${snapshot.hasData}');
        print('Matches StreamBuilder - Has Error: ${snapshot.hasError}');
        if (snapshot.hasData) {
          print('Matches StreamBuilder - Document Count: ${snapshot.data!.docs.length}');
        }
        if (snapshot.hasError) {
          print('Matches StreamBuilder - Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading matches',
                  style: TextStyle(color: Colors.red[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No matches found',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Create your first match to get started!',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading players',
                  style: TextStyle(color: Colors.red[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No players found',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first player to get started!',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }
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
              color: color.withValues(alpha: 0.1),
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

  // Modern Mobile Tab Layouts
  Widget _buildMobileMatchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMobileActionCard(
            icon: Icons.add_circle,
            title: 'Schedule New Match',
            subtitle: 'Create a new match',
            onTap: () => _showMobileBottomSheet(
              context,
              'Schedule Match',
              _buildCompactScheduleForm(),
            ),
          ),
          const SizedBox(height: 16),
          _buildMatchesList(),
        ],
      ),
    );
  }

  Widget _buildMobilePlayerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMobileActionCard(
            icon: Icons.person_add,
            title: 'Add New Player',
            subtitle: 'Register a new player',
            onTap: () => _showMobileBottomSheet(
              context,
              'Add Player',
              _buildCompactPlayerForm(),
            ),
          ),
          const SizedBox(height: 16),
          _buildPlayersList(),
        ],
      ),
    );
  }

  Widget _buildMobileManageTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: AppConfig.backgroundColor,
            child: TabBar(
              labelColor: AppConfig.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppConfig.primaryColor,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Sub Junior'),
                Tab(text: 'Junior'),
                Tab(text: 'Senior'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCategoryManageView('Sub Junior'),
                _buildCategoryManageView('Junior'),
                _buildCategoryManageView('Senior'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryManageView(String category) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConfig.primaryColor.withValues(alpha: 0.1),
                  AppConfig.accentColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.category, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$category Management',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Manage $category matches and players',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Matches Section (Priority)
          _buildLiveMatchesSection(category),

          const SizedBox(height: 24),

          // Upcoming Matches Section
          _buildCategorySectionHeader('Upcoming Matches', Icons.schedule, category),
          const SizedBox(height: 12),
          _buildUpcomingMatchesList(category),

          const SizedBox(height: 24),

          // Finished Matches Section
          _buildCategorySectionHeader('Finished Matches', Icons.check_circle, category),
          const SizedBox(height: 12),
          _buildFinishedMatchesList(category),

          const SizedBox(height: 24),

          // Players Section
          _buildCategorySectionHeader('Players', Icons.people, category),
          const SizedBox(height: 12),
          _buildCategoryPlayersList(category),
        ],
      ),
    );
  }

  Widget _buildLiveMatchesSection(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'Live')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final liveMatches = snapshot.data?.docs.map((doc) {
          return Match.fromFirestore(doc);
        }).toList() ?? [];

        if (liveMatches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Matches Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[500]!, Colors.red[600]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.live_tv, color: Colors.red, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'LIVE MATCHES - Quick Control',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${liveMatches.length} Live',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Live Match Cards
            ...liveMatches.map((match) => _buildLiveMatchControlCard(match)),
          ],
        );
      },
    );
  }

  Widget _buildLiveMatchControlCard(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Match Header with Live indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Live indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${match.homeTeamName} vs ${match.awayTeamName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Timer Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${match.currentMinute.toString().padLeft(2, '0')}:${match.currentSecond.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        _getGamePhaseDisplay(match.gamePhase),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Score Display and Quick Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Score Display
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            match.homeTeamName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppConfig.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text(
                                match.homeScore.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            match.awayTeamName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppConfig.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text(
                                match.awayScore.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Timer Controls
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Timer Controls',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: match.isTimerRunning ? null : () => _startTimer(match),
                              icon: const Icon(Icons.play_arrow, size: 14),
                              label: const Text('Start', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: match.isTimerRunning ? () => _pauseTimer(match) : () => _resumeTimer(match),
                              icon: Icon(match.isTimerRunning ? Icons.pause : Icons.play_arrow, size: 14),
                              label: Text(match.isTimerRunning ? 'Pause' : 'Resume', style: const TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _resetTimer(match),
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('Reset', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (match.gamePhase == 'halftime') ...[
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          onPressed: () => _startSecondHalf(match),
                          icon: const Icon(Icons.fast_forward, size: 14),
                          label: const Text('Start 2nd Half', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                      if (match.gamePhase == 'second_half') ...[
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          onPressed: () => _endMatch(match),
                          icon: const Icon(Icons.stop, size: 14),
                          label: const Text('End Match', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Manual Timer Controls
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showSetTimerDialog(match),
                              icon: const Icon(Icons.edit_calendar, size: 14),
                              label: const Text('Set Timer', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: match.gamePhase == 'first_half' ? () => _triggerHalftime(match) : null,
                              icon: const Icon(Icons.pause_presentation, size: 14),
                              label: const Text('Halftime', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showQuickScoreUpdate(match),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Score'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEventDialog(match.id),
                        icon: const Icon(Icons.sports_soccer, size: 16),
                        label: const Text('Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showUpdateMatchDialog(match),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Manage'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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

  void _showQuickScoreUpdate(Match match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Score Update',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${match.homeTeamName} vs ${match.awayTeamName}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Home team score controls
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          match.homeTeamName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => _updateScore(match, 'home', -1),
                              icon: const Icon(Icons.remove_circle),
                              color: Colors.red,
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppConfig.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppConfig.primaryColor),
                              ),
                              child: Center(
                                child: Text(
                                  match.homeScore.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _updateScore(match, 'home', 1),
                              icon: const Icon(Icons.add_circle),
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Away team score controls
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          match.awayTeamName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => _updateScore(match, 'away', -1),
                              icon: const Icon(Icons.remove_circle),
                              color: Colors.red,
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppConfig.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppConfig.primaryColor),
                              ),
                              child: Center(
                                child: Text(
                                  match.awayScore.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _updateScore(match, 'away', 1),
                              icon: const Icon(Icons.add_circle),
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateScore(Match match, String team, int change) {
    final newHomeScore = team == 'home' ? match.homeScore + change : match.homeScore;
    final newAwayScore = team == 'away' ? match.awayScore + change : match.awayScore;

    if (newHomeScore < 0 || newAwayScore < 0) return;

    FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'homeScore': newHomeScore,
      'awayScore': newAwayScore,
    });
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

  void _startTimer(Match match) async {
    await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'isTimerRunning': true,
      'timerStartTime': FieldValue.serverTimestamp(),
      'gamePhase': match.gamePhase == 'finished' ? 'first_half' : match.gamePhase,
    });
    _startTimerUpdates(match.id);
  }

  void _pauseTimer(Match match) async {
    await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'isTimerRunning': false,
    });
  }

  void _resumeTimer(Match match) async {
    await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'isTimerRunning': true,
      'timerStartTime': FieldValue.serverTimestamp(),
    });
    _startTimerUpdates(match.id);
  }

  void _resetTimer(Match match) async {
    await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'currentMinute': 0,
      'currentSecond': 0,
      'isTimerRunning': false,
      'gamePhase': 'first_half',
      'timerStartTime': null,
      'halftimeStartTime': null,
    });
  }

  void _startSecondHalf(Match match) async {
    // Continue from where first half ended (don't reset timer to 0)
    await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'gamePhase': 'second_half',
      'isTimerRunning': true,
      'timerStartTime': FieldValue.serverTimestamp(),
      'halftimeStartTime': null,
    });
    _startTimerUpdates(match.id);
  }

  void _endMatch(Match match) async {
    await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'status': 'Finished',
      'gamePhase': 'finished',
      'isTimerRunning': false,
    });
  }

  void _startTimerUpdates(String matchId) {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final doc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
        if (!doc.exists) {
          timer.cancel();
          return;
        }

        final match = Match.fromFirestore(doc);
        if (!match.isTimerRunning) {
          timer.cancel();
          return;
        }

        int newMinute = match.currentMinute;
        int newSecond = match.currentSecond + 1;

        if (newSecond >= 60) {
          newSecond = 0;
          newMinute++;
        }

        // Auto halftime at 10 minutes for first half
        if (match.gamePhase == 'first_half' && newMinute >= 10) {
          await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
            'gamePhase': 'halftime',
            'isTimerRunning': false,
            'halftimeStartTime': FieldValue.serverTimestamp(),
          });
          timer.cancel();

          // Auto-resume after 1 minute halftime
          Timer(const Duration(minutes: 1), () {
            _startSecondHalf(match);
          });
          return;
        }

        // Auto finish at 20 minutes total (10 first half + 10 second half)
        if (match.gamePhase == 'second_half' && newMinute >= 20) {
          await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
            'status': 'Finished',
            'gamePhase': 'finished',
            'isTimerRunning': false,
          });
          timer.cancel();
          return;
        }

        await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
          'currentMinute': newMinute,
          'currentSecond': newSecond,
        });

      } catch (e) {
        timer.cancel();
      }
    });
  }

  void _showSetTimerDialog(Match match) {
    int selectedMinute = match.currentMinute;
    int selectedSecond = match.currentSecond;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Match Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select the current match time:'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Minutes', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(initialItem: selectedMinute),
                            itemExtent: 30,
                            perspective: 0.005,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setDialogState(() {
                                selectedMinute = index;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 60,
                              builder: (context, index) {
                                return Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    index.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: selectedMinute == index ? FontWeight.bold : FontWeight.normal,
                                      color: selectedMinute == index ? Colors.blue : Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Seconds', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(initialItem: selectedSecond),
                            itemExtent: 30,
                            perspective: 0.005,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setDialogState(() {
                                selectedSecond = index;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 60,
                              builder: (context, index) {
                                return Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    index.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: selectedSecond == index ? FontWeight.bold : FontWeight.normal,
                                      color: selectedSecond == index ? Colors.blue : Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Timer will be set to: ${selectedMinute.toString().padLeft(2, '0')}:${selectedSecond.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
                  'currentMinute': selectedMinute,
                  'currentSecond': selectedSecond,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Timer set to ${selectedMinute.toString().padLeft(2, '0')}:${selectedSecond.toString().padLeft(2, '0')}')),
                );
              },
              child: const Text('Set Timer'),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerHalftime(Match match) async {
    await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'gamePhase': 'halftime',
      'isTimerRunning': false,
      'halftimeStartTime': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${match.homeTeamName} vs ${match.awayTeamName} is now at halftime!')),
    );
  }

  String _formatMatchTime(DateTime matchDate) {
    final now = DateTime.now();
    final difference = matchDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else if (difference.inSeconds > 0) {
      return 'Soon';
    } else {
      // Past matches
      final pastDifference = now.difference(matchDate);
      if (pastDifference.inDays > 0) {
        return '${pastDifference.inDays}d ago';
      } else if (pastDifference.inHours > 0) {
        return '${pastDifference.inHours}h ago';
      } else {
        return 'Recent';
      }
    }
  }

  void _goLive(Match match) async {
    try {
      // Update match status to Live with confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Go Live'),
          content: Text('Start live broadcast for:\n${match.homeTeamName} vs ${match.awayTeamName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
                  'status': 'Live',
                  'gamePhase': 'first_half',
                  'currentMinute': 0,
                  'currentSecond': 0,
                  'isTimerRunning': false,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${match.homeTeamName} vs ${match.awayTeamName} is now LIVE!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Live'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error starting live match'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCategorySectionHeader(String title, IconData icon, String category) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppConfig.primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$category $title',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppConfig.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            'Manage',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingMatchesList(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Upcoming matches error: ${snapshot.error}');
          return _buildErrorCard('Failed to load upcoming matches: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard('Loading upcoming matches...');
        }

        // Filter and sort in code instead of using composite queries
        final allMatches = snapshot.data!.docs.map((doc) {
          return Match.fromFirestore(doc);
        }).toList();

        final matches = allMatches
            .where((match) => match.status == 'Upcoming')
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (matches.isEmpty) {
          return _buildEmptyCard(
            icon: Icons.schedule,
            title: 'No Upcoming $category Matches',
            subtitle: 'No upcoming matches scheduled',
          );
        }

        return Column(
          children: matches.map((match) => _buildManageMatchCard(match)).toList(),
        );
      },
    );
  }

  Widget _buildFinishedMatchesList(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Finished matches error: ${snapshot.error}');
          return _buildErrorCard('Failed to load finished matches: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard('Loading finished matches...');
        }

        // Filter and sort in code instead of using composite queries
        final allMatches = snapshot.data!.docs.map((doc) {
          return Match.fromFirestore(doc);
        }).toList();

        final matches = allMatches
            .where((match) => match.status == 'Finished')
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first

        if (matches.isEmpty) {
          return _buildEmptyCard(
            icon: Icons.check_circle,
            title: 'No Finished $category Matches',
            subtitle: 'No completed matches found',
          );
        }

        return Column(
          children: matches.map((match) => _buildManageMatchCard(match)).toList(),
        );
      },
    );
  }

  Widget _buildCategoryPlayersList(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('players')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Category players error: ${snapshot.error}');
          return _buildErrorCard('Failed to load players: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard('Loading players...');
        }

        final players = snapshot.data!.docs.map((doc) {
          return Player.fromFirestore(doc);
        }).toList();

        if (players.isEmpty) {
          return _buildEmptyCard(
            icon: Icons.person,
            title: 'No $category Players',
            subtitle: 'No players found in this category',
          );
        }

        return Column(
          children: players.map((player) => _buildManagePlayerCard(player)).toList(),
        );
      },
    );
  }

  Widget _buildManageMatchCard(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: match.status == 'Live' ? Colors.red :
                         match.status == 'Finished' ? Colors.green :
                         AppConfig.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${match.homeTeamName} vs ${match.awayTeamName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: match.status == 'Live' ? Colors.red :
                                   match.status == 'Finished' ? Colors.green :
                                   Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            match.status,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          match.matchStage,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Match time display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatMatchTime(match.date),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Go Live button (only for upcoming matches)
              if (match.status == 'Upcoming') ...[
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _goLive(match),
                    icon: const Icon(Icons.play_circle_fill, size: 16),
                    label: const Text('Go Live'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Edit/Manage button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateMatchDialog(match),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(match.status == 'Live' ? 'Manage' : 'Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: match.status == 'Live' ? Colors.orange : AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ));
  }

  Widget _buildManagePlayerCard(Player player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppConfig.primaryColor.withValues(alpha: 0.1),
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
              style: TextStyle(
                color: AppConfig.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  player.teamName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deletePlayer(player.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error, size: 48, color: Colors.red[400]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.red[700])),
        ],
      ),
    );
  }

  void _deleteMatch(String matchId) {
    FirebaseFirestore.instance.collection('matches').doc(matchId).delete();
  }

  void _deletePlayer(String playerId) {
    FirebaseFirestore.instance.collection('players').doc(playerId).delete();
  }

  Widget _buildMobileActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppConfig.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppConfig.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConfig.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileBottomSheet(BuildContext context, String title, Widget form) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: form,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactScheduleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMobileFormField('Home Team', _homeTeamController, Icons.home),
        const SizedBox(height: 16),
        _buildMobileFormField('Away Team', _awayTeamController, Icons.sports),
        const SizedBox(height: 16),
        _buildMobileFormField('Home Logo URL', _homeLogoController, Icons.image),
        const SizedBox(height: 16),
        _buildMobileFormField('Away Logo URL', _awayLogoController, Icons.image),
        const SizedBox(height: 16),
        _buildMobileDropdown('Category', _selectedCategory, _categories, (value) {
          setState(() => _selectedCategory = value!);
        }),
        const SizedBox(height: 16),
        _buildMobileDropdown('Stage', _selectedStage, ['Group Stage', 'Round of 16', 'Quarter Final', 'Semi Final', 'Final'], (value) {
          setState(() => _selectedStage = value!);
        }),
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
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              _saveMatch();
              Navigator.pop(context);
            },
            child: const Text('Schedule Match'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPlayerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMobileFormField('Player Name', _playerNameController, Icons.person),
        const SizedBox(height: 16),
        _buildMobileFormField('Team Name', _playerTeamNameController, Icons.group),
        const SizedBox(height: 16),
        _buildMobileFormField('Team Logo URL', _playerTeamLogoController, Icons.image),
        const SizedBox(height: 16),
        _buildMobileDropdown('Category', _playerSelectedCategory, _categories, (value) {
          setState(() => _playerSelectedCategory = value!);
        }),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              _savePlayer();
              Navigator.pop(context);
            },
            child: const Text('Add Player'),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFormField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppConfig.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConfig.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}