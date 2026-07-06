import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/article.dart';

class NewsService {
  // ⚠️ Vérifie ces URLs de flux RSS, elles peuvent changer avec le temps.
  static const Map<String, String> feeds = {
    'À la une': 'https://www.france24.com/fr/rss',
    'France': 'https://www.france24.com/fr/france/rss',
    'Monde': 'https://www.france24.com/fr/monde/rss',
    'Afrique': 'https://www.france24.com/fr/afrique/rss',
    'Économie': 'https://www.france24.com/fr/eco-tech/rss',
  };

  Future<List<Article>> fetchArticles(String category) async {
    final url = feeds[category] ?? feeds['À la une']!;
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Erreur lors du chargement du flux ($category)');
    }

    final document = xml.XmlDocument.parse(response.body);
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
