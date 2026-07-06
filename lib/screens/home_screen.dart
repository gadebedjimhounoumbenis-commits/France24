import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/news_service.dart';
import '../widgets/article_card.dart';
import 'article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NewsService _service = NewsService();
  final categories = NewsService.feeds.keys.toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACTU 24'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: categories.map((category) {
          return _CategoryList(category: category, service: _service);
        }).toList(),
      ),
    );
  }
}

class _CategoryList extends StatefulWidget {
  final String category;
  final NewsService service;

  const _CategoryList({required this.category, required this.service});

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  late Future<List<Article>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchArticles(widget.category);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.service.fetchArticles(widget.category);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }
        final articles = snapshot.data ?? [];
        if (articles.isEmpty) {
          return const Center(child: Text('Aucun article trouvé'));
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return ArticleCard(
                article: article,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: article),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
