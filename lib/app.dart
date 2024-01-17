import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
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
    timeago.setLocaleMessages('en', _MyCustomMessages());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workupdate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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
