import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/datasources/story_remote_datasource.dart';
import '../../../../data/models/story_model.dart';

part 'create_story_bloc.freezed.dart';
part 'create_story_event.dart';
part 'create_story_state.dart';

class CreateStoryBloc extends Bloc<CreateStoryEvent, CreateStoryState> {
  final StoryRemoteDatasource _datasource;

  CreateStoryBloc(this._datasource) : super(const _Initial()) {
    on<_CreateStory>(_onCreateStory);
  }

  Future<void> _onCreateStory(
    _CreateStory event,
    Emitter<CreateStoryState> emit,
  ) async {
    emit(const CreateStoryState.loading());

    final result = await _datasource.createStory(
      description: event.description,
      image: event.image,
      lat: event.lat,
      lon: event.lon,
    );

    result.fold(
      (error) => emit(CreateStoryState.error(error)),
      (story) => emit(CreateStoryState.success(story)),
    );
  }
}
