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
  List<Article> _articles = [];
  bool _loading = true;
  bool _isOffline = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1) Affiche immédiatement le cache s'il existe
    final cached = await widget.service.loadCachedArticles(widget.category);
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _articles = cached;
        _loading = false;
      });
    }
    // 2) Rafraîchit depuis le réseau
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await widget.service.fetchArticles(widget.category);
      if (!mounted) return;
      setState(() {
        _articles = fresh;
        _loading = false;
        _isOffline = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_articles.isNotEmpty) {
          _isOffline = true; // on garde le cache affiché, juste un bandeau
        } else {
          _errorMessage = 'Impossible de charger les articles.\nVérifie ta connexion internet.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _loading = true);
                  _refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange[100],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: const Text(
                '⚠ Hors connexion — affichage des derniers articles enregistrés',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _articles.length,
              itemBuilder: (context, index) {
                final article = _articles[index];
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
          ),
        ],
      ),
    );
  }
}