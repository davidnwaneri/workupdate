import 'package:dart_rss/dart_rss.dart';
import 'package:dart_rss/domain/rss_content.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';

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
