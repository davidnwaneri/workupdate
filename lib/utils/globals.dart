import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

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

String formatTimeAgo(DateTime time) => timeago.format(time);
