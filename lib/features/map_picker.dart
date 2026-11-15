import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

/// اختيار موقع المحل: حرّك الخريطة لين يصير الدبوس على المحل ثم «تأكيد الموقع»
/// يرجع (خط العرض، خط الطول) أو null عند الإلغاء
class MapPickerScreen extends StatefulWidget {
  final double? lat, lng;
  const MapPickerScreen({super.key, this.lat, this.lng});

  static Future<LatLng?> open(BuildContext context, {double? lat, double? lng}) =>
      Navigator.of(context).push<LatLng>(MaterialPageRoute(builder: (_) => MapPickerScreen(lat: lat, lng: lng)));

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final map = MapController();
  late LatLng center = LatLng(widget.lat ?? 24.7136, widget.lng ?? 46.6753); // الرياض افتراضياً
  List<(String, LatLng)> results = [];
  bool searching = false;
  Timer? debounce;

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  /// البحث عن مكان (OpenStreetMap — داخل السعودية)
  void _search(String q) {
    debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => results = []);
      return;
    }
    debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => searching = true);
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', {'q': q.trim(), 'format': 'json', 'countrycodes': 'sa', 'limit': '6', 'accept-language': 'ar'});
        final r = await http.get(uri, headers: {'User-Agent': 'qitaat-app/1.0 (support@qitaat.app)'});
        final list = (jsonDecode(r.body) as List).cast<Map>();
        if (!mounted) return;
        setState(() => results = [
              for (final e in list) ('${e['display_name']}', LatLng(double.parse('${e['lat']}'), double.parse('${e['lon']}'))),
            ]);
      } catch (_) {
        if (mounted) setState(() => results = []);
      } finally {
        if (mounted) setState(() => searching = false);
      }
    });
  }

  void _go(LatLng p) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      center = p;
      results = [];
    });
    map.move(p, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        FlutterMap(
          mapController: map,
          options: MapOptions(
            initialCenter: center,
            initialZoom: widget.lat != null ? 16 : 11,
            onPositionChanged: (pos, _) => center = pos.center,
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'sa.almubarky.qitaat'),
            const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap')]),
          ],
        ),
        // الدبوس ثابت في منتصف الخريطة
        const IgnorePointer(
          child: Center(
            child: Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(LucideIcons.mapPin, size: 44, color: AppColors.pri)),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(LucideIcons.arrowRight, size: 22, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: AppField(hint: 'ابحث عن الحي أو الشارع...', icon: LucideIcons.search, onChanged: _search)),
              ]),
              if (searching) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator(color: AppColors.pri)),
              if (results.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    for (final r in results)
                      InkWell(
                        onTap: () => _go(r.$2),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            const Icon(LucideIcons.mapPin, size: 18, color: AppColors.mute),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r.$1, maxLines: 2, overflow: TextOverflow.ellipsis, style: tx(13))),
                          ]),
                        ),
                      ),
                  ]),
                ),
            ]),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
          child: VCol(gap: 10, [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
              child: Text('حرّك الخريطة لين يصير الدبوس على محلك بالضبط', textAlign: TextAlign.center, style: tx(13, c: AppColors.ink2)),
            ),
            AppButton('تأكيد الموقع', icon: LucideIcons.check, onTap: () => Navigator.pop(context, center)),
          ]),
        ),
      ]),
    );
  }
}
