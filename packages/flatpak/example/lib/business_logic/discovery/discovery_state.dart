import 'package:equatable/equatable.dart';
import '../../data/models/application_model.dart';

abstract class DiscoveryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiscoveryInitial extends DiscoveryState {}

class DiscoveryLoading extends DiscoveryState {
  final String? category;
  DiscoveryLoading({this.category});
  @override
  List<Object?> get props => [category];
}

class DiscoveryLoaded extends DiscoveryState {
  final Map<String, List<Application>> categoryApps;
  final List<String> availableRemotes;

  DiscoveryLoaded({required this.categoryApps, required this.availableRemotes});

  @override
  List<Object?> get props => [categoryApps, availableRemotes];
}

class DiscoverySearchResults extends DiscoveryState {
  final List<Application> results;
  final String query;
  final bool isSearching;

  DiscoverySearchResults({
    required this.results,
    required this.query,
    this.isSearching = false,
  });

  @override
  List<Object?> get props => [results, query, isSearching];
}

class DiscoveryError extends DiscoveryState {
  final String message;
  DiscoveryError(this.message);
  @override
  List<Object?> get props => [message];
}
