import 'package:flutter/foundation.dart';
import 'package:workupdate/domain/job_entry.dart';

@immutable
class FeedInfo {
  const FeedInfo({
    required this.title,
    required this.link,
    required this.jobs,
  });

  final String title;

  /// The link to the search result on upwork.
  final String link;
  final Iterable<JobEntry> jobs;

  @override
  String toString() {
    return '''
    ${describeIdentity(this)}(
        title: $title,
        link: $link,
        jobs: $jobs,
    )''';
  }
}
