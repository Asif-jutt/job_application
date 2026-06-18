import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the phone number while user completes OTP verification.
final pendingPhoneProvider = StateProvider<String?>((ref) => null);
