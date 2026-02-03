import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:rss_dart/dart_rss.dart';
import 'package:rss_dart/domain/rss_content.dart';

extension RemoveHtmlTagsX on String {
  /// Removes all HTML tags from a given string.
  ///
  /// This method parses the input string as an HTML document, then extracts and returns the text content.
  /// Processes strings from RSS feed, where the HTML tags are not needed.
  /// The method ensures that only readable text content is returned, making it suitable for display.
  ///
  /// For example, given the input:
  /// ```
  /// <![CDATA[Reports to<br />
  /// Chief Information Officer (CIO), Chief Technology Officer (CTO)...<br /><br />
  /// Job Brief<br />
  /// We are looking for an experienced Developer to join our highly skilled technical team. <br /><br />
  /// ...
  /// ]]>
  /// ```
  /// The method will return:
  /// ```
  /// Reports to
  /// Chief Information Officer (CIO)...
  /// Job Brief
  /// We are looking for an experienced Developer to join our highly skilled technical team.
  /// ...
  /// ```
  String removeHtmlTags() {
    final document = parse(this);
    final parsedString = parse(document.body!.text).documentElement!.text;
    return parsedString;
  }
}

extension RssFeedToString on RssFeed {
  /// {@template string_identity}
  /// A string representation of this object.
  /// {@endtemplate}
  String stringIdentity() {
    return '''
    ${describeIdentity(this)}(
      title: $title,
      author: $author,
      description: $description,
      link: $link,
      items: ${items.map((e) => e.stringIdentity()).toList()},
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
  /// {@macro string_identity}
  String stringIdentity() {
    return '''
    ${describeIdentity(this)}(
      title: $title,
      description: $description,
      link: $link,
      categories: ${categories.map((e) => e.stringIdentity()).toList()},
      guid: $guid,
      pubDate: $pubDate,
      author: $author,
      comments: $comments,
      source: ${source?.stringIdentity()},
      content: ${content?.stringIdentity()},
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
  /// {@macro string_identity}
  String stringIdentity() {
    return '''
    ${describeIdentity(this)}(
      domain: $domain,
      value: $value,
    )
    ''';
  }
}

extension on RssSource {
  /// {@macro string_identity}
  String stringIdentity() {
    return '''
    ${describeIdentity(this)}(
      url: $url,
      value: $value,
    )
    ''';
  }
}

extension on RssContent {
  /// {@macro string_identity}
  String stringIdentity() {
    return '''
    ${describeIdentity(this)}(
      value: $value,
      images: $images,
    )
    ''';
  }
}
