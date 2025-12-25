part of 'delete_story_bloc.dart';

@freezed
sealed class DeleteStoryEvent with _$DeleteStoryEvent {
  const factory DeleteStoryEvent.deleteStory({
    required int id,
  }) = _DeleteStory;
}
