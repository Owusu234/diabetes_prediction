import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../drawer/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  LatLng? _searchedLocation;
  final MapController _mapController = MapController();
  List<Marker> _facilityMarkers = [];
  List<Map<String, dynamic>> _facilityList = [];
  List<Polyline> _routes = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation!, 15.0);
        _fetchHealthFacilities();
      }
    } catch (e) {
      debugPrint('Error getting current position: $e');
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
    try {
      final response = await http.get(url, headers: {'User-Agent': 'DiabetesPredictApp/1.0 (dev.owusu.diabetes)'});
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final destination = LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
          if (mounted) {
            setState(() {
              _searchedLocation = destination;
              _routes = [];
            });
            _mapController.move(destination, 15.0);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHealthFacilities() async {
    if (_currentLocation == null) return;
    setState(() => _isLoading = true);
    final overpassUrl = 'https://overpass-api.de/api/interpreter';
    final query = '''
      [out:json];
      (
        node["amenity"="hospital"](around:10000, ${_currentLocation!.latitude}, ${_currentLocation!.longitude});
        node["amenity"="clinic"](around:10000, ${_currentLocation!.latitude}, ${_currentLocation!.longitude});
        node["amenity"="doctors"](around:10000, ${_currentLocation!.latitude}, ${_currentLocation!.longitude});
      );
      out body;
    ''';
    try {
      final response = await http.post(
        Uri.parse(overpassUrl), 
        body: query,
        headers: {'User-Agent': 'DiabetesPredictApp/1.0 (dev.owusu.diabetes)'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'];
        if (mounted) {
          setState(() {
            _facilityList = elements.cast<Map<String, dynamic>>();
            _facilityMarkers = elements.map((e) {
              final pos = LatLng(e['lat'], e['lon']);
              return Marker(
                point: pos,
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () => _fetchRoute(pos),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.9), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
                  ),
                ),
              );
            }).toList();
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRoute(LatLng destination) async {
    if (_currentLocation == null) return;
    setState(() => _isLoading = true);
    final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/'
        '${_currentLocation!.longitude},${_currentLocation!.latitude};'
        '${destination.longitude},${destination.latitude}?overview=full&geometries=geojson');
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'DiabetesPredictApp/1.0 (dev.owusu.diabetes)'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List<LatLng> points = (data['routes'][0]['geometry']['coordinates'] as List).map((c) => LatLng(c[1], c[0])).toList();
          if (mounted) setState(() => _routes = [Polyline(points: points, strokeWidth: 5.0, color: Colors.orangeAccent)]);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentLocation ?? const LatLng(0, 0), initialZoom: 13.0),
            children: [
              TileLayer(
                urlTemplate: isDark ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'dev.owusu.diabetes',
              ),
              if (_routes.isNotEmpty) PolylineLayer(polylines: _routes),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 60, height: 60,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
                        child: Center(child: Container(width: 16, height: 16, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)))),
                      ),
                    ),
                  if (_searchedLocation != null)
                    Marker(
                      point: _searchedLocation!,
                      width: 50, height: 50,
                      child: const Icon(Icons.location_on_rounded, color: Colors.green, size: 45),
                    ),
                  ..._facilityMarkers,
                ],
              ),
            ],
          ),
          
          // Custom Floating Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.bodyTextColor),
                      decoration: InputDecoration(
                        hintText: 'Search for clinics...',
                        hintStyle: TextStyle(color: theme.bodyTextColor.withOpacity(0.5)),
                        prefixIcon: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
                        suffixIcon: IconButton(icon: const Icon(Icons.search_rounded, color: Colors.blueAccent), onPressed: () => _searchLocation(_searchController.text)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onSubmitted: _searchLocation,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('Hospitals', Icons.local_hospital_rounded),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Clinics', Icons.medical_services_rounded),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Pharmacies', Icons.local_pharmacy_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const Positioned(top: 100, left: 0, right: 0, child: Center(child: Card(elevation: 4, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 3))))),

          // Bottom Facilities Overlay
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: _facilityList.isEmpty ? const SizedBox.shrink() : Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _facilityList.length,
                itemBuilder: (context, index) {
                  final facility = _facilityList[index];
                  final name = facility['tags']?['name'] ?? 'Health Center';
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medical_information_rounded, color: Colors.blueAccent)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.bodyTextColor, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              GestureDetector(onTap: () => _fetchRoute(LatLng(facility['lat'], facility['lon'])), child: const Text('Tap for Directions', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _facilityList.isEmpty ? 0 : 140),
        child: FloatingActionButton(
          onPressed: _determinePosition,
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.my_location_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
