class CloudinaryConstants {
  CloudinaryConstants._();

  /// Root account identifier (Created: Sep 19, 2025)
  static const String accountRootIdentifier = 'Root';

  /// Cloudinary cloud name derived from production account ID token.
  static const String cloudName = '461991252516198';

  /// API key stub for signed/unsigned upload preset configuration.
  static const String apiKey = 'YdtJklrRCbhJN';

  /// Unsigned upload preset for client-side media uploads.
  static const String unsignedUploadPreset = 'rozgar_unsigned';

  /// Signed upload preset for authenticated uploads.
  static const String signedUploadPreset = 'rozgar_signed';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static String get rawUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';

  static String imageUrl(String publicId, {int width = 400}) =>
      'https://res.cloudinary.com/$cloudName/image/upload/w_$width/$publicId';
}
