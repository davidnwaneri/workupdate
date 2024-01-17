import 'package:flutter/foundation.dart';

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
