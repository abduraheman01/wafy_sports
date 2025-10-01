import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sports_app/models/player_model.dart';
import 'package:sports_app/screens/simple_manager_page.dart';
import 'package:sports_app/config/app_config.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  // UPDATED: Changed category names
  final List<String> _categories = ['Sub Junior', 'Junior', 'Senior'];
  static const Color newBlue = Color(0xFF002675);
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manager Access'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_passwordController.text == 'abdu15211') {
                  Navigator.pop(context); // Close the dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SimpleManagerPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect Password')),
                  );
                }
                _passwordController.clear();
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(double headerHeight) {
    return GestureDetector(
      onDoubleTap: _showPasswordDialog,
      child: Container(
        height: headerHeight,
        width: double.infinity,
        
        alignment: Alignment.center,
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Image.asset(
          'assets/images/LogoWide.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double headerHeight = screenHeight / 5;

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: const Text('Leaderboard'),
              pinned: true,
              floating: true,
              bottom: TabBar(
                controller: _tabController,
                tabs: _categories
                    .map((String category) => Tab(text: category))
                    .toList(),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: newBlue,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
              ),
            ),
          ];
        },
        body: TabBarView(
            controller: _tabController,
            children: _categories.map((String category) {
              return CategoryLeaderboard(category: category);
            }).toList()),
      ),
    );
  }
}

class CategoryLeaderboard extends StatelessWidget {
  final String category;
  const CategoryLeaderboard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLeaderboardSection(
          context: context,
          title: 'Top Scorers',
          stream: FirebaseFirestore.instance
              .collection('players')
              .where('category', isEqualTo: category)
              .orderBy('goals', descending: true)
              .limit(5)
              .snapshots(),
          statField: 'goals',
        ),
        const SizedBox(height: 24),
        // _buildLeaderboardSection(
        //   context: context,
        //   title: 'Most Saves',
        //   stream: FirebaseFirestore.instance
        //       .collection('players')
        //       .where('category', isEqualTo: category)
        //       .orderBy('saves', descending: true)
        //       .limit(5)
        //       .snapshots(),
        //   statField: 'saves',
        // ),
      ],
    );
  }

  Widget _buildLeaderboardSection({
    required BuildContext context,
    required String title,
    required Stream<QuerySnapshot> stream,
    required String statField,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Error: ${snapshot.error}"),
              ));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('No players found.'),
              );
            }

            final players = snapshot.data!.docs;
            return Column(
              children: List.generate(players.length, (index) {
                final player = Player.fromFirestore(players[index]);
                return _buildPlayerTile(
                    context,
                    player,
                    index + 1,
                    statField == 'goals' ? player.goals : player.saves);
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayerTile(
      BuildContext context, Player player, int rank, int statValue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/${player.teamLogo}',
            width: 40,
            height: 40,
            errorBuilder: (c, o, s) =>
                const Icon(Icons.shield, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  player.teamName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$statValue',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF002675),
            ),
          ),
        ],
      ),
    );
  }
}