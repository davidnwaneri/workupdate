import 'package:dart_rss/dart_rss.dart';
import 'package:dart_rss/domain/rss_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:workupdate/feed_entity.dart';

final dio = Dio()
  ..interceptors.add(
    TalkerDioLogger(
      settings: const TalkerDioLoggerSettings(
        printRequestHeaders: true,
      ),
    ),
  );

Future<String> getXmlString() async {
  const pageIndex = 0;
  const pageSize = 10;

  try {
    final res = await dio.get<String>(
      const String.fromEnvironment('BASE_URL'),
      queryParameters: {
        'q': 'flutter',
        'sort': 'recency',
        'paging': '$pageIndex;$pageSize',
        'api_params': '1',
        'securityToken': const String.fromEnvironment('SECURITY_TOKEN'),
        'userUid': const String.fromEnvironment('USER_UID'),
        'orgUid': const String.fromEnvironment('ORG_UID'),
      },
    );
    final xmlString = res.data!;
    return xmlString;
  } catch (e) {
    rethrow;
  }
}

Future<FeedEntity> convertXmlToFeed() async {
  try {
    final xmlString = await getXmlString();
    final rssFeed = RssFeed.parse(xmlString);

    final feed = FeedEntity(
      title: rssFeed.description!.removeHtmlTags(),
      link: rssFeed.link!,
      jobs: rssFeed.items.map(
        (e) => Job(
          title: e.title!.removeUpworkText().removeHtmlTags(),
          description: e.description!.removeHtmlTags().extractDescription(),
          link: e.link!,
          country: e.description!.extractCountry(),
          publishedAt: DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').parseUTC(e.pubDate!).toLocal(),
          category: e.description!.extractCategory().removeHtmlTags(),
          budget: e.description!.getBudget(),
          skills: e.description!.extractSkills(),
        ),
      ),
    );
    return feed;
  } catch (e) {
    rethrow;
  }
}

void main() {
  runApp(const WorkUpdateApp());
}

class WorkUpdateApp extends StatelessWidget {
  const WorkUpdateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workupdate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<void> _rssFeedFuture;
  FeedEntity? _feed;
  String? _appBarTitle;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('en', MyCustomMessages());
    _rssFeedFuture = getFeed();
  }

  Future<void> getFeed() async {
    try {
      final feed = await convertXmlToFeed();
      _feed = feed;
    } catch (e) {
      rethrow;
    } finally {
      _setAppBarTitle(_feed?.title);
    }
  }

  Future<void> _refreshFeed() async {
    try {
      final feed = await convertXmlToFeed();
      setState(() => _feed = feed);
    } catch (e) {
      if (mounted) showSnackBar(context, message: e.toString());
    } finally {
      _setAppBarTitle(_feed?.title);
    }
  }

  void _setAppBarTitle(String? text) {
    if (text == null || text == _appBarTitle) return;
    setState(() => _appBarTitle = text.formatAppBarTitle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          _appBarTitle ?? 'Workupdate',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: FutureBuilder<void>(
          future: _rssFeedFuture,
          builder: (context, AsyncSnapshot<void> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const LoadingView();
              case ConnectionState.active:
              case ConnectionState.done:
                final hasErrorAndNoInitialData = snapshot.hasError && _feed == null;
                final hasErrorAndInitialData = snapshot.hasError && _feed != null;

                if (hasErrorAndNoInitialData) return ErrorView(error: snapshot.error.toString());

                final feed = _feed!;
                final jobs = feed.jobs;

                if (hasErrorAndInitialData) {
                  return JobListView(
                    jobs: jobs,
                    onRefresh: _refreshFeed,
                  );
                } else {
                  // At this point there is no error, and everything was successful, so just return the data
                  return JobListView(
                    jobs: jobs,
                    onRefresh: _refreshFeed,
                  );
                }
            }
          },
        ),
      ),
    );
  }
}

class JobListView extends StatelessWidget {
  const JobListView({
    required this.jobs,
    required this.onRefresh,
    super.key,
  });

  final Iterable<Job> jobs;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return const Center(child: Text('No jobs found'));

    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs.elementAt(index);
            return FeedInfoCard(job: job);
          },
        ),
      ),
    );
  }
}

class FeedInfoCard extends StatelessWidget {
  const FeedInfoCard({
    required this.job,
    super.key,
  });
  final Job job;

  Future<void> _copyToClipboard(BuildContext context, String link) {
    return Clipboard.setData(ClipboardData(text: link)).then<void>(
      (_) {
        showSnackBar(context, message: 'Link copied to clipboard');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    timeago.format(job.publishedAt),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Pay: ${job.budget}',
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 5),
                Text(job.country),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: 'Category: ',
                  children: [
                    TextSpan(
                      text: job.category,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              job.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                job.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final skill in job.skills) ...[
                    Chip(label: Text(skill)),
                    const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                await launchUrl(
                  Uri.parse(job.link),
                  mode: LaunchMode.externalApplication,
                );
              },
              onLongPress: () => _copyToClipboard(context, job.link),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'View on Upwork',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                  // textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.error,
    super.key,
  });

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(error),
    );
  }
}

