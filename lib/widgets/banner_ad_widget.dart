import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/iap_service.dart';

class CollapsibleBannerAdWidget extends StatefulWidget {
  final String collapsiblePosition; // 'top' or 'bottom'

  const CollapsibleBannerAdWidget({
    super.key,
    this.collapsiblePosition = 'top',
  });

  @override
  State<CollapsibleBannerAdWidget> createState() => _CollapsibleBannerAdWidgetState();
}

class _CollapsibleBannerAdWidgetState extends State<CollapsibleBannerAdWidget> {
  final IapService _iapService = IapService.instance;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _iapService.addListener(_onIapChanged);
    AdService.instance.addListener(_onAdServiceChanged);
    if (!_iapService.isPro && AdService.instance.canRequestAds) {
      _loadCollapsibleBannerAd();
    }
  }

  void _onIapChanged() {
    if (_iapService.isPro) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (mounted) {
        setState(() {
          _isAdLoaded = false;
        });
      }
    } else if (!_isAdLoaded && _bannerAd == null && AdService.instance.canRequestAds) {
      _loadCollapsibleBannerAd();
    }
  }

  void _onAdServiceChanged() {
    if (!_iapService.isPro && AdService.instance.canRequestAds && !_isAdLoaded && _bannerAd == null) {
      _loadCollapsibleBannerAd();
    }
  }

  void _loadCollapsibleBannerAd() {
    if (_iapService.isPro || !AdService.instance.canRequestAds) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.instance.bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(
        extras: {
          'collapsible': widget.collapsiblePosition,
        },
      ),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_iapService.isPro) {
            ad.dispose();
            _bannerAd = null;
            return;
          }
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Collapsible BannerAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _iapService.removeListener(_onIapChanged);
    AdService.instance.removeListener(_onAdServiceChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_iapService.isPro || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
