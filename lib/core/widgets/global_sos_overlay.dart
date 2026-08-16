// lib/core/widgets/global_sos_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../features/elderly/providers/elderly_provider.dart';

class GlobalSosOverlay extends ConsumerWidget {
  const GlobalSosOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elderlyState = ref.watch(elderlyProvider);
    final alert = elderlyState.activeSosAlert;

    if (!elderlyState.isSosActive || alert == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x8F000000),
        child: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _SosAlertCard(alert: alert),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SosAlertCard extends ConsumerWidget {
  const _SosAlertCard({required this.alert});

  final SosAlertData alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      label:
          'Emergency SOS from ${alert.elderlyName}. Immediate assistance requested.',
      child: Material(
        elevation: 16,
        clipBehavior: Clip.antiAlias,
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: colors.error,
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 32,
                      semanticLabel: 'Emergency warning',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency SOS',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${alert.elderlyName} needs immediate assistance.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        ref.read(elderlyProvider.notifier).resolveSOS,
                    tooltip: 'Dismiss SOS alert',
                    color: Colors.white,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        color: colors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current location',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (alert.hasLocation) ...[
                    _LocationMap(alert: alert),
                    const SizedBox(height: 12),
                    Text(
                      '${alert.latitude!.toStringAsFixed(6)}, '
                      '${alert.longitude!.toStringAsFixed(6)}'
                      '${alert.accuracy == null ? '' : '  •  ±${alert.accuracy!.round()} m'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            color: colors.onErrorContainer,
                            semanticLabel: 'Location unavailable',
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Location was unavailable. Contact the elderly person immediately.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (alert.triggeredAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Triggered at ${alert.triggeredAt}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed:
                          ref.read(elderlyProvider.notifier).resolveSOS,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.onError,
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('I have seen this alert'),
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

class _LocationMap extends StatelessWidget {
  const _LocationMap({required this.alert});

  final SosAlertData alert;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(alert.latitude!, alert.longitude!);
    final errorColor = Theme.of(context).colorScheme.error;

    return Semantics(
      label:
          'Map showing ${alert.elderlyName} at latitude ${alert.latitude!.toStringAsFixed(6)} and longitude ${alert.longitude!.toStringAsFixed(6)}.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          child: FlutterMap(
            options: MapOptions(initialCenter: point, initialZoom: 16),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.homecare_app',
              ),
              if (alert.accuracy != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: point,
                      radius: alert.accuracy!,
                      useRadiusInMeter: true,
                      color: errorColor.withOpacity(0.16),
                      borderColor: errorColor.withOpacity(0.55),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.location_pin,
                      color: errorColor,
                      size: 48,
                      semanticLabel: '${alert.elderlyName} location pin',
                    ),
                  ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
