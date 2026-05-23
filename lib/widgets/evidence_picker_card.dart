import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/error_messages.dart';
import '../core/navigation.dart';

class EvidencePickerCard extends StatefulWidget {
  const EvidencePickerCard({
    super.key,
    required this.image,
    required this.onChanged,
  });

  final XFile? image;
  final ValueChanged<XFile?> onChanged;

  @override
  State<EvidencePickerCard> createState() => _EvidencePickerCardState();
}

class _EvidencePickerCardState extends State<EvidencePickerCard> {
  final picker = ImagePicker();
  Uint8List? previewBytes;
  bool isPicking = false;

  @override
  void didUpdateWidget(covariant EvidencePickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image?.path != widget.image?.path) {
      _loadPreview();
    }
  }

  Future<void> pick(ImageSource source) async {
    try {
      setState(() => isPicking = true);
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1600,
      );
      widget.onChanged(picked);
      await _loadPreview(picked);
    } catch (exception) {
      if (mounted) showSnack(context, friendlyError(exception));
    } finally {
      if (mounted) setState(() => isPicking = false);
    }
  }

  Future<void> _loadPreview([XFile? file]) async {
    final image = file ?? widget.image;
    if (image == null) {
      setState(() => previewBytes = null);
      return;
    }
    final bytes = await image.readAsBytes();
    if (mounted) setState(() => previewBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photo evidence',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isPicking)
                  const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (widget.image != null)
                  IconButton(
                    tooltip: 'Remove photo',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      widget.onChanged(null);
                      setState(() => previewBytes = null);
                    },
                  ),
              ],
            ),
            if (previewBytes != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  previewBytes!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.image?.name ?? 'Selected photo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF536E7A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isPicking
                        ? null
                        : () => pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isPicking
                        ? null
                        : () => pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
