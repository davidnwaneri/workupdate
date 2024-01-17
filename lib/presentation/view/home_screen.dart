import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:workupdate/data/feed_remote_data_source.dart';
import 'package:workupdate/data/network_client.dart';
import 'package:workupdate/domain/feed_info.dart';
import 'package:workupdate/domain/job_entry.dart';
import 'package:workupdate/presentation/widgets/feed_info_card.dart';
import 'package:workupdate/utils/globals.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FeedRemoteDataSource _remoteDataSource;
  late Future<void> _rssFeedFuture;
  FeedInfo? _feed;
  String? _appBarTitle;

  @override
  void initState() {
    super.initState();
    _remoteDataSource = FeedRemoteDataSource(
      networkClient: NetworkClient(dio: Dio()),
    );
    _rssFeedFuture = getFeed();
  }

  Future<void> getFeed() async {
    try {
      final feed = await _remoteDataSource.getFeed();
      _feed = feed;
    } catch (e) {
      rethrow;
    } finally {
      _setAppBarTitle(_feed?.title);
    }
  }

  Future<void> _refreshFeed() async {
    try {
      final feed = await _remoteDataSource.getFeed();
      setState(() => _feed = feed);
    } catch (e) {
      if (mounted) showSnackBar(context, message: e.toString());
    } finally {
      _setAppBarTitle(_feed?.title);
    }
  }

  void _setAppBarTitle(String? text) {
    if (text == null || text == _appBarTitle) return;
    setState(() => _appBarTitle = text);
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

  final Iterable<JobEntry> jobs;
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
