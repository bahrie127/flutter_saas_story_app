import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../../data/models/story_model.dart';
import '../blocs/delete_story/delete_story_bloc.dart';
import 'edit_story_page.dart';

class StoryDetailPage extends StatelessWidget {
  final StoryModel story;

  const StoryDetailPage({
    super.key,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<DeleteStoryBloc, DeleteStoryState>(
        listener: (context, state) {
          state.maybeWhen(
            success: (message) {
              context.showSuccess(message);
              context.pop(true);
            },
            error: (message) {
              context.showError(message);
            },
            orElse: () {},
          );
        },
        child: CustomScrollView(
          slivers: [
            // App Bar with Image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () async {
                      final result = await context.push(
                        EditStoryPage(story: story),
                      );
                      if (result == true && context.mounted) {
                        context.pop(true);
                      }
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: story.photoUrl != null
                    ? Image.network(
                        story.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: AppColors.outline,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: AppColors.onBackground.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          story.formattedDate,
                          style: TextStyle(
                            fontSize: AppSizes.fontMd,
                            color: AppColors.onBackground.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Description
                    Text(
                      story.description ?? '',
                      style: const TextStyle(
                        fontSize: AppSizes.fontLg,
                        height: 1.6,
                      ),
                    ),

                    // Location
                    if (story.lat != null && story.lon != null) ...[
                      const SizedBox(height: AppSizes.xl),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lokasi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Lat: ${story.lat}, Lon: ${story.lon}',
                                    style: TextStyle(
                                      fontSize: AppSizes.fontSm,
                                      color:
                                          AppColors.onBackground.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await context.showConfirmDialog(
      title: 'Hapus Cerita',
      message: 'Apakah Anda yakin ingin menghapus cerita ini?',
      confirmText: 'Hapus',
      confirmColor: AppColors.error,
    );

    if (confirmed == true && context.mounted) {
      context.read<DeleteStoryBloc>().add(
            DeleteStoryEvent.deleteStory(id: story.id),
          );
    }
  }
}
