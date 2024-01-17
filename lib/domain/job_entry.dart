import 'package:dart_rss/dart_rss.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:workupdate/utils/extension_parsers.dart';

@immutable
class JobEntry {
  const JobEntry({
    required this.title,
    required this.description,
    required this.link,
    required this.country,
    required this.category,
    required this.budget,
    required this.publishedAt,
    required this.skills,
  });

  factory JobEntry.fromRssItem(RssItem item) {
    return JobEntry(
      title: item.title!.removeUpworkText().removeHtmlTags(),
      description: item.description!.removeHtmlTags().extractDescription(),
      link: item.link!,
      country: item.description!.extractCountry(),
      publishedAt: DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').parseUTC(item.pubDate!).toLocal(),
      category: item.description!.extractCategory().removeHtmlTags(),
      budget: item.description!.getBudget(),
      skills: item.description!.extractSkills(),
    );
  }

  final String title;
  final String description;
  final String link;
  final String country;
  final String category;
  final String budget;
  final DateTime publishedAt;
  final Iterable<String> skills;

  @override
  String toString() {
    return '''
    ${describeIdentity(this)}(
        title: $title,
        description: $description,
        link: $link,
        country: $country,
        category: $category,
        budget: $budget,
        publishedAt: $publishedAt,
        skills: $skills,
    )''';
  }
}
