import 'package:flutter/material.dart';
import 'package:open_station/theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  'About Open Station',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'A local-first desktop internet radio app built around a simple Discover, Play, Bookmark, and Play Again loop.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const _InfoSection(
                icon: Icons.shield_outlined,
                title: 'Privacy at a glance',
                items: [
                  'Open Station requires no account and includes no advertising.',
                  'The app includes no app-specific analytics and does not use cloud synchronization.',
                  'Bookmarks, Recently Played, and volume settings are stored locally on this computer.',
                ],
              ),
              const SizedBox(height: 16),
              const _InfoSection(
                icon: Icons.language,
                title: 'Network connections',
                items: [
                  'Station searches contact the Radio Browser directory.',
                  'Audio connects directly to the selected station rather than passing through an Open Station server.',
                  'Radio Browser servers, selected stations, station-artwork hosts, and network providers may receive your IP address and other connection information.',
                  'Listening is not anonymous.',
                  'Open Station does not send Radio Browser click-count notifications.',
                ],
              ),
              const SizedBox(height: 16),
              const _InfoSection(
                icon: Icons.graphic_eq,
                title: 'Now-playing information',
                items: [
                  'Song, show, or other now-playing text is displayed only when the active station stream supplies it.',
                  'Open Station does not use third-party metadata enrichment, lyrics, or cloud listening-history services. Station artwork may be downloaded directly from the favicon URL supplied by Radio Browser.',
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Open Station v0.1.0 MVP',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.openGreen, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.signalBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
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
