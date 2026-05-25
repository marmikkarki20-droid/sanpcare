import 'package:geocoding/geocoding.dart';

class AddressCoordinates {
  const AddressCoordinates({
    required this.latitude,
    required this.longitude,
    required this.resolvedAddress,
  });

  final double latitude;
  final double longitude;
  final String resolvedAddress;
}

class AddressGeocodingService {
  const AddressGeocodingService._();

  static Future<AddressCoordinates> coordinatesForAddress(
    String address,
  ) async {
    final cleanAddress = address.trim();
    if (cleanAddress.isEmpty) {
      throw StateError('Service address is required.');
    }

    final attempts = _addressAttempts(cleanAddress);
    for (final candidate in attempts) {
      try {
        final locations = await locationFromAddress(candidate);
        if (locations.isEmpty) continue;
        final location = locations.first;
        return AddressCoordinates(
          latitude: location.latitude,
          longitude: location.longitude,
          resolvedAddress: candidate,
        );
      } catch (_) {
        continue;
      }
    }

    throw StateError(
      'Could not find GPS coordinates for this service address. '
      'Use a complete street address with suburb and state.',
    );
  }

  static List<String> _addressAttempts(String address) {
    final lower = address.toLowerCase();
    final attempts = <String>[address];
    if (!lower.contains('australia')) {
      attempts.add('$address, Australia');
    }
    if (!RegExp(
      r'\bnsw\b|\bact\b|\bvic\b|\bqld\b|\bsa\b|\bwa\b|\btas\b|\bnt\b',
    ).hasMatch(lower)) {
      attempts.add('$address, NSW, Australia');
      attempts.add('$address, ACT, Australia');
    }
    return attempts.toSet().toList();
  }
}
