class ChargerStationModel {
  final String placeId;
  final String name;
  final String vicinity;
  final String businessStatus;
  final double? lat;
  final double? lng;
  final String? photoReference;
  final bool? openNow;
  final List<String>? weekdayText;
  final double? rating;
  final int? userRatingsTotal;
  
  ChargerStationModel({
    required this.placeId,
    required this.name,
    required this.vicinity,
    required this.businessStatus,
    this.lat,
    this.lng,
    this.photoReference,
    this.openNow,
    this.weekdayText,
    this.rating,
    this.userRatingsTotal,
  });

  factory ChargerStationModel.fromJson(Map<String, dynamic> json) {
    // Handle locations that might be missing geometry data
    double? latitude;
    double? longitude;
    
    if (json['geometry'] != null && json['geometry']['location'] != null) {
      latitude = json['geometry']['location']['lat']?.toDouble();
      longitude = json['geometry']['location']['lng']?.toDouble();
    }
    
    // Handle weekday_text which might be in nested structure
    List<String>? weekdayTextList;
    if (json['opening_hours'] != null && json['opening_hours']['weekday_text'] != null) {
      weekdayTextList = List<String>.from(json['opening_hours']['weekday_text']);
    }
    
    return ChargerStationModel(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      vicinity: json['vicinity'] ?? '',
      businessStatus: json['business_status'] ?? '',
      lat: latitude,
      lng: longitude,
      photoReference: json['photos'] != null && json['photos'].isNotEmpty 
          ? json['photos'][0]['photo_reference'] 
          : null,
      openNow: json['opening_hours'] != null 
          ? json['opening_hours']['open_now'] 
          : null,
      weekdayText: weekdayTextList,
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
    );
  }
  
  // Check if station is operational
  bool isOperational() {
    return businessStatus == 'OPERATIONAL';
  }
}

class ChargerStationResponse {
  final bool success;
  final String wilayah;
  final bool cached;
  final List<ChargerStationModel> places;
  
  ChargerStationResponse({
    required this.success,
    required this.wilayah,
    required this.cached,
    required this.places,
  });
  
  factory ChargerStationResponse.fromJson(Map<String, dynamic> json) {
    var placesJson = json['places'] as List;
    List<ChargerStationModel> stationsList = placesJson
        .map((placeJson) => ChargerStationModel.fromJson(placeJson))
        .toList();
        
    return ChargerStationResponse(
      success: json['success'] ?? false,
      wilayah: json['wilayah'] ?? '',
      cached: json['cached'] ?? false,
      places: stationsList,
    );
  }
  
}