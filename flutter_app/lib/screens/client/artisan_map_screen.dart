import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';
import 'artisan_profile_screen.dart';

class ArtisanMapScreen extends StatefulWidget {
  const ArtisanMapScreen({super.key});

  @override
  State<ArtisanMapScreen> createState() => _ArtisanMapScreenState();
}

class _ArtisanMapScreenState extends State<ArtisanMapScreen> {
  final _api = Get.find<ApiService>();
  final _mapController = MapController();
  List<Map<String, dynamic>> _artisans = [];
  Map<String, dynamic>? _selected;
  bool _loading = true;

  // Algeria center
  static const _defaultCenter = LatLng(28.0339, 1.6596);
  static const _defaultZoom = 5.0;

  // Get Mapbox token from environment variables
  String get _mapboxToken => dotenv.env['MAPBOX_TOKEN'] ?? '';
  static const _mapboxStyle = 'mapbox/streets-v12';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/artisans/map');
      setState(() {
        _artisans = List<Map<String, dynamic>>.from(res.data['artisans'] ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error if token is missing
    if (_mapboxToken.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('خريطة الحرفيين')),
        body: const Center(
          child: Text('Mapbox token not configured. Please check .env file'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('خريطة الحرفيين',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_artisans.length} حرفي',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                _buildMap(),
                if (_selected != null) _buildBottomCard(),
              ],
            ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _artisans.isNotEmpty
            ? LatLng(
                double.parse(_artisans.first['latitude'].toString()),
                double.parse(_artisans.first['longitude'].toString()),
              )
            : _defaultCenter,
        initialZoom: _artisans.isNotEmpty ? 6.0 : _defaultZoom,
        onTap: (_, __) => setState(() => _selected = null),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/{style}/tiles/{z}/{x}/{y}?access_token={accessToken}',
          additionalOptions: {
            'style': _mapboxStyle,
            'accessToken': _mapboxToken,
          },
          userAgentPackageName: 'com.naamaya.app',
        ),
        MarkerLayer(
          markers: _artisans.map((a) {
            final lat = double.tryParse(a['latitude'].toString()) ?? 0;
            final lng = double.tryParse(a['longitude'].toString()) ?? 0;
            final isSelected = _selected?['id'] == a['id'];
            final isSponsored = (a['is_sponsored'] ?? 0) == 1;

            return Marker(
              point: LatLng(lat, lng),
              width: isSelected ? 56 : 44,
              height: isSelected ? 56 : 44,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selected = a);
                  _mapController.move(LatLng(lat, lng), 10);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSponsored
                        ? AppColors.accent
                        : isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isSelected ? AppColors.primary : Colors.black)
                            .withOpacity(0.2),
                        blurRadius: isSelected ? 12 : 4,
                        spreadRadius: isSelected ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _badgeEmoji(a['badge']),
                      style: TextStyle(fontSize: isSelected ? 22 : 18),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomCard() {
    final a = _selected!;
    final badge = a['badge'] ?? 'new';
    final rating = double.tryParse(a['avg_rating'].toString()) ?? 0.0;
    final isSponsored = (a['is_sponsored'] ?? 0) == 1;

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isSponsored
                      ? AppColors.accentLight
                      : AppColors.primaryLight,
                  child: Text(
                    (a['name'] ?? 'ح')[0],
                    style: TextStyle(
                      color:
                          isSponsored ? AppColors.sponsored : AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(
                          a['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (isSponsored) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('ممول',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.sponsored,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                      Text(
                        a['craft_type'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildBadgeChip(badge),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(a['location'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                const Icon(Icons.star, size: 14, color: AppColors.accent),
                const SizedBox(width: 3),
                Text(rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                const Icon(Icons.shopping_bag_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text('${a['total_sales']} مبيعة',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.to(() => ArtisanProfileScreen(
                      artisanId: a['id'],
                      artisanName: a['name'] ?? '',
                    )),
                child: const Text('عرض الملف الشخصي',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String badge) {
    final isGold = badge == 'gold';
    final isSilver = badge == 'silver';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGold
            ? AppColors.accentLight
            : isSilver
                ? Colors.grey.shade100
                : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isGold
            ? '★ ذهبي'
            : isSilver
                ? '◆ فضي'
                : '✦ جديد',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isGold
              ? AppColors.gold
              : isSilver
                  ? AppColors.silver
                  : AppColors.primary,
        ),
      ),
    );
  }

  String _badgeEmoji(dynamic badge) {
    switch (badge) {
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      default:
        return '🏺';
    }
  }
}
