import 'package:flutter/foundation.dart';

@immutable
class FeedEntity {
  const FeedEntity({
    required this.title,
    required this.link,
    required this.jobs,
  });

  final String title;

  /// The link to the search result on upwork.
  final String link;
  final Iterable<Job> jobs;

  @override
  String toString() {
    return '''${describeIdentity(this)}(
        title: $title,
        link: $link,
        jobs: $jobs,
    )''';
  }
}

@immutable
class Job {
  const Job({
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
    return '''${describeIdentity(this)}(
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
