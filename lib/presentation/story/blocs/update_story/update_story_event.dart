part of 'update_story_bloc.dart';

@freezed
sealed class UpdateStoryEvent with _$UpdateStoryEvent {
  const factory UpdateStoryEvent.updateStory({
    required int id,
    required String description,
    File? image,
    double? lat,
    double? lon,
  }) = _UpdateStory;
}
