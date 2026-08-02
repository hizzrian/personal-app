import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrFullscreenView extends StatefulWidget {
  final String data;
  final String label;

  const QrFullscreenView({super.key, required this.data, required this.label});

  @override
  State<QrFullscreenView> createState() => _QrFullscreenViewState();
}

class _QrFullscreenViewState extends State<QrFullscreenView> {
  static const _brightnessChannel =
      MethodChannel('com.personal.personal_app/brightness');
  double? _previousBrightness;

  @override
  void initState() {
    super.initState();
    _setMaxBrightness();
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  Future<void> _setMaxBrightness() async {
    try {
      _previousBrightness =
          await _brightnessChannel.invokeMethod('getBrightness');
      await _brightnessChannel
          .invokeMethod('setBrightness', {'brightness': 1.0});
    } catch (_) {
      // Fallback: just set system UI for white screen
    }
    // Force light status bar on white background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_previousBrightness != null) {
        await _brightnessChannel
            .invokeMethod('setBrightness', {'brightness': _previousBrightness});
      }
    } catch (_) {}
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.black54),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // QR Code
              QrImageView(
                data: widget.data,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  widget.data,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium!
                      .copyWith(color: Colors.black45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text(
                  'Tap anywhere to close',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium!
                      .copyWith(color: Colors.black26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
