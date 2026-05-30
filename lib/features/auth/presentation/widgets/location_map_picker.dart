import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

// Load Google Maps API Key from environment define (--dart-define=GOOGLE_MAPS_API_KEY=your_key)
const String googleMapsApiKey =
    String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

class LocationMapPicker extends StatefulWidget {
  final LatLng initialCenter;

  const LocationMapPicker({
    super.key,
    required this.initialCenter,
  });

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  GoogleMapController? _mapController;
  late LatLng _currentCenter;

  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialCenter;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearching = true;
        _showSuggestions = true;
      });

      List<Map<String, dynamic>> results;
      if (googleMapsApiKey.isNotEmpty &&
          googleMapsApiKey != "YOUR_GOOGLE_MAPS_API_KEY") {
        results = await _fetchGooglePlaces(query);
        // Self-healing fallback: If Google Places fails (e.g. key restriction, quota, or network error), use Nominatim!
        if (results.isEmpty) {
          results = await _fetchNominatimPlaces(query);
        }
      } else {
        results = await _fetchNominatimPlaces(query);
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  // Dual search fetcher 1: Premium Google Places API
  Future<List<Map<String, dynamic>>> _fetchGooglePlaces(String query) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$googleMapsApiKey&components=country:ke');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody);
        final predictions = data['predictions'] as List<dynamic>? ?? [];

        List<Map<String, dynamic>> results = [];
        for (var pred in predictions) {
          final description = pred['description'] ?? '';
          final placeId = pred['place_id'] ?? '';
          results.add({
            'display_name': description,
            'place_id': placeId,
            'is_google': true,
          });
        }
        return results;
      }
    } catch (e) {
      debugPrint('[MAP PICKER] Google Places autocomplete error: $e');
    } finally {
      client.close();
    }
    return [];
  }

  // Dual search fetcher 2: Free OpenStreetMap Nominatim API Fallback
  Future<List<Map<String, dynamic>>> _fetchNominatimPlaces(String query) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=ke');
      final request = await client.getUrl(uri);
      request.headers
          .set('User-Agent', 'BikeBuddyApp/1.0 (com.hacklabs.bikebuddy)');
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(responseBody);
        return data.map((item) {
          return {
            'display_name': item['display_name'] ?? '',
            'lat': double.tryParse(item['lat']?.toString() ?? '') ?? 0.0,
            'lon': double.tryParse(item['lon']?.toString() ?? '') ?? 0.0,
            'is_google': false,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('[MAP PICKER] Nominatim search error: $e');
    } finally {
      client.close();
    }
    return [];
  }

  // Resolve Place details to fetch exact Lat/Lng for Google Place results
  Future<LatLng?> _fetchGooglePlaceDetails(String placeId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$googleMapsApiKey');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody);
        final result = data['result'] as Map<String, dynamic>?;
        final geometry = result?['geometry'] as Map<String, dynamic>?;
        final location = geometry?['location'] as Map<String, dynamic>?;

        if (location != null) {
          final lat = double.tryParse(location['lat']?.toString() ?? '') ?? 0.0;
          final lng = double.tryParse(location['lng']?.toString() ?? '') ?? 0.0;
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('[MAP PICKER] Google Place details error: $e');
    } finally {
      client.close();
    }
    return null;
  }

  Future<void> _selectSuggestion(Map<String, dynamic> place) async {
    LatLng? target;

    if (place['is_google'] == true) {
      setState(() {
        _isSearching = true;
      });
      target = await _fetchGooglePlaceDetails(place['place_id'] as String);
      setState(() {
        _isSearching = false;
      });
    } else {
      final lat = place['lat'] as double;
      final lon = place['lon'] as double;
      target = LatLng(lat, lon);
    }

    if (target != null && mounted) {
      setState(() {
        _currentCenter = target!;
        _showSuggestions = false;
        _searchController.text = place['display_name'].toString().split(',')[0];
        _searchResults = [];
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16.0));
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Station Location',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _currentMapType == MapType.normal
                    ? Icons.map
                    : Icons.satellite_alt,
                color: Colors.white),
            onPressed: () {
              setState(() {
                _currentMapType = _currentMapType == MapType.normal
                    ? MapType.hybrid
                    : MapType.normal;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // NATIVE GOOGLE MAP
          GoogleMap(
            mapType: _currentMapType,
            initialCameraPosition: CameraPosition(
              target: widget.initialCenter,
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              setState(() {
                _currentCenter = position.target;
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // STATIC CENTER PIN
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom: 40), // offset for marker height alignment
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Move map to position pin',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.location_on,
                    color: AppColors.green,
                    size: 44,
                  ),
                ],
              ),
            ),
          ),

          // SEARCH AND DROPDOWN
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for area or landmark...',
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.green),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.white54),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : (_isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(AppColors.green),
                                  ),
                                )
                              : null),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_showSuggestions && _searchResults.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.place_outlined,
                            color: AppColors.green,
                            size: 20,
                          ),
                          title: Text(
                            result['display_name'],
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSuggestion(result),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // BOTTOM SELECTION BUTTON
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _currentCenter);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'Confirm This Location',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
