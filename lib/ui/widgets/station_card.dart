import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_station/models/station.dart';
import 'package:open_station/services/audio_player_service.dart';
import 'package:open_station/services/bookmark_service.dart';
import 'package:open_station/theme/app_theme.dart';
import 'package:open_station/ui/widgets/station_artwork.dart';

class StationCard extends StatelessWidget {
  final Station station;

  const StationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<AudioPlayerService>();
    final bookmarkService = context.watch<BookmarkService>();

    final isCurrentStation = playerService.currentStation?.uuid == station.uuid;
    final isPlaying =
        isCurrentStation && playerService.state == AudioPlayerState.playing;
    final isConnecting =
        isCurrentStation && playerService.state == AudioPlayerState.connecting;
    final isPaused =
        isCurrentStation && playerService.state == AudioPlayerState.paused;
    final isFailed =
        isCurrentStation && playerService.state == AudioPlayerState.failed;
    final isBookmarked = bookmarkService.isBookmarked(station.uuid);

    final String playbackTooltip;
    final IconData playbackIcon;
    if (isConnecting) {
      playbackTooltip = 'Connecting to ${station.name}';
      playbackIcon = Icons.hourglass_top;
    } else if (isPlaying) {
      playbackTooltip = 'Pause ${station.name}';
      playbackIcon = Icons.pause_circle_filled;
    } else if (isPaused) {
      playbackTooltip = 'Resume ${station.name}';
      playbackIcon = Icons.play_circle_filled;
    } else if (isFailed) {
      playbackTooltip = 'Retry ${station.name}';
      playbackIcon = Icons.refresh;
    } else {
      playbackTooltip = 'Play ${station.name}';
      playbackIcon = Icons.play_circle_filled;
    }

    return Card(
      color: isCurrentStation ? AppColors.raisedSlate : AppColors.slateSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCurrentStation ? AppColors.openGreen : AppColors.softDivider,
          width: isCurrentStation ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          context.read<AudioPlayerService>().playStation(station);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              StationArtwork(faviconUrl: station.faviconUrl, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      station.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isCurrentStation
                            ? AppColors.openGreen
                            : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (station.codec != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.raisedSlate,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.softDivider),
                            ),
                            child: Text(
                              '${station.codec}${station.bitrate != null ? ' ${station.bitrate}k' : ''}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (station.tags.isNotEmpty)
                          Flexible(
                            child: Text(
                              station.tags.take(2).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.favorite : Icons.favorite_border,
                      color: isBookmarked
                          ? AppColors.openGreen
                          : AppColors.mutedText,
                    ),
                    onPressed: () {
                      context.read<BookmarkService>().toggleBookmark(station);
                    },
                    tooltip: isBookmarked
                        ? 'Remove ${station.name} from bookmarks'
                        : 'Add ${station.name} to bookmarks',
                  ),
                  IconButton(
                    icon: isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.connectingBlue,
                            ),
                          )
                        : Icon(
                            playbackIcon,
                            color: isCurrentStation
                                ? AppColors.openGreen
                                : AppColors.signalBlue,
                            size: 32,
                          ),
                    onPressed: isConnecting
                        ? null
                        : () {
                            if (isPlaying) {
                              context.read<AudioPlayerService>().pause();
                            } else if (isPaused) {
                              context.read<AudioPlayerService>().resume();
                            } else {
                              context.read<AudioPlayerService>().playStation(
                                station,
                              );
                            }
                          },
                    tooltip: playbackTooltip,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
