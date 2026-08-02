import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../core/dependencies.dart';
import '../../core/result.dart';
import '../../models/qr_item.dart';
import '../../utils/app_theme.dart';
import 'qr_saved_tab.dart';
import '../../utils/app_spacing.dart';

class QrCameraScreen extends StatefulWidget {
  const QrCameraScreen({super.key});

  @override
  QrCameraScreenState createState() => QrCameraScreenState();
}

class QrCameraScreenState extends State<QrCameraScreen> {
  int _tabIndex = 0;
  MobileScannerController? _cameraController;
  final ImagePicker _imagePicker = ImagePicker();
  String? _lastScanned;
  bool _isSaving = false;
  bool _isVisible = false;

  void startCamera() {
    if (_cameraController != null) return;
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    if (mounted) setState(() {});
  }

  void stopCamera() {
    final controller = _cameraController;
    if (controller == null) return;
    _cameraController = null;
    controller.dispose();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // stopCamera() nulls the field, so this only fires if it was still live.
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  void setVisible(bool visible) {
    _isVisible = visible;
    if (visible && _tabIndex == 0) {
      Future.microtask(() {
        if (mounted) startCamera();
      });
    } else if (!visible) {
      stopCamera();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isSaving) return;
    if (capture.barcodes.isNotEmpty) {
      final value = capture.barcodes.first.rawValue;
      if (value != null && value.isNotEmpty && value != _lastScanned) {
        setState(() => _lastScanned = value);
        _showScanResult(value);
      }
    }
  }

  void _showScanResult(String data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.pill))),
      builder: (ctx) => _ScanResultSheet(
        data: data,
        onSave: (label) => _saveToList(label, data),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _lastScanned = null);
    });
  }

  Future<void> _saveToList(String label, String data) async {
    setState(() => _isSaving = true);

    final result = await context.qrCodes.save(
      QrItem(
        id: const Uuid().v4(),
        label: label,
        data: data,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;

    if (result case Err(:final failure)) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    setState(() {
      _isSaving = false;
      _tabIndex = 1;
      _lastScanned = null;
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to My Codes')),
    );
    stopCamera();
  }

  Future<void> _pickFromGallery() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final controller = _cameraController ?? MobileScannerController();
    final bool needsDispose = _cameraController == null;

    try {
      final BarcodeCapture? result = await controller.analyzeImage(image.path);
      if (result != null && result.barcodes.isNotEmpty) {
        final value = result.barcodes.first.rawValue;
        if (value != null && value.isNotEmpty) {
          _showScanResult(value);
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR code found in image')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error scanning image')));
      }
    } finally {
      if (needsDispose) unawaited(controller.dispose());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, 16, AppSpacing.page, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: colors.primaryContainer),
                    child: Icon(Icons.person_rounded,
                        color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Clarity',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(color: colors.primary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    _buildTab(0, 'Scan', colors),
                    _buildTab(1, 'My Codes', colors),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _tabIndex == 0 ? _buildScanView(colors) : const QrSavedTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, ColorScheme colors) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tabIndex = index);
          if (index == 0 && _isVisible) {
            startCamera();
          } else {
            stopCamera();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.floating),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w500,
                  color:
                      isSelected ? AppTheme.onPrimary : colors.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanView(ColorScheme colors) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: _cameraController != null
                ? MobileScanner(
                    controller: _cameraController!,
                    onDetect: _onDetect,
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                        child: Icon(Icons.camera_alt,
                            color: Colors.white38, size: 48)),
                  ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.frame),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.6),
                            width: 2.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.pill)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Scan QR Code',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: colors.onSurface)),
                const SizedBox(height: 4),
                Text('Align the QR code within the frame',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.image_rounded, size: 18),
                    label: const Text('Pick from Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.outlineVariant),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanResultSheet extends StatefulWidget {
  final String data;
  final Function(String label) onSave;

  const _ScanResultSheet({required this.data, required this.onSave});

  @override
  State<_ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<_ScanResultSheet> {
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    final preview =
        widget.data.length > 30 ? widget.data.substring(0, 30) : widget.data;
    _labelController = TextEditingController(text: preview);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.grabber)))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppTheme.success, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('QR Code Detected',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      )),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.floating)),
            child: Text(widget.data,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: colors.onSurface,
                      fontFamily: 'monospace',
                    ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 16),
          Text('Label',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.outline,
                  )),
          const SizedBox(height: 6),
          TextField(
              controller: _labelController,
              decoration: const InputDecoration(hintText: 'Name this QR code')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.data));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Copied')));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    side: BorderSide(color: colors.outlineVariant),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.floating)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final label = _labelController.text.trim();
                    if (label.isEmpty) return;
                    widget.onSave(label);
                  },
                  child: const Text('Save to My Codes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
