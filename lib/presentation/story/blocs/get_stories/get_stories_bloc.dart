import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/datasources/story_remote_datasource.dart';
import '../../../../data/models/story_model.dart';

part 'get_stories_bloc.freezed.dart';
part 'get_stories_event.dart';
part 'get_stories_state.dart';

class GetStoriesBloc extends Bloc<GetStoriesEvent, GetStoriesState> {
  final StoryRemoteDatasource _datasource;

  GetStoriesBloc(this._datasource) : super(const _Initial()) {
    on<_GetStories>(_onGetStories);
    on<_LoadMore>(_onLoadMore);
    on<_Refresh>(_onRefresh);
  }

  int _currentPage = 1;
  bool _hasReachedMax = false;
  List<StoryModel> _stories = [];

  Future<void> _onGetStories(
    _GetStories event,
    Emitter<GetStoriesState> emit,
  ) async {
    emit(const GetStoriesState.loading());

    _currentPage = 1;
    _hasReachedMax = false;
    _stories = [];

    final result = await _datasource.getMyStories(page: _currentPage);

    result.fold(
      (error) => emit(GetStoriesState.error(error)),
      (response) {
        _stories = response.data;
        _hasReachedMax = response.currentPage >= response.lastPage;
        emit(GetStoriesState.loaded(
          stories: _stories,
          hasReachedMax: _hasReachedMax,
        ));
      },
    );
  }

  Future<void> _onLoadMore(
    _LoadMore event,
    Emitter<GetStoriesState> emit,
  ) async {
    if (_hasReachedMax) return;

    emit(GetStoriesState.loadingMore(stories: _stories));

    _currentPage++;
    final result = await _datasource.getMyStories(page: _currentPage);

    result.fold(
      (error) {
        _currentPage--;
        emit(GetStoriesState.error(error));
      },
      (response) {
        _stories = [..._stories, ...response.data];
        _hasReachedMax = response.currentPage >= response.lastPage;
        emit(GetStoriesState.loaded(
          stories: _stories,
          hasReachedMax: _hasReachedMax,
        ));
      },
    );
  }

  Future<void> _onRefresh(
    _Refresh event,
    Emitter<GetStoriesState> emit,
  ) async {
    _currentPage = 1;
    _hasReachedMax = false;
    _stories = [];

    final result = await _datasource.getMyStories(page: _currentPage);

    result.fold(
      (error) => emit(GetStoriesState.error(error)),
      (response) {
        _stories = response.data;
        _hasReachedMax = response.currentPage >= response.lastPage;
        emit(GetStoriesState.loaded(
          stories: _stories,
          hasReachedMax: _hasReachedMax,
        ));
      },
    );
  }
}
