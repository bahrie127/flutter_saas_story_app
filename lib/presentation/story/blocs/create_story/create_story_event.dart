part of 'create_story_bloc.dart';

@freezed
sealed class CreateStoryEvent with _$CreateStoryEvent {
  const factory CreateStoryEvent.createStory({
    required String description,
    required File image,
    double? lat,
    double? lon,
  }) = _CreateStory;
}
