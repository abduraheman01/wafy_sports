import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/widgets/match_card.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage>
    with TickerProviderStateMixin {
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
          tabs:
              _categories.map((String category) => Tab(text: category)).toList(),
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
// In lib/screens/matches_page.dart

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
      // FIXED: Removed the .orderBy('date') part of the query
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('category', isEqualTo: widget.category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No matches found for ${widget.category}."));
        }

        final allMatches =
            snapshot.data!.docs.map((doc) => Match.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: allMatches.length,
          itemBuilder: (context, index) {
            return MatchCard(match: allMatches[index]);
          },
        );
      },
    );
  }
}