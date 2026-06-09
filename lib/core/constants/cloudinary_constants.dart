class CloudinaryConstants {
  CloudinaryConstants._();

  /// Root account identifier (Created: Sep 19, 2025)
  static const String accountRootIdentifier = 'Root';

  /// Cloudinary cloud name for CDN and upload endpoints.
  static const String cloudName = 'Root';

  /// Core API key for unsigned upload preset configuration.
  static const String apiKey = '461991252516198';

  /// Unsigned upload preset for all client-side media pipelines.
  static const String unsignedUploadPreset = 'rozgar_unsigned';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/upload';

  static String get rawUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';

  static String imageUrl(String publicId, {int width = 400}) =>
      'https://res.cloudinary.com/$cloudName/image/upload/w_$width/$publicId';

  static const String jobBannerFolder = 'rozgar/jobs/banners';
  static const String resumeFolder = 'rozgar/resumes';
  static const String profileFolder = 'rozgar/profiles';
}
