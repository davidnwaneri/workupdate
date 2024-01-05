import 'package:dart_rss/dart_rss.dart';
import 'package:dart_rss/domain/rss_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workupdate/feed_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

final dio = Dio();

Future<String> getXmlString() async {
  const pageIndex = 0;
  const pageSize = 10;

  try {
    final res = await dio.get(
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
    final xmlString = res.data as String;
    return xmlString;
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
  late Future<FeedEntity> _rssFeedFuture;
  String? _appBarTitle;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('en', MyCustomMessages());
    _rssFeedFuture = getFeed();
  }

  void _setAppBarTitle(String? text) {
    if (text == null) return;
    _appBarTitle = text;
  }

  Future<FeedEntity> getFeed() async {
    try {
      final xmlString = await getXmlString();
      var rssFeed = RssFeed.parse(xmlString);

      final feed = FeedEntity(
        title: rssFeed.description!.removeHtmlTags(),
        link: rssFeed.link!,
        jobs: rssFeed.items.map((e) => Job(
              title: e.title!.removeUpworkText().removeHtmlTags(),
              description: e.description!.removeHtmlTags().extractDescription(),
              link: e.link!,
              country: e.description!.extractCountry(),
              publishedAt: DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').parse(e.pubDate!),
              category: e.description!.extractCategory(),
              budget: e.description!.getBudget(),
              skills: e.description!.extractSkills(),
            )),
      );
      return feed;
    } catch (e) {
      rethrow;
    }
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
        child: FutureBuilder<FeedEntity>(
            future: _rssFeedFuture,
            builder: (context, AsyncSnapshot<FeedEntity> snapshot) {
              if (snapshot.hasError) {
                return ErrorView(error: snapshot.error.toString());
              }

              if (snapshot.hasData == false) {
                return const LoadingView();
              }

              final feed = snapshot.data!;
              final posts = feed.jobs;

              _setAppBarTitle(feed.title);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (posts.isEmpty)
                    const Text('Empty Post')
                  else
                    Expanded(
                      child: RefreshIndicator.adaptive(
                        onRefresh: () async {
                          final feed = await getFeed();
                          setState(() => _rssFeedFuture = Future.value(feed));
                        },
                        child: ListView.builder(
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final job = posts.elementAt(index);
                            return FeedInfo(job: job);
                          },
                        ),
                      ),
                    ),
                ],
              );
            }),
      ),
    );
  }
}

class FeedInfo extends StatelessWidget {
  const FeedInfo({
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
                  flex: 2,
                  child: Text(
                    job.title,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    timeago.format(job.publishedAt),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Text(job.country),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(job.category),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              runSpacing: 3,
              children: [
                for (final skill in job.skills) Chip(label: Text(skill)),
              ],
            ),
            const SizedBox(height: 10),
            Text(job.budget),
            const SizedBox(height: 10),
            Text(job.description),
            InkWell(
              onTap: () async {
                await launchUrl(
                  Uri.parse(job.link),
                  mode: LaunchMode.externalApplication,
                );
              },
              onLongPress: () => _copyToClipboard(context, job.link),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'View on Upwork',
                  textAlign: TextAlign.center,
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
    final String parsedString = parse(document.body!.text).documentElement!.text;
    return parsedString;
  }

  String removeUpworkText() {
    return replaceAll('- Upwork', '');
  }

  String extractCountry() {
    RegExp countryRegExp = RegExp(r'<b>Country</b>:\s*(.*?)\s*<br />');
    final match = countryRegExp.firstMatch(this);

    if (match != null) {
      return match.group(1)!;
    } else {
      return "Unknown location";
    }
  }

  String extractCategory() {
    RegExp categoryRegExp = RegExp(r'<b>Category</b>:\s*(.*?)\s*<br />');
    final match = categoryRegExp.firstMatch(this);

    return match!.group(1)!;
  }

  List<String> extractSkills() {
    RegExp skillsRegExp = RegExp(r'<b>Skills</b>:(.*?)<br />');
    final match = skillsRegExp.firstMatch(this);

    if (match != null) {
      String skillsString = match.group(1)!;
      List<String> skillsList = skillsString.split(',').map((e) => e.trim()).toList();
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
    return extractHourlyPay() ?? extractFixedPrice() ?? 'No budget';
  }

  String? extractHourlyPay() {
    RegExp hourlyPayRegExp = RegExp(r'<b>Hourly Range</b>:\s*(.*?)\s*<br />');
    final match = hourlyPayRegExp.firstMatch(this);

    if (match != null) {
      return '${match.group(1)!}/hr';
    } else {
      return null;
    }
  }

  String? extractFixedPrice() {
    RegExp fixedPriceRegExp = RegExp(r'<b>Budget</b>:\s*(.*?)\s*<br />');
    final match = fixedPriceRegExp.firstMatch(this);

    if (match != null) {
      return match.group(1)!;
    } else {
      return null;
    }
  }
}

extension RssFeedToString on RssFeed {
  String string() {
    return '''${describeIdentity(this)}(
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
