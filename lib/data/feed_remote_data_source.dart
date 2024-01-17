import 'package:dart_rss/dart_rss.dart';
import 'package:workupdate/data/network_client.dart';
import 'package:workupdate/data/network_client_exception.dart';
import 'package:workupdate/domain/feed_info.dart';

class FeedRemoteDataSource {
  FeedRemoteDataSource({
    required NetworkClient networkClient,
  }) : _networkClient = networkClient;

  final NetworkClient _networkClient;

  Future<FeedInfo> getFeed() async {
    try {
      final xmlString = await _getXmlString();
      final rssFeed = RssFeed.parse(xmlString);

      final feed = FeedInfo.fromRssFeed(rssFeed);
      return feed;
    } on NetworkClientException {
      rethrow;
    }
  }

  Future<String> _getXmlString() async {
    const pageIndex = 0;
    const pageSize = 10;
    try {
      final res = await _networkClient.get(
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
    } on NetworkClientException {
      rethrow;
    }
  }
}
