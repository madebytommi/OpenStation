import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_station/services/audio_player_service.dart';
import 'package:open_station/services/bookmark_service.dart';
import 'package:open_station/theme/app_theme.dart';
import 'package:open_station/ui/widgets/station_artwork.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<AudioPlayerService>();
    final bookmarkService = context.watch<BookmarkService>();

    final currentStation = playerService.currentStation;
    final state = playerService.state;
    final isPlaying = state == AudioPlayerState.playing;
    final isConnecting = state == AudioPlayerState.connecting;
    final isFailed = state == AudioPlayerState.failed;
    final isBookmarked =
        currentStation != null &&
        bookmarkService.isBookmarked(currentStation.uuid);

    final stationName = currentStation?.name ?? 'station';
    final String mainControlTooltip;
    final IconData mainControlIcon;
    if (isPlaying) {
      mainControlTooltip = 'Pause $stationName';
      mainControlIcon = Icons.pause;
    } else if (state == AudioPlayerState.paused) {
      mainControlTooltip = 'Resume $stationName';
      mainControlIcon = Icons.play_arrow;
    } else if (isFailed) {
      mainControlTooltip = 'Retry $stationName';
      mainControlIcon = Icons.refresh;
    } else {
      mainControlTooltip = 'Play $stationName';
      mainControlIcon = Icons.play_arrow;
    }

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.slateSurface,
        border: Border(top: BorderSide(color: AppColors.softDivider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: currentStation != null
                ? Row(
                    children: [
                      StationArtwork(
                        faviconUrl: currentStation.faviconUrl,
                        size: 52,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStation.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ValueListenableBuilder<String?>(
                              valueListenable: playerService.currentMetadata,
                              builder: (context, metadata, child) {
                                final hasMetadata =
                                    metadata != null && metadata.isNotEmpty;
                                final String subtitleText;

                                if (isFailed) {
                                  subtitleText = playerService.lastError.isNotEmpty
                                      ? playerService.lastError
                                      : 'Playback failed';
                                } else if (hasMetadata) {
                                  subtitleText = metadata;
                                } else {
                                  subtitleText =
                                      currentStation.countryCode ??
                                      currentStation.tags.take(2).join(', ');
                                }

                                if (subtitleText.isEmpty && !isFailed) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    subtitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color: isFailed
                                              ? AppColors.error
                                              : AppColors.secondaryText,
                                          fontWeight: isFailed
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ) ??
                                        TextStyle(
                                          color: isFailed
                                              ? AppColors.error
                                              : AppColors.secondaryText,
                                          fontSize: 12,
                                          fontWeight: isFailed
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.favorite : Icons.favorite_border,
                          color: isBookmarked
                              ? AppColors.openGreen
                              : AppColors.mutedText,
                        ),
                        onPressed: () {
                          bookmarkService.toggleBookmark(currentStation);
                        },
                        tooltip: isBookmarked
                            ? 'Remove ${currentStation.name} from bookmarks'
                            : 'Add ${currentStation.name} to bookmarks',
                      ),
                    ],
                  )
                : const Row(
                    children: [
                      Icon(Icons.radio, color: AppColors.mutedText, size: 36),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No station selected',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.stop, color: AppColors.secondaryText),
                  onPressed:
                      currentStation != null &&
                          state != AudioPlayerState.stopped
                      ? playerService.stop
                      : null,
                  tooltip: 'Stop playback',
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.openGreen,
                    shape: BoxShape.circle,
                  ),
                  child: isConnecting
                      ? Semantics(
                          label: 'Connecting to $stationName',
                          liveRegion: true,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            mainControlIcon,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: mainControlTooltip,
                          onPressed: currentStation == null
                              ? null
                              : () {
                                  if (isPlaying) {
                                    playerService.pause();
                                  } else if (
                                      state == AudioPlayerState.paused) {
                                    playerService.resume();
                                  } else {
                                    playerService.playStation(currentStation);
                                  }
                                },
                        ),
                ),
                const SizedBox(width: 16),
                _buildStatusBadge(state),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    playerService.volume == 0
                        ? Icons.volume_off
                        : (playerService.volume < 0.5
                              ? Icons.volume_down
                              : Icons.volume_up),
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                  tooltip: playerService.volume == 0 ? 'Unmute' : 'Mute',
                  onPressed: () {
                    if (playerService.volume > 0) {
                      playerService.setVolume(0);
                    } else {
                      playerService.setVolume(1.0);
                    }
                  },
                ),
                SizedBox(
                  width: 120,
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.signalBlue,
                      inactiveTrackColor: AppColors.raisedSlate,
                      thumbColor: AppColors.primaryText,
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: playerService.volume,
                      semanticFormatterCallback: (value) =>
                          'Volume ${(value * 100).round()} percent',
                      onChanged: (value) {
                        playerService.setVolume(value);
                        bookmarkService.setVolume(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AudioPlayerState state) {
    Color badgeColor;
    String label;

    switch (state) {
      case AudioPlayerState.playing:
        badgeColor = AppColors.openGreen;
        label = 'PLAYING';
        break;
      case AudioPlayerState.connecting:
        badgeColor = AppColors.connectingBlue;
        label = 'CONNECTING';
        break;
      case AudioPlayerState.paused:
        badgeColor = AppColors.signalBlue;
        label = 'PAUSED';
        break;
      case AudioPlayerState.stopped:
        badgeColor = AppColors.disabledText;
        label = 'STOPPED';
        break;
      case AudioPlayerState.failed:
        badgeColor = AppColors.error;
        label = 'FAILED';
        break;
      case AudioPlayerState.idle:
        badgeColor = AppColors.disabledText;
        label = 'IDLE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
