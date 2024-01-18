import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:workupdate/app.dart';
import 'package:workupdate/data/feed_remote_data_source.dart';
import 'package:workupdate/data/network_client.dart';
import 'package:workupdate/presentation/state_handler/state_handler.dart';

void main() {
  runApp(
    DependencyAgent(
      remoteDataSource: FeedRemoteDataSource(
        networkClient: NetworkClient(dio: Dio()),
      ),
      child: const WorkUpdateApp(),
    ),
  );
}
