import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/widgets/match_card.dart';
import 'package:sports_app/screens/full_match_list_page.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> with TickerProviderStateMixin {
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
          indicatorWeight: 3.0,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((String category) {
              return CategoryMatchesList(category: category);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class CategoryMatchesList extends StatefulWidget {
  final String category;
  const CategoryMatchesList({super.key, required this.category});

  @override
  State<CategoryMatchesList> createState() => _CategoryMatchesListState();
}

class _CategoryMatchesListState extends State<CategoryMatchesList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('category', isEqualTo: widget.category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}\n\nThis usually means you need to create a Firestore Index. Check your debug console for a link to create it."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No matches for ${widget.category}."));
        }

        final allMatches = snapshot.data!.docs.map((doc) => Match.fromFirestore(doc)).toList();
        
        // Separate matches into lists based on status
        final live = allMatches.where((m) => m.status == 'Live').toList();
        final finished = allMatches.where((m) => m.status == 'Finished').toList();
        final upcoming = allMatches.where((m) => m.status == 'Upcoming').toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (live.isNotEmpty) ...[
              _buildSectionHeader(context, "Live Matches"),
              ...live.map((match) => MatchCard(match: match)),
              const SizedBox(height: 24),
            ],
            
            _buildSectionHeader(context, "Finished Matches", () {
              if (finished.isEmpty) return;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FullMatchListPage(title: "Finished Matches", matches: finished)
              ));
            }),
            if(finished.isEmpty) const Center(child: Text("No finished matches.")),
            ...finished.take(2).map((match) => MatchCard(match: match)),
            const SizedBox(height: 24),

            _buildSectionHeader(context, "Upcoming Matches", () {
               if (upcoming.isEmpty) return;
               Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FullMatchListPage(title: "Upcoming Matches", matches: upcoming)
              ));
            }),
            if(upcoming.isEmpty) const Center(child: Text("No upcoming matches.")),
            ...upcoming.take(2).map((match) => MatchCard(match: match)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, [VoidCallback? onSeeMore]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          if(onSeeMore != null)
            TextButton(
              onPressed: onSeeMore,
              child: const Text("See More", style: TextStyle(color: Colors.white70)),
            )
        ],
      ),
    );
  }
}