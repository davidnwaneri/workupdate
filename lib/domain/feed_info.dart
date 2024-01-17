import 'package:dart_rss/dart_rss.dart';
import 'package:flutter/foundation.dart';
import 'package:workupdate/domain/job_entry.dart';
import 'package:workupdate/utils/extension_parsers.dart';

@immutable
class FeedInfo {
  const FeedInfo({
    required this.title,
    required this.link,
    required this.jobs,
  });

  factory FeedInfo.fromRssFeed(RssFeed feed) {
    return FeedInfo(
      title: feed.description!.removeHtmlTags().formatAppBarTitle(),
      link: feed.link!,
      jobs: feed.items.map(JobEntry.fromRssItem),
    );
  }

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
