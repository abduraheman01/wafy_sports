import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_app/models/match_model.dart';
import 'package:sports_app/screens/full_match_list_page.dart';
import 'package:sports_app/screens/simple_manager_page.dart';
import 'package:sports_app/widgets/live_match_card.dart';
import 'package:sports_app/widgets/match_card.dart';
import 'package:sports_app/widgets/error_widgets.dart';
import 'package:sports_app/widgets/safe_image.dart';
import 'package:sports_app/config/app_config.dart';
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
                if (_passwordController.text == AppConfig.adminPassword) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);

    return GestureDetector(
      onDoubleTap: _showPasswordDialog,
      child: Container(
        height: isWeb ? headerHeight * 0.8 : headerHeight,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.only(
          left: isWeb ? 24.0 : 16.0,
          right: isWeb ? 24.0 : 16.0,
          bottom: 12.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clean logo design (no container styling)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeImage(
                imagePath: 'assets/images/LogoWide.png',
                height: isWeb ? 100 : 80,
                fit: BoxFit.contain,
                fallbackWidget: Container(
                  height: isWeb ? 100 : 80,
                  width: isWeb ? 200 : 160,
                  decoration: BoxDecoration(
                    color: AppConfig.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Simple logo icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.sports_soccer,
                          size: isWeb ? 24 : 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Clean text section
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main title - bold black text
                          Text(
                            'SPORTIFY',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: isWeb ? 20 : 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Simple subtitle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConfig.secondaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'MEET',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWeb ? 12 : 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isWeb) ...[
              const SizedBox(height: 8),
              Text(
                'Live Sports Updates & Match Tracking',
                style: TextStyle(
                  color: AppConfig.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double headerHeight = screenHeight / 4.5; // Optimized for better space usage

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(headerHeight),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(message: 'Loading matches...');
                }
                if (snapshot.hasError) {
                  return FirebaseErrorWidget(
                    error: snapshot.error.toString(),
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyDataWidget(
                    title: 'No Matches Yet',
                    subtitle: 'Check back later for upcoming matches and live scores.',
                    icon: Icons.sports_soccer,
                  );
                }

                final allMatches = snapshot.data!.docs
                    .map((doc) => Match.fromFirestore(doc))
                    .toList();

                final liveMatches = allMatches.where((m) => m.status == 'Live').toList();
                // Sort live matches by time (earliest started first)
                liveMatches.sort((a, b) {
                  int dateComparison = a.date.compareTo(b.date);
                  if (dateComparison == 0) {
                    // If same date, sort by time
                    return a.time.compareTo(b.time);
                  }
                  return dateComparison;
                });

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
                    Container(
                      margin: EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: isWeb ? 32.0 : 16.0,
                      ),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: _categories
                            .map((String category) => Tab(
                                  text: category,
                                  height: 40,
                                ))
                            .toList(),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF6B7280),
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              AppConfig.primaryColor,
                              AppConfig.secondaryColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppConfig.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: AppConfig.accentColor.withOpacity(0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        overlayColor: MaterialStateProperty.all(Colors.transparent),
                      ),
                    ),
                    Expanded(
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
          ),
        ],
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
    final categoryMatches = matches.where((m) =>
        m.category.toLowerCase().trim() == category.toLowerCase().trim()).toList();

    // Sort finished matches by most recent first
    final finishedMatches = categoryMatches.where((m) => m.status == 'Finished').toList();
    finishedMatches.sort((a, b) {
      int dateComparison = b.date.compareTo(a.date);
      if (dateComparison == 0) {
        // If same date, sort by time
        return b.time.compareTo(a.time);
      }
      return dateComparison;
    });

    // Sort upcoming matches chronologically (earliest first)
    final upcomingMatches = categoryMatches.where((m) => m.status == 'Upcoming').toList();
    upcomingMatches.sort((a, b) {
      int dateComparison = a.date.compareTo(b.date);
      if (dateComparison == 0) {
        // If same date, sort by time
        return a.time.compareTo(b.time);
      }
      return dateComparison;
    });

    if (categoryMatches.isEmpty) {
      return EmptyDataWidget(
        title: 'No $category Matches',
        subtitle: 'No matches available in this category yet.',
        icon: Icons.sports_soccer,
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
                  // Sort matches properly based on type
                  List<Match> sortedMatches = List.from(matches);

                  if (title.contains('Upcoming')) {
                    // Sort upcoming matches chronologically (earliest first)
                    sortedMatches.sort((a, b) {
                      int dateComparison = a.date.compareTo(b.date);
                      if (dateComparison == 0) {
                        return a.time.compareTo(b.time);
                      }
                      return dateComparison;
                    });
                  } else if (title.contains('Finished')) {
                    // Sort finished matches by most recent first
                    sortedMatches.sort((a, b) {
                      int dateComparison = b.date.compareTo(a.date);
                      if (dateComparison == 0) {
                        return b.time.compareTo(a.time);
                      }
                      return dateComparison;
                    });
                  }

                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => FullMatchListPage(title: title, matches: sortedMatches),
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