import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/story_model.dart';

class StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const StoryCard({
    super.key,
    required this.story,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (story.photoUrl != null && story.photoUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  story.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.outline,
                      ),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.surfaceVariant,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: AppColors.outline,
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    story.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppSizes.fontLg,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Footer
                  Row(
                    children: [
                      // Date
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.onBackground.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        story.formattedDate,
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          color: AppColors.onBackground.withValues(alpha: 0.5),
                        ),
                      ),

                      // Location indicator
                      if (story.lat != null && story.lon != null) ...[
                        const SizedBox(width: AppSizes.md),
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.onBackground.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lokasi tersedia',
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            color: AppColors.onBackground.withValues(alpha: 0.5),
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Delete button
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          iconSize: 20,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
