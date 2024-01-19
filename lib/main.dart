import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workupdate/app/app.dart';
import 'package:workupdate/data/feed_remote_data_source.dart';
import 'package:workupdate/data/network_client.dart';
import 'package:workupdate/presentation/state_handler/state_handler.dart';

void main() {
  _addFontsLicense();

  runApp(
    DependencyAgent(
      remoteDataSource: FeedRemoteDataSource(
        networkClient: NetworkClient(dio: Dio()),
      ),
      child: const WorkUpdateApp(),
    ),
  );
}

void _addFontsLicense() {
  // Disable HTTP fetching of fonts at runtime
  GoogleFonts.config.allowRuntimeFetching = false;

  LicenseRegistry.addLicense(() async* {
    final inconsolataFontLicense = await rootBundle.loadString('assets/fonts/google_fonts/inconsolata/OFL.txt');

    yield LicenseEntryWithLineBreaks(['google_fonts'], inconsolataFontLicense);
  });
}
