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
          const Text(
            'Discover Radio Stations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: controller.onSearchChanged,
            style: const TextStyle(color: AppColors.primaryText),
            decoration: InputDecoration(
              hintText: 'Search by station name or genre...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        controller.onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
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
          _buildRecentStations(recentStations),
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  Widget _buildBody(DirectoryController controller) {
    final hasStations = controller.stations.isNotEmpty;

    if (controller.isLoading && !hasStations) {
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

    if (controller.errorMessage != null && !hasStations) {
      return _buildFullError(controller);
    }

    if (!hasStations) {
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

    final stationCollection = _buildStationCollection(controller);
    if (!controller.isLoading && controller.errorMessage == null) {
      return stationCollection;
    }

    return Column(
      children: [
        if (controller.isLoading)
          const LinearProgressIndicator(
            minHeight: 3,
            color: AppColors.openGreen,
            backgroundColor: AppColors.raisedSlate,
          ),
        if (controller.errorMessage != null) ...[
          _buildInlineError(controller),
          const SizedBox(height: 12),
        ],
        Expanded(child: stationCollection),
      ],
    );
  }

  Widget _buildFullError(DirectoryController controller) {
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
                'Station directory unavailable',
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
                onPressed: controller.retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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

  Widget _buildInlineError(DirectoryController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search failed. Previous results are still shown.',
              style: const TextStyle(color: AppColors.primaryText),
            ),
          ),
          TextButton.icon(
            onPressed: controller.retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCollection(DirectoryController controller) {
    final isSearchResults =
        controller.searchQuery.trim().isNotEmpty ||
        controller.selectedTag != null;

    if (isSearchResults) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results · ${controller.stations.length}',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('search-results-list'),
              itemCount: controller.stations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return StationCard(station: controller.stations[index]);
              },
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 360).floor().clamp(1, 4);
        return GridView.builder(
          key: const ValueKey('popular-stations-grid'),
          itemCount: controller.stations.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return StationCard(station: controller.stations[index]);
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
          height: 100,
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
