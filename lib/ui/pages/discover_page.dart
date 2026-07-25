import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_station/controllers/directory_controller.dart';
import 'package:open_station/theme/app_theme.dart';
import 'package:open_station/ui/widgets/station_card.dart';
import 'package:open_station/services/recent_stations_service.dart';
import 'package:open_station/models/station.dart';

const List<String> popularTags = [
  'jazz',
  'classical',
  'news',
  'pop',
  'rock',
  'ambient',
  'electronic',
  'chillout',
  '80s',
];

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<DirectoryController>();
      if (controller.stations.isEmpty && !controller.isLoading) {
        controller.loadPopularStations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DirectoryController>();
    final recentService = context.watch<RecentStationsService>();
    final recentStations = recentService.recentStations;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          const Text(
            'Discover Radio Stations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) {
              controller.onSearchChanged(val);
            },
            style: const TextStyle(color: AppColors.primaryText),
            decoration: InputDecoration(
              hintText: 'Search by station name or genre...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        controller.onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Tag Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Popular'),
                  selected:
                      controller.selectedTag == null &&
                      controller.searchQuery.isEmpty,
                  onSelected: (_) {
                    _searchController.clear();
                    controller.loadPopularStations();
                  },
                ),
                const SizedBox(width: 8),
                ...popularTags.map((tag) {
                  final isSelected = controller.selectedTag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text('#$tag'),
                      selected: isSelected,
                      onSelected: (_) {
                        _searchController.clear();
                        controller.selectTag(tag);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Recently Played Section
          _buildRecentStations(recentStations),

          // Main Body Content (Grid, Loading, or Error)
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  Widget _buildBody(DirectoryController controller) {
    if (controller.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.openGreen),
            SizedBox(height: 16),
            Text(
              'Fetching Radio Directory...',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Card(
          color: AppColors.slateSurface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                const Text(
                  'Directory Offline / Network Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.retry(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.signalBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller.stations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.mutedText),
            SizedBox(height: 12),
            Text(
              'No stations found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try searching with a different station name or tag.',
              style: TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 360).floor().clamp(1, 4);
        return GridView.builder(
          itemCount: controller.stations.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final station = controller.stations[index];
            return StationCard(station: station);
          },
        );
      },
    );
  }

  Widget _buildRecentStations(List<Station> recentStations) {
    if (recentStations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recently Played',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100, // Matching aspect ratio for 320 width
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentStations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 320,
                child: StationCard(station: recentStations[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
