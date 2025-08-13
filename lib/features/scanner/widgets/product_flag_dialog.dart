import 'package:flutter/material.dart';
import 'package:ummaly/core/services/product_flag_service.dart';

class ProductFlagResult {
  final bool flagged;
  final int? flagsCountDelta;
  ProductFlagResult({required this.flagged, this.flagsCountDelta});
}

class ProductFlagDialog extends StatefulWidget {
  final int? productId; // nullable: we can still create by barcode
  final String? barcode;
  final bool initiallyFlagged;

  const ProductFlagDialog({
    super.key,
    required this.productId,
    this.barcode,
    required this.initiallyFlagged,
  });

  @override
  State<ProductFlagDialog> createState() => _ProductFlagDialogState();
}

class _ProductFlagDialogState extends State<ProductFlagDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  late bool _flagged;

  // For showing existing flag on retract screen
  Map<String, dynamic>? _myFlag; // { id, reason, created_at }
  bool _loadingMyFlag = false;

  ProductFlagService _svc() => ProductFlagService(); // uses Config.apiBaseUrl by default

  @override
  void initState() {
    super.initState();
    _flagged = widget.initiallyFlagged;

    // If already flagged and we have a productId, fetch the user's flag to display
    if (_flagged && widget.productId != null) {
      _loadMyFlag(widget.productId!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMyFlag(int productId) async {
    setState(() => _loadingMyFlag = true);
    try {
      final res = await _svc().getMyFlag(productId: productId);
      final flag = (res?['flag'] is Map) ? (res!['flag'] as Map).cast<String, dynamic>() : null;
      if (mounted) setState(() => _myFlag = flag);
    } catch (_) {
      // Non-fatal: just don't show details
    } finally {
      if (mounted) setState(() => _loadingMyFlag = false);
    }
  }

  Future<void> _submit() async {
    // If already flagged -> attempt retract instead
    if (_flagged) {
      await _retract();
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      // Prefer barcode when present (works even if productId is null)
      if (widget.barcode != null && widget.barcode!.isNotEmpty) {
        await _svc().createFlagByBarcode(
          barcode: widget.barcode!,
          reason: _controller.text.trim(),
        );
      } else if (widget.productId != null) {
        await _svc().createFlagByProductId(
          productId: widget.productId!,
          reason: _controller.text.trim(),
        );
      } else {
        throw StateError('Missing product id/barcode');
      }
      if (!mounted) return;
      Navigator.of(context).pop(ProductFlagResult(flagged: true, flagsCountDelta: 1));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not flag product: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _retract() async {
    if (widget.productId == null) {
      // We only support delete by productId right now
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove flag without product id')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _svc().deleteMyFlag(productId: widget.productId!);
      if (!mounted) return;
      Navigator.of(context).pop(ProductFlagResult(flagged: false, flagsCountDelta: -1));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not retract flag: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }

  Widget _existingFlagCard(BuildContext context) {
    if (_loadingMyFlag) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Loading your flag…'),
          ],
        ),
      );
    }

    if (_myFlag == null) {
      return const SizedBox(); // Nothing to show
    }

    final reason = (_myFlag!['reason'] ?? '').toString();
    final created = _fmtDate(_myFlag!['created_at']?.toString());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your flag', style: Theme.of(context).textTheme.titleMedium),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(reason),
                ],
                if (created.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Added on $created',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _flagged ? 'Retract flag' : 'Flag this product';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // If flagged, show the existing flag details above the button
            if (_flagged) _existingFlagCard(context),

            if (!_flagged)
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _controller,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText:
                    'Describe the issue (e.g., contains pork, alcohol, unclear ingredients)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.length < 3) return 'Please enter at least 3 characters';
                    return null;
                  },
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_flagged ? 'Remove my flag' : 'Submit flag'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
