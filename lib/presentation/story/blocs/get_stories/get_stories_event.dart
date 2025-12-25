part of 'get_stories_bloc.dart';

@freezed
sealed class GetStoriesEvent with _$GetStoriesEvent {
  const factory GetStoriesEvent.getStories() = _GetStories;
  const factory GetStoriesEvent.loadMore() = _LoadMore;
  const factory GetStoriesEvent.refresh() = _Refresh;
}
