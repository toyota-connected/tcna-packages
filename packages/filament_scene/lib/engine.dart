import 'dart:collection';

import 'package:filament_scene/generated/messages.g.dart';

Queue<Future<void>> _asyncTasks = Queue<Future<void>>();

extension FilamentEngine on FilamentViewApi {
  /*
   *  Async task handling
   */
  void queueFrameTask(final Future<void>? task) {
    if (task != null) {
      _asyncTasks.add(task);
    }
  }

  /// Queues a list of async tasks to be executed in parallel
  /// and awaited before the next frame.
  /// Ignores any errors and executes all tasks regardless of individual failures.
  void queueFrameTasksParallel(final List<Future<dynamic>> tasks) {
    final Future<List<void>> parallelTask = Future.wait(tasks);
    _asyncTasks.add(parallelTask);
  }

  /// Queues a list of async tasks to be executed in series after each other
  /// and awaited before the next frame.
  /// Ignores any errors and continues with the next task.
  void queueFrameTasksSeries(final List<Future<dynamic>> tasks) {
    final Future seriesTask = Future.forEach(tasks, (final task) async {
      try {
        await task;
      }
      // ignore: avoid_catches_without_on_clauses
      catch (e) {
        // Handle any errors that occur during the task execution
        print('Error executing task: $e');
      }
    });

    _asyncTasks.add(seriesTask);
  }

  /// Executes all queued async tasks and waits for their completion.
  /// Ignores any errors and executes all tasks regardless of individual failures.
  Future<void> drainFrameTasks() async {
    // Await all tasks in parallel
    try {
      await Future.wait(_asyncTasks);
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      // Handle any errors that occur during the task execution
      print('Error executing queued tasks: $e');
    }

    // Clear the queue after execution
    _asyncTasks.clear();
  }
}
