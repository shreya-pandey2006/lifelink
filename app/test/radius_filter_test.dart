import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_app/models/blood_request.dart';
import 'package:lifelink_app/models/potential_donor.dart';
import 'package:lifelink_app/models/responder.dart';
import 'package:lifelink_app/providers/tracking_provider.dart';

void main() {
  group('Urgency Radius and Location Distance Calculation Tests', () {
    test('maxRadiusKmForUrgency returns correct radius for each urgency level', () {
      // 1. Normal urgency -> 20 km radius
      expect(maxRadiusKmForUrgency(1), equals(20.0));

      // 2. Urgent urgency -> 10 km radius
      expect(maxRadiusKmForUrgency(2), equals(10.0));

      // 3. Critical urgency -> 5 km radius
      expect(maxRadiusKmForUrgency(3), equals(5.0));

      // Fallback
      expect(maxRadiusKmForUrgency(0), equals(20.0));
      expect(maxRadiusKmForUrgency(99), equals(20.0));
    });

    test('calculateDistanceKm computes accurate Haversine distances', () {
      // Delhi (28.6139, 77.2090) to Noida (28.5355, 77.3910) is ~19.8 km
      final distDelhiToNoida = calculateDistanceKm(28.6139, 77.2090, 28.5355, 77.3910);
      expect(distDelhiToNoida, greaterThan(18.0));
      expect(distDelhiToNoida, lessThan(21.0));

      // In Normal urgency (20 km), Noida is within range
      expect(distDelhiToNoida <= maxRadiusKmForUrgency(1), isTrue);

      // In Urgent urgency (10 km), Noida is outside range
      expect(distDelhiToNoida <= maxRadiusKmForUrgency(2), isFalse);

      // In Critical urgency (5 km), Noida is outside range
      expect(distDelhiToNoida <= maxRadiusKmForUrgency(3), isFalse);

      // Identical coordinates
      final zeroDist = calculateDistanceKm(28.6139, 77.2090, 28.6139, 77.2090);
      expect(zeroDist, equals(0.0));
      expect(zeroDist <= maxRadiusKmForUrgency(3), isTrue);

      // Nearby point 3 km away:
      // (28.6139, 77.2090) to (28.6409, 77.2090) -> ~3 km
      final dist3Km = calculateDistanceKm(28.6139, 77.2090, 28.6409, 77.2090);
      expect(dist3Km, greaterThan(2.5));
      expect(dist3Km, lessThan(3.5));
      // Within Critical (5 km)
      expect(dist3Km <= maxRadiusKmForUrgency(3), isTrue);
      // Within Urgent (10 km)
      expect(dist3Km <= maxRadiusKmForUrgency(2), isTrue);
      // Within Normal (20 km)
      expect(dist3Km <= maxRadiusKmForUrgency(1), isTrue);

      // Point 7 km away:
      // (28.6139, 77.2090) to (28.6769, 77.2090) -> ~7 km
      final dist7Km = calculateDistanceKm(28.6139, 77.2090, 28.6769, 77.2090);
      expect(dist7Km, greaterThan(6.5));
      expect(dist7Km, lessThan(7.5));
      // Outside Critical (5 km)
      expect(dist7Km <= maxRadiusKmForUrgency(3), isFalse);
      // Within Urgent (10 km)
      expect(dist7Km <= maxRadiusKmForUrgency(2), isTrue);
      // Within Normal (20 km)
      expect(dist7Km <= maxRadiusKmForUrgency(1), isTrue);

      // Point 15 km away:
      // (28.6139, 77.2090) to (28.7489, 77.2090) -> ~15 km
      final dist15Km = calculateDistanceKm(28.6139, 77.2090, 28.7489, 77.2090);
      expect(dist15Km, greaterThan(14.5));
      expect(dist15Km, lessThan(15.5));
      // Outside Critical (5 km)
      expect(dist15Km <= maxRadiusKmForUrgency(3), isFalse);
      // Outside Urgent (10 km)
      expect(dist15Km <= maxRadiusKmForUrgency(2), isFalse);
      // Within Normal (20 km)
      expect(dist15Km <= maxRadiusKmForUrgency(1), isTrue);

      // Distant city (>25 km, e.g., Delhi to Bengaluru > 1700 km)
      final distFar = calculateDistanceKm(28.6139, 77.2090, 12.9716, 77.5946);
      expect(distFar, greaterThan(1500.0));
      // Excluded for all levels
      expect(distFar <= maxRadiusKmForUrgency(3), isFalse);
      expect(distFar <= maxRadiusKmForUrgency(2), isFalse);
      expect(distFar <= maxRadiusKmForUrgency(1), isFalse);
    });

    test('Privacy Rule: Available donors never expose phone number', () {
      final potential = PotentialDonor.fromJson({
        '_id': 'donor-1',
        'bloodGroup': 'B+',
        'city': 'Delhi',
        'available': true,
        'phone': '+91 9988776655',
        'user': {
          'name': 'Rahul Sharma',
          'phone': '+91 9988776655',
        },
      });

      // Phone must ALWAYS be null for available donors to preserve privacy
      expect(potential.phone, isNull);
    });

    test('Privacy Rule: Requester phone is parsed for donor coordination', () {
      final req = BloodRequest.fromJson({
        '_id': 'req-1',
        'bloodGroup': 'O+',
        'city': 'Delhi',
        'units': 2,
        'requester': {
          '_id': 'user-1',
          'name': 'Priya Singh',
          'phone': '+91 9876543210',
        },
      });

      expect(req.requesterName, equals('Priya Singh'));
      expect(req.requesterPhone, equals('+91 9876543210'));
    });

    test('Privacy Rule: Responders gate phone access by accepted status', () {
      final acceptedResponder = Responder.fromJson({
        'name': 'Amit Kumar',
        'status': 'accepted',
        'phone': '+91 9123456780',
      });
      expect(acceptedResponder.accepted, isTrue);
      expect(acceptedResponder.phone, equals('+91 9123456780'));

      final declinedResponder = Responder.fromJson({
        'name': 'Vikram',
        'status': 'declined',
        'phone': null,
      });
      expect(declinedResponder.accepted, isFalse);
      expect(declinedResponder.phone, isNull);
    });
  });
}
