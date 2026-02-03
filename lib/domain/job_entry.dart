import 'package:rss_dart/dart_rss.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:workupdate/utils/extension_parsers.dart';

/// {@template job_entry}
/// A class that holds information about a job that was posted.
/// {@endtemplate}
@immutable
class JobEntry {
  /// Creates a new [JobEntry] instance.
  /// {@macro job_entry}
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

  /// Creates a new [JobEntry] instance from an [RssItem].
  ///
  /// This method parses the information in a given [RssItem] and converts to a [JobEntry] instance.
  factory JobEntry.fromRssItem(RssItem item) {
    return JobEntry(
      title: item.title!.removeUpworkText().removeHtmlTags(),
      description: item.description!.removeHtmlTags().extractJobDescription(),
      link: item.link!,
      country: item.description!.extractCountry(),
      publishedAt: DateFormat(
        'EEE, dd MMM yyyy HH:mm:ss Z',
      ).parseUTC(item.pubDate!).toLocal(),
      category: item.description!.extractCategory().removeHtmlTags(),
      budget: item.description!.getBudget(),
      skills: item.description!.extractSkills(),
    );
  }

  /// The title of the job.
  final String title;

  /// The description of the job.
  final String description;

  /// The link to the job post.
  final String link;

  /// The country where the job was posted from.
  ///
  /// You can also say the country of residence of the job poster/prospective client.
  final String country;

  /// The category of the job.
  ///
  /// E.g. Mobile app development, Mobile game development, etc.
  final String category;

  /// The payment information for the job.
  ///
  /// This could be a fixed budget, or a range of hourly rates.
  /// For example, `$500` or `$10-$15/hr`.
  ///
  /// This will be unavailable unable to get the payment information from the job information.
  final String budget;

  /// The Date and time the job was posted.
  ///
  /// By default, the date and time is in UTC, but it is converted to the local time zone.
  final DateTime publishedAt;

  /// The skills required for the job.
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

extension on String {
  /// Removes the '- Upwork' text from a given string.
  ///
  /// This method is used to clean up the job description by removing the '- Upwork' text that is appended at the end of the job description in the RSS feed.
  /// The method ensures that only the actual job description is returned, making it suitable for display.
  String removeUpworkText() => replaceAll('- Upwork', '');

  /// Extracts the job description from a [JobEntry].
  ///
  /// This method is called after the `removeHtmlTags()` method has parsed the HTML content.
  /// It searches for the first occurrence of 'Budget:', 'Hourly Range:', or 'Posted On:' in the string,
  /// and returns the substring from the start of the string to the index of the first occurrence.
  ///
  /// For example, given the input:
  /// ```
  /// Reports to
  /// Chief Information Officer (CIO), Chief Technology Officer (CTO)...
  /// Job Brief
  /// We are looking for an experienced Developer to join our highly skilled technical team.
  /// ...
  /// Budget: $750
  /// ```
  /// The method will return:
  /// ```
  /// Reports to
  /// Chief Information Officer (CIO), Chief Technology Officer (CTO)...
  /// Job Brief
  /// We are looking for an experienced Developer to join our highly skilled technical team.
  /// ...
  /// ```
  ///
  /// Note: This method assumes that some/all of the keywords will be present in the string.
  /// 'Budget:' is first searched for, and only if not found does it go to the next.
  ///
  /// It may appear that the payment information is been stripped from the string, but it is not exactly the case,
  /// other information appear after the payment information. It is only at this breakpoint that the actual job description ends.
  String extractJobDescription() {
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

  /// Extracts the country from a given string.
  ///
  /// This method is used to parse the job description and extract the country information.
  /// It searches for the pattern '<b>Country</b>:' in the string, and returns the substring that follows this pattern.
  /// If the pattern is not found, it returns 'Unknown location'.
  ///
  /// For example, given the input:
  /// ```
  /// <b>Country</b>: United States <br />
  /// ```
  /// The method will return 'United States'.
  String extractCountry() {
    final countryRegExp = RegExp(r'<b>Country</b>:\s*(.*?)\s*<br />');
    final match = countryRegExp.firstMatch(this);

    if (match != null) {
      return match.group(1)!;
    } else {
      return 'Unknown location';
    }
  }

  /// Extracts the category from a given string.
  ///
  /// This method extracts the category from the raw/unparsed description.
  /// It searches for the pattern '<b>Category</b>:' in the string, and returns the substring that follows this pattern.
  ///
  /// For example, given the input:
  /// ```
  /// <b>Category</b>: Mobile app development <br />
  /// ```
  /// The method will return 'Mobile app development'.
  String extractCategory() {
    final categoryRegExp = RegExp(r'<b>Category</b>:\s*(.*?)\s*<br />');
    final match = categoryRegExp.firstMatch(this);

    return match!.group(1)!;
  }

  /// Extracts the skills from a given string.
  ///
  /// This method extracts the skills from the raw/unparsed description.
  /// It searches for the pattern '<b>Skills</b>:' in the string, and returns the substring that follows this pattern.
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

  /// Extracts the budget information from a given string.
  ///
  /// This method extracts the budget from the raw/unparsed description.
  /// It first tries to extract the hourly pay rate, if it exists, in the format: '$10-$15/hr'.
  /// If the hourly pay rate does not exist, it tries to extract the fixed price, if it exists, in the format: '$500'.
  /// If neither exist, it returns 'Unavailable'.
  String getBudget() {
    return _extractHourlyPay() ?? _extractFixedPrice() ?? 'Unavailable';
  }

  String? _extractHourlyPay() {
    final hourlyPayRegExp = RegExp(r'<b>Hourly Range</b>:\s*(.*?)\s*<br />');
    final match = hourlyPayRegExp.firstMatch(this);

    if (match != null) {
      return '${match.group(1)!}/hr';
    } else {
      return null;
    }
  }

  String? _extractFixedPrice() {
    final fixedPriceRegExp = RegExp(r'<b>Budget</b>:\s*(.*?)\s*<br />');
    final match = fixedPriceRegExp.firstMatch(this);

    if (match != null) {
      return match.group(1)!;
    } else {
      return null;
    }
  }
}
