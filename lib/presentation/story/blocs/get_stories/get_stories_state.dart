part of 'get_stories_bloc.dart';

@freezed
sealed class GetStoriesState with _$GetStoriesState {
  const factory GetStoriesState.initial() = _Initial;
  const factory GetStoriesState.loading() = _Loading;
  const factory GetStoriesState.loaded({
    required List<StoryModel> stories,
    required bool hasReachedMax,
  }) = _Loaded;
  const factory GetStoriesState.loadingMore({
    required List<StoryModel> stories,
  }) = _LoadingMore;
  const factory GetStoriesState.error(String message) = _Error;
}
