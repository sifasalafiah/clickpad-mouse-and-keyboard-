import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

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
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCollapsibleBannerAd();
  }

  void _loadCollapsibleBannerAd() {
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
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
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
