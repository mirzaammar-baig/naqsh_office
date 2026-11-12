// Plot ki extra tafseel. Ye Plot ke saath Firestore mein 'details' ke andar save hoti hai.

enum PlotFacing {
  north('North'),
  south('South'),
  east('East'),
  west('West');

  const PlotFacing(this.label);

  final String label;
}

enum DevelopmentStatus {
  undeveloped('Undeveloped'),
  partial('Partially developed'),
  developed('Developed');

  const DevelopmentStatus(this.label);

  final String label;
}

enum Utility {
  electricity('Electricity'),
  gas('Gas'),
  water('Water'),
  sewerage('Sewerage');

  const Utility(this.label);

  final String label;
}

enum NearbyPlace {
  masjid('Masjid'),
  park('Park'),
  school('School'),
  hospital('Hospital'),
  market('Market'),
  zoo('Zoo'),
  mainGate('Main Gate'),
  mainRoad('Main Road'),
  playground('Playground'),
  graveyard('Graveyard'),
  busStop('Bus stop'),
  mall('Mall'),
  bank('Bank / ATM'),
  petrolPump('Petrol pump');

  const NearbyPlace(this.label);

  final String label;
}

// Ready-made tags. Custom tags bhi add ho sakte hain.
const List<String> locationTagSuggestions = [
  'Park facing',
  'Main boulevard',
  'Commercial side',
  'Corner side',
  'Near entrance',
];

const List<String> advantageSuggestions = [
  'Quiet street',
  'Near market',
  'Near school',
  'Wide road',
  'Gated area',
  'Good for investment',
];

// Disadvantage ke saath uska upside (jo indirect faida hai).
const Map<String, String> disadvantageUpsides = {
  'Near main road': 'Noisy, but easy access and good for a shop or office',
  'Near graveyard': 'Quiet and peaceful, usually a lower price',
  'Near commercial area': 'Busy, but good rental and business value',
  'Narrow street': 'Less traffic and safer for children',
  'Far from market': 'Calmer area, less crowd',
  'Near high-tension line': 'Lower price, open view',
};

// Faasla meters mein save hota hai, dikhane ke liye 1000 se zyada ho to km.
String formatDistance(int meters) {
  if (meters < 1000) {
    return '$meters m';
  }
  final km = meters / 1000;
  final text = km.toStringAsFixed(1);
  return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text} km';
}

class PlotDetails {
  const PlotDetails({
    this.description = '',
    this.facing,
    this.roadWidthFeet,
    this.development = DevelopmentStatus.undeveloped,
    this.possessionReady = false,
    this.utilities = const [],
    this.locationTags = const [],
    this.advantages = const [],
    this.disadvantages = const [],
    this.distances = const {},
  });

  final String description;
  final PlotFacing? facing;
  final int? roadWidthFeet;
  final DevelopmentStatus development;
  final bool possessionReady;
  final List<Utility> utilities;
  final List<String> locationTags;
  final List<String> advantages;
  final List<String> disadvantages;

  // Jis jagah ka faasla diya hai, sirf wahi is map mein hoti hai (meters).
  final Map<NearbyPlace, int> distances;

  // Kuch bhi nahi bhara to true.
  bool get isEmpty =>
      description.isEmpty &&
          facing == null &&
          roadWidthFeet == null &&
          utilities.isEmpty &&
          locationTags.isEmpty &&
          advantages.isEmpty &&
          disadvantages.isEmpty &&
          distances.isEmpty;

  String get roadWidthText =>
      roadWidthFeet == null ? 'Not set' : '$roadWidthFeet ft';

  PlotDetails copyWith({
    String? description,
    PlotFacing? facing,
    bool clearFacing = false,
    int? roadWidthFeet,
    bool clearRoadWidth = false,
    DevelopmentStatus? development,
    bool? possessionReady,
    List<Utility>? utilities,
    List<String>? locationTags,
    List<String>? advantages,
    List<String>? disadvantages,
    Map<NearbyPlace, int>? distances,
  }) {
    return PlotDetails(
      description: description ?? this.description,
      facing: clearFacing ? null : (facing ?? this.facing),
      roadWidthFeet: clearRoadWidth
          ? null
          : (roadWidthFeet ?? this.roadWidthFeet),
      development: development ?? this.development,
      possessionReady: possessionReady ?? this.possessionReady,
      utilities: utilities ?? this.utilities,
      locationTags: locationTags ?? this.locationTags,
      advantages: advantages ?? this.advantages,
      disadvantages: disadvantages ?? this.disadvantages,
      distances: distances ?? this.distances,
    );
  }

  // ---------- Firestore ke liye ----------

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'facing': facing?.name,
      'roadWidthFeet': roadWidthFeet,
      'development': development.name,
      'possessionReady': possessionReady,
      'utilities': [for (final utility in utilities) utility.name],
      'locationTags': locationTags,
      'advantages': advantages,
      'disadvantages': disadvantages,
      'distances': {
        for (final entry in distances.entries) entry.key.name: entry.value,
      },
    };
  }

  factory PlotDetails.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const PlotDetails();
    }

    List<String> readStrings(String key) {
      final value = data[key];
      if (value is List) {
        return value.whereType<String>().toList();
      }
      return [];
    }

    final utilityNames = readStrings('utilities');
    final distanceData = data['distances'];
    final distances = <NearbyPlace, int>{};
    if (distanceData is Map) {
      for (final place in NearbyPlace.values) {
        final value = distanceData[place.name];
        if (value is num) {
          distances[place] = value.toInt();
        }
      }
    }

    return PlotDetails(
      description: (data['description'] as String?) ?? '',
      facing: PlotFacing.values
          .where((facing) => facing.name == data['facing'])
          .firstOrNull,
      roadWidthFeet: (data['roadWidthFeet'] as num?)?.toInt(),
      development: DevelopmentStatus.values
          .where((status) => status.name == data['development'])
          .firstOrNull ??
          DevelopmentStatus.undeveloped,
      possessionReady: (data['possessionReady'] as bool?) ?? false,
      utilities: [
        for (final utility in Utility.values)
          if (utilityNames.contains(utility.name)) utility,
      ],
      locationTags: readStrings('locationTags'),
      advantages: readStrings('advantages'),
      disadvantages: readStrings('disadvantages'),
      distances: distances,
    );
  }
}