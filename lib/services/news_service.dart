import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class NewsService {
  static const Map<String, String> feeds = {
    'À la une': 'https://www.france24.com/fr/rss',
    'France': 'https://www.france24.com/fr/france/rss',
    'Monde': 'https://www.france24.com/fr/monde/rss',
    'Afrique': 'https://www.france24.com/fr/afrique/rss',
    'Économie': 'https://www.france24.com/fr/eco-tech/rss',
  };

  String _cacheKey(String category) => 'cache_articles_$category';

  /// Charge les articles sauvegardés localement (peut être vide)
  Future<List<Article>> loadCachedArticles(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(category));
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = json.decode(raw);
      return decoded.map((e) => Article.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToCache(String category, List<Article> articles) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(articles.map((a) => a.toJson()).toList());
    await prefs.setString(_cacheKey(category), raw);
  }

  /// Récupère les articles en ligne, avec retries, et met à jour le cache.
  /// En cas d'échec total, retourne le cache existant (sans erreur) si disponible.
  Future<List<Article>> fetchArticles(String category, {int retries = 2}) async {
    final url = feeds[category] ?? feeds['À la une']!;
    Exception? lastError;

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 12));

        if (response.statusCode != 200) {
          throw Exception('Erreur serveur (${response.statusCode})');
        }

        final articles = _parseArticles(response.body, category);
        await _saveToCache(category, articles);
        return articles;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt < retries) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    // Échec réseau : on retombe sur le cache s'il existe
    final cached = await loadCachedArticles(category);
    if (cached.isNotEmpty) {
      return cached;
    }

    throw lastError ?? Exception('Erreur inconnue');
  }

  List<Article> _parseArticles(String body, String category) {
    final document = xml.XmlDocument.parse(body);
    final items = document.findAllElements('item');

    return items.map((item) {
      String getText(String tag) =>
          item.findElements(tag).isNotEmpty
              ? item.findElements(tag).first.innerText
              : '';

      String imageUrl = '';
      final mediaContent = item.findElements('media:content');
      if (mediaContent.isNotEmpty) {
        imageUrl = mediaContent.first.getAttribute('url') ?? '';
      } else {
        final enclosure = item.findElements('enclosure');
        if (enclosure.isNotEmpty) {
          imageUrl = enclosure.first.getAttribute('url') ?? '';
        }
      }

      return Article(
        title: getText('title'),
        description: getText('description'),
        link: getText('link'),
        pubDate: getText('pubDate'),
        imageUrl: imageUrl,
        category: category,
      );
    }).toList();
  }
}