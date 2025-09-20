import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sports_app/models/player_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['6s', '5s', '7s'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

   @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
         TabBar(
          controller: _tabController,
          tabs: _categories.map((String category) => Tab(text: category)).toList(),
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((String category) {
              return CategoryLeaderboard(category: category);
            }).toList()
          ),
        ),
      ],
    );
  }
}

class CategoryLeaderboard extends StatelessWidget {
  final String category;
  const CategoryLeaderboard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          _buildLeaderboardSection(
            context: context,
            title: 'Top Scorers',
            stream: FirebaseFirestore.instance
                .collection('players')
                .where('category', isEqualTo: category)
                .orderBy('goals', descending: true)
                .limit(3)
                .snapshots(),
            statField: 'goals',
          ),
          const SizedBox(height: 24),
          _buildLeaderboardSection(
            context: context,
            title: 'Top Keepers (Saves)',
            stream: FirebaseFirestore.instance
                .collection('players')
                .where('category', isEqualTo: category)
                .orderBy('saves', descending: true)
                .limit(3)
                .snapshots(),
            statField: 'saves',
          ),
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
              return Center(child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Error: ${snapshot.error}\n\nThis usually means you need to create a Firestore Index. Check your debug console for a link to create it."),
              ));
            }
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty)
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('No players found.'),
              );

            final players = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = Player.fromFirestore(players[index]);
                return _buildPlayerTile(
                    context,
                    player,
                    index + 1,
                    statField == 'goals' ? player.goals : player.saves);
              },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Image.asset('assets/images/${player.teamLogo}',
                        width: 18,
                        height: 18,
                        errorBuilder: (c, o, s) =>
                            const Icon(Icons.shield, size: 18)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        player.teamName,
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$statValue',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }
}