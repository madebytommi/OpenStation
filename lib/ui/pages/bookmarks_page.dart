import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_station/services/bookmark_service.dart';
import 'package:open_station/theme/app_theme.dart';
import 'package:open_station/ui/widgets/station_card.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkService>().bookmarks;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title & Subtitle
          Row(
            children: [
              const Text(
                'My Bookmarked Stations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.openGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.openGreen),
                ),
                child: Text(
                  '${bookmarks.length} SAVED',
                  style: const TextStyle(
                    color: AppColors.openGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Bookmarks are stored locally on your PC and remain accessible offline.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Main Content View
          Expanded(
            child: bookmarks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 56, color: AppColors.mutedText),
                        SizedBox(height: 16),
                        Text(
                          'No Bookmarks Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Explore the Discover tab and click the heart icon on any station to save it here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = (constraints.maxWidth / 360).floor().clamp(1, 4);
                      return GridView.builder(
                        itemCount: bookmarks.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 3.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder: (context, index) {
                          final station = bookmarks[index];
                          return StationCard(station: station);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
