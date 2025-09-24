import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/screens/full_match_list_page.dart';
import 'package:sports_app/screens/simple_manager_page.dart';
import 'package:sports_app/widgets/live_match_card.dart';
import 'package:sports_app/widgets/match_card.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> with TickerProviderStateMixin {
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
                  Navigator.pop(context);
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
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(headerHeight),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No matches found."));
                }

                final allMatches = snapshot.data!.docs
                    .map((doc) => Match.fromFirestore(doc))
                    .toList();

                final liveMatches = allMatches.where((m) => m.status == 'Live').toList();
                final otherMatches = allMatches.where((m) => m.status != 'Live').toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (liveMatches.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                        child: Text(
                          "Live Match",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87),
                        ),
                      ),
                      CarouselSlider.builder(
                        itemCount: liveMatches.length,
                        itemBuilder: (context, index, realIndex) {
                          return LiveMatchCard(match: liveMatches[index]);
                        },
                        options: CarouselOptions(
                          height: 180,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.85,
                          enlargeFactor: 0.2,
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 8.0),
                      child: TabBar(
                        controller: _tabController,
                        tabs: _categories
                            .map((String category) => Tab(text: category))
                            .toList(),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black54,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: newBlue,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: TabBarView(
                        controller: _tabController,
                        children: _categories.map((category) {
                          return CategorizedMatchView(
                            matches: otherMatches,
                            category: category,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CategorizedMatchView extends StatelessWidget {
  final List<Match> matches;
  final String category;

  const CategorizedMatchView({
    super.key,
    required this.matches,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final categoryMatches = matches.where((m) => m.category == category).toList();
    final finishedMatches = categoryMatches.where((m) => m.status == 'Finished').toList();
    final upcomingMatches = categoryMatches.where((m) => m.status == 'Upcoming').toList();

    if (categoryMatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text("No matches for $category."),
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMatchSection(context, 'Finished Matches', finishedMatches),
          _buildMatchSection(context, 'Upcoming Matches', upcomingMatches),
        ],
      ),
    );
  }

  Widget _buildMatchSection(BuildContext context, String title, List<Match> matches) {
    if (matches.isEmpty) return const SizedBox.shrink();

    const int displayLimit = 2;
    final bool hasMore = matches.length > displayLimit;
    final List<Match> limitedMatches = hasMore ? matches.sublist(0, displayLimit) : matches;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ...limitedMatches.map((match) => MatchCard(match: match)).toList(),
          if (hasMore)
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => FullMatchListPage(title: title, matches: matches),
                  ));
                },
                child: const Text('See more'),
              ),
            ),
        ],
      ),
    );
  }
}