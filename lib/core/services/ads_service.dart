import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ads_constants.dart';
import '../utils/app_logger.dart';

class AdsService {
  AdsService();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await MobileAds.instance.initialize();

    final config = RequestConfiguration(
      testDeviceIds: [AdsConstants.testDeviceId],
    );
    await MobileAds.instance.updateRequestConfiguration(config);

    _initialized = true;
    AppLogger.info('Mobile Ads SDK initialized with test device whitelist');
  }

  BannerAd createBannerAd({void Function(Ad)? onAdLoaded}) {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdsConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          AppLogger.debug('Banner ad loaded');
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.warning('Banner ad failed: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
    return _bannerAd!;
  }

  Future<void> loadInterstitial({VoidCallback? onDismissed}) async {
    await InterstitialAd.load(
      adUnitId: AdsConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              onDismissed?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              AppLogger.warning('Interstitial show failed: $error');
              ad.dispose();
            },
          );
        },
        onAdFailedToLoad: (error) {
          AppLogger.warning('Interstitial load failed: $error');
        },
      ),
    );
  }

  void showInterstitial() {
    _interstitialAd?.show();
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}

typedef VoidCallback = void Function();
