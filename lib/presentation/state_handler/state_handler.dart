import 'package:flutter/material.dart';
import 'package:workupdate/data/feed_remote_data_source.dart';

/// {@template dependency_agent}
/// An inherited widget that provides access to the `FeedRemoteDataSource` instance.
///
/// This class is used to propagate the `FeedRemoteDataSource` instance down the widget tree.
/// It allows widgets to access the `FeedRemoteDataSource` without having to manually pass it around.
///
/// The `of` method is used to retrieve the `DependencyAgent` from the current context. It supports both listening and read access.
/// {@endtemplate}
class DependencyAgent extends InheritedWidget {
  /// Creates a new [DependencyAgent] instance.
  ///
  /// {@macro dependency_agent}
  const DependencyAgent({
    required this.remoteDataSource,
    required super.child,
    super.key,
  });

  final FeedRemoteDataSource remoteDataSource;

  @override
  bool updateShouldNotify(covariant DependencyAgent oldWidget) {
    return oldWidget.remoteDataSource != remoteDataSource;
  }

  /// Returns the [DependencyAgent] instance from the current context.
  ///
  /// If [listen] is `true`, dependent will be rebuilt whenever the [DependencyAgent] changes,
  /// according to the conditions specified in `updateShouldNotify`.
  static DependencyAgent of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<DependencyAgent>()!;
    } else {
      return context.getInheritedWidgetOfExactType<DependencyAgent>()!;
    }
  }
}
