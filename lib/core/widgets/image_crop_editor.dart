import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ImageCropEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final bool circular;
  final String title;
  final String helpText;

  const ImageCropEditorScreen({
    super.key,
    required this.imageBytes,
    this.circular = false,
    this.title = 'Adjust image',
    this.helpText = 'Drag to position. Pinch or scroll to zoom.',
  });

  @override
  State<ImageCropEditorScreen> createState() => _ImageCropEditorScreenState();
}

class _ImageCropEditorScreenState extends State<ImageCropEditorScreen> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _controller = TransformationController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    _controller.value = Matrix4.identity();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (!mounted) return;
      Navigator.pop(context, bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not crop this image. Try another one.')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _reset,
            child: const Text('Reset'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Use'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(
              widget.helpText,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.70)),
            ),
            const SizedBox(height: 18),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.circular ? 999 : 30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.16),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: RepaintBoundary(
                          key: _cropKey,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(widget.circular ? 999 : 30),
                            child: ColoredBox(
                              color: cs.surface,
                              child: InteractiveViewer(
                                transformationController: _controller,
                                minScale: 0.75,
                                maxScale: 5,
                                boundaryMargin: const EdgeInsets.all(140),
                                clipBehavior: Clip.none,
                                child: SizedBox.expand(
                                  child: Image.memory(
                                    widget.imageBytes,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.circular ? 999 : 30),
                            border: Border.all(color: Colors.white.withOpacity(0.82), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary.withOpacity(0.14)),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_outlined, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Desktop: drag and mouse wheel. Phone: drag and pinch. The saved image keeps exactly this square crop.',
                      style: tt.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