extension RemoveHtmlTagsX on String {
  String removeHtmlTags() {
    final document = parse(this);
    final parsedString = parse(document.body!.text).documentElement!.text;
    return parsedString;
  }

  String removeUpworkText() {
    return replaceAll('- Upwork', '');
  }

  String extractCountry() {
    final countryRegExp = RegExp(r'<b>Country</b>:\s*(.*?)\s*<br />');
    final match = countryRegExp.firstMatch(this);

    if (match != null) {
      return match.group(1)!;
    } else {
      return 'Unknown location';
    }
  }

  String extractCategory() {
    final categoryRegExp = RegExp(r'<b>Category</b>:\s*(.*?)\s*<br />');
    final match = categoryRegExp.firstMatch(this);

    return match!.group(1)!;
  }

  List<String> extractSkills() {
    final skillsRegExp = RegExp('<b>Skills</b>:(.*?)<br />');
    final match = skillsRegExp.firstMatch(this);

    if (match != null) {
      final skillsString = match.group(1)!;
      final skillsList = skillsString.split(',').map((e) => e.trim()).toList();
      return skillsList;
    } else {
      return [];
    }
  }

  String extractDescription() {
    final firstBreak = indexOf('Budget:');
    final secondBreak = indexOf('Hourly Range:');
    final thirdBreak = indexOf('Posted On:');

    if (firstBreak != -1) {
      return substring(0, firstBreak);
    } else if (secondBreak != -1) {
      return substring(0, secondBreak);
    } else {
      return substring(0, thirdBreak);
    }
  }

  String getBudget() {
    return extractHourlyPay() ?? extractFixedPrice() ?? 'Unavailable';
  }

  String? extractHourlyPay() {
    final hourlyPayRegExp = RegExp(r'<b>Hourly Range</b>:\s*(.*?)\s*<br />');
    final match = hourlyPayRegExp.firstMatch(this);

    if (match != null) {
      return '${match.group(1)!}/hr';
    } else {
      return null;
    }
  }

  String? extractFixedPrice() {
    final fixedPriceRegExp = RegExp(r'<b>Budget</b>:\s*(.*?)\s*<br />');
    final match = fixedPriceRegExp.firstMatch(this);

    if (match != null) {
      return match.group(1)!;
    } else {
      return null;
    }
  }

  String formatAppBarTitle() {
    final dateRegExp = RegExp(r'of\s*(.*?)\s*UTC');
    final match = dateRegExp.firstMatch(this);
    final dateFromTitle = match!.group(1)!;

    final date = DateFormat('MMMM dd, yyyy HH:mm').parseUTC(dateFromTitle).toLocal();
    final dateToLocal = DateFormat('MMMM dd, yyyy hh:mm a').format(date);
    return 'Jobs as of $dateToLocal';
  }
}

extension RssFeedToString on RssFeed {
  String string() {
    return '''
    ${describeIdentity(this)}(
      title: $title,
      author: $author,
      description: $description,
      link: $link,
      items: ${items.map((e) => e.string()).toList()},
      image: $image,
      cloud: $cloud,
      categories: $categories,
      skipDays: $skipDays,
      lastBuildDate: $lastBuildDate,
      language: $language,
      generator: $generator,
      copyright: $copyright,
      docs: $docs,
      managingEditor: $managingEditor,
      rating: $rating,
      webMaster: $webMaster,
      ttl: $ttl,
      dc: $dc,
      itunes: $itunes,
      podcastIndex: $podcastIndex,
      
    )
    ''';
  }
}

extension on RssItem {
  String string() {
    return '''
    ${describeIdentity(this)}(
      title: $title,
      description: $description,
      link: $link,
      categories: ${categories.map((e) => e.string()).toList()},
      guid: $guid,
      pubDate: $pubDate,
      author: $author,
      comments: $comments,
      source: ${source?.string()},
      content: ${content?.string()},
      media: $media,
      enclosure: $enclosure,
      dc: $dc,
      itunes: $itunes,
      podcastIndex: $podcastIndex,
    )
    ''';
  }
}

extension on RssCategory {
  String string() {
    return '''
    ${describeIdentity(this)}(
      domain: $domain,
      value: $value,
    )
    ''';
  }
}

extension on RssSource {
  String string() {
    return '''
    ${describeIdentity(this)}(
      url: $url,
      value: $value,
    )
    ''';
  }
}

extension on RssContent {
  String string() {
    return '''
    ${describeIdentity(this)}(
      value: $value,
      images: $images,
    )
    ''';
  }
}

class MyCustomMessages extends timeago.EnMessages {
  @override
  String aboutAnHour(int minutes) => '1 hour ${minutes % 60} minutes';

  @override
  String lessThanOneMinute(int seconds) => '$seconds seconds';
}

void showSnackBar(BuildContext context, {required String message}) {
  final snackbar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,

    margin: const EdgeInsets.only(
      left: 12,
      right: 12,
      bottom: 12,
    ),
    // width: 200,
  );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackbar);
}
