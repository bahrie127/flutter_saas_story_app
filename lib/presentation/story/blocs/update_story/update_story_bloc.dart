import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/datasources/story_remote_datasource.dart';
import '../../../../data/models/story_model.dart';

part 'update_story_bloc.freezed.dart';
part 'update_story_event.dart';
part 'update_story_state.dart';

class UpdateStoryBloc extends Bloc<UpdateStoryEvent, UpdateStoryState> {
  final StoryRemoteDatasource _datasource;

  UpdateStoryBloc(this._datasource) : super(const _Initial()) {
    on<_UpdateStory>(_onUpdateStory);
  }

  Future<void> _onUpdateStory(
    _UpdateStory event,
    Emitter<UpdateStoryState> emit,
  ) async {
    emit(const UpdateStoryState.loading());

    final result = await _datasource.updateStory(
      id: event.id,
      description: event.description,
      image: event.image,
      lat: event.lat,
      lon: event.lon,
    );

    result.fold(
      (error) => emit(UpdateStoryState.error(error)),
      (story) => emit(UpdateStoryState.success(story)),
    );
  }
}
