part of 'create_story_bloc.dart';

@freezed
sealed class CreateStoryState with _$CreateStoryState {
  const factory CreateStoryState.initial() = _Initial;
  const factory CreateStoryState.loading() = _Loading;
  const factory CreateStoryState.success(StoryModel story) = _Success;
  const factory CreateStoryState.error(String message) = _Error;
}
