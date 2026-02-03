import 'package:rss_dart/dart_rss.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:workupdate/domain/job_entry.dart';

/// {@template feed_info}
/// A class that holds information about a feed.
///
/// Everytime a new feed is fetched or refreshed, a new instance of this class is created.
/// {@endtemplate}
@immutable
class FeedInfo {
  /// Creates a new [FeedInfo] instance.
  /// {@macro feed_info}
  const FeedInfo({
    required this.title,
    required this.link,
    required this.jobs,
  });

  /// Creates a new [FeedInfo] instance from an [RssFeed].
  ///
  /// This method parses the information in a given [RssFeed] and converts to a [FeedInfo] instance.
  factory FeedInfo.fromRssFeed(RssFeed feed) {
    return FeedInfo(
      title: feed.description!.formatTitle(),
      link: feed.link!,
      jobs: feed.items.map(JobEntry.fromRssItem),
    );
  }

  /// This mainly contains the date and time the feed was last updated.
  final String title;

  /// The link to the search result on upwork.
  final String link;

  /// The list of jobs fetched from the feed.
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

extension on String {
  /// Formats the title of the feed.
  ///
  /// The title of the feed is returned in the format: <![CDATA[All jobs as of January 19, 2024 11:51 UTC]]>
  /// This method extracts the date and time from the title, converts it to the local time zone,
  /// and returns it in the format: 'Jobs as of January 19, 2024 11:51 AM/PM'.
  String formatTitle() {
    // The date is between the words 'of' and 'UTC'.
    final dateRegExp = RegExp(r'of\s*(.*?)\s*UTC');
    final match = dateRegExp.firstMatch(this);
    final dateFromTitle = match!.group(1)!;

    final date = DateFormat(
      'MMMM dd, yyyy HH:mm',
    ).parseUTC(dateFromTitle).toLocal();
    final dateToLocal = DateFormat('MMMM dd, yyyy hh:mm a').format(date);
    return 'Jobs as of $dateToLocal';
  }
}
