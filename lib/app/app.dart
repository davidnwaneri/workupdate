import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:workupdate/app/app_theme.dart';
import 'package:workupdate/presentation/view/home_screen.dart';

class WorkUpdateApp extends StatefulWidget {
  const WorkUpdateApp({super.key});

  @override
  State<WorkUpdateApp> createState() => _WorkUpdateAppState();
}

class _WorkUpdateAppState extends State<WorkUpdateApp> {
  @override
  void initState() {
    super.initState();
    _initializeConfigurations();
  }

  Future<void> _initializeConfigurations() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Intl.defaultLocale = PlatformDispatcher.instance.locale.toLanguageTag();
    await initializeDateFormatting();
    timeago.setLocaleMessages('en', _MyCustomMessages());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workupdate',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // TODO(me): Set theme mode based on user preference
      home: const HomeScreen(),
    );
  }
}

class _MyCustomMessages extends timeago.EnMessages {
  @override
  String aboutAnHour(int minutes) => '1 hour ${minutes % 60} minutes';

  @override
  String lessThanOneMinute(int seconds) => '$seconds seconds';
}
