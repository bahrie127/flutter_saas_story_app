import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/empty_state.dart';
import '../../../core/components/error_state.dart';
import '../../../core/components/loading_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../../data/models/story_model.dart';
import '../../profile/pages/profile_page.dart';
import '../blocs/delete_story/delete_story_bloc.dart';
import '../blocs/get_stories/get_stories_bloc.dart';
import '../widgets/story_card.dart';
import 'add_story_page.dart';
import 'story_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadStories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadStories() {
    context.read<GetStoriesBloc>().add(const GetStoriesEvent.getStories());
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<GetStoriesBloc>().add(const GetStoriesEvent.loadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Story App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push(const ProfilePage());
            },
          ),
        ],
      ),
      body: BlocListener<DeleteStoryBloc, DeleteStoryState>(
        listener: (context, state) {
          state.maybeWhen(
            success: (message) {
              context.showSuccess(message);
              _loadStories();
            },
            error: (message) {
              context.showError(message);
            },
            orElse: () {},
          );
        },
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<GetStoriesBloc>().add(const GetStoriesEvent.refresh());
          },
          child: BlocBuilder<GetStoriesBloc, GetStoriesState>(
            builder: (context, state) {
              return state.maybeWhen(
                loading: () => const LoadingIndicator(),
                loaded: (stories, hasReachedMax) => _buildStoryList(
                  stories,
                  hasReachedMax,
                  isLoadingMore: false,
                ),
                loadingMore: (stories) => _buildStoryList(
                  stories,
                  false,
                  isLoadingMore: true,
                ),
                error: (message) => ErrorState(
                  message: message,
                  onRetry: _loadStories,
                ),
                orElse: () => const EmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: 'Belum ada cerita',
                  subtitle: 'Tambahkan cerita pertamamu!',
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push(const AddStoryPage());
          if (result == true) {
            _loadStories();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Cerita'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }

  Widget _buildStoryList(
    List<StoryModel> stories,
    bool hasReachedMax, {
    required bool isLoadingMore,
  }) {
    if (stories.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_stories_outlined,
        title: 'Belum ada cerita',
        subtitle: 'Tambahkan cerita pertamamu!',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: isLoadingMore ? stories.length + 1 : stories.length,
      itemBuilder: (context, index) {
        if (index >= stories.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final story = stories[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          child: StoryCard(
            story: story,
            onTap: () async {
              final result = await context.push(
                StoryDetailPage(story: story),
              );
              if (result == true) {
                _loadStories();
              }
            },
            onDelete: () => _confirmDelete(story),
          ),
        );
      },
    );
  }

  void _confirmDelete(StoryModel story) async {
    final confirmed = await context.showConfirmDialog(
      title: 'Hapus Cerita',
      message: 'Apakah Anda yakin ingin menghapus cerita ini?',
      confirmText: 'Hapus',
      confirmColor: AppColors.error,
    );

    if (confirmed == true && mounted) {
      context.read<DeleteStoryBloc>().add(
            DeleteStoryEvent.deleteStory(id: story.id),
          );
    }
  }
}
