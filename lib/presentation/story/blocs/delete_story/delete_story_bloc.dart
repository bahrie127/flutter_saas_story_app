import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/datasources/story_remote_datasource.dart';

part 'delete_story_bloc.freezed.dart';
part 'delete_story_event.dart';
part 'delete_story_state.dart';

class DeleteStoryBloc extends Bloc<DeleteStoryEvent, DeleteStoryState> {
  final StoryRemoteDatasource _datasource;

  DeleteStoryBloc(this._datasource) : super(const _Initial()) {
    on<_DeleteStory>(_onDeleteStory);
  }

  Future<void> _onDeleteStory(
    _DeleteStory event,
    Emitter<DeleteStoryState> emit,
  ) async {
    emit(const DeleteStoryState.loading());

    final result = await _datasource.deleteStory(id: event.id);

    result.fold(
      (error) => emit(DeleteStoryState.error(error)),
      (message) => emit(DeleteStoryState.success(message)),
    );
  }
}
