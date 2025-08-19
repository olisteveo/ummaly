import 'package:flutter/material.dart';
import 'package:ummaly/theme/styles.dart';

class ResultsSheet extends StatefulWidget {
  final DraggableScrollableController controller;
  final double initialSize;
  final double minSize;
  final double maxSize;
  final double bottomInset;

  /// Title shown in the sheet header (e.g. "Results", "12 places found", "Error")
  final String title;

  /// Tapping the header toggles snap
  final VoidCallback onHeaderTap;

  /// Dragging the header lets you resize the sheet
  final void Function(DragUpdateDetails) onHeaderDragUpdate;

  /// When non-null, an error UI with a Retry button is shown.
  final String? error;

  /// Shows a loading spinner where appropriate (caller controls)
  final bool loading;

  /// When true and not loading and no error, shows a simple “No results yet” message.
  final bool isEmpty;

  /// Called by the “Retry” button when error is shown.
  final VoidCallback onRetry;

  /// Build the content list using the provided scroll controller.
  final Widget Function(ScrollController) bodyBuilder;

  const ResultsSheet({
    super.key,
    required this.controller,
    required this.initialSize,
    required this.minSize,
    required this.maxSize,
    required this.bottomInset,
    required this.title,
    required this.onHeaderTap,
    required this.onHeaderDragUpdate,
    required this.error,
    required this.loading,
    required this.isEmpty,
    required this.onRetry,
    required this.bodyBuilder,
  });

  @override
  State<ResultsSheet> createState() => _ResultsSheetState();
}

class _ResultsSheetState extends State<ResultsSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: widget.controller,
      initialChildSize: widget.initialSize,
      minChildSize: widget.minSize,
      maxChildSize: widget.maxSize,
      snap: true,
      builder: (context, scrollController) {
        // IMPORTANT: use `scrollController` everywhere so drag/snap works.
        return Container(
          padding: EdgeInsets.only(bottom: widget.bottomInset),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xl),
              topRight: Radius.circular(AppRadius.xl),
            ),
            boxShadow: AppCards.modalShadows,
          ),
          child: Column(
            children: [
              // Header (big hit target for tap/drag)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onHeaderTap,
                onVerticalDragUpdate: widget.onHeaderDragUpdate,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.s),
                    Container(
                      width: 56,
                      height: 20,
                      alignment: Alignment.center,
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.xs,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.title,
                          style: AppTextStyles.instruction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (widget.error != null) {
                      return ListView(
                        controller: scrollController,
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(AppSpacing.l),
                        children: [
                          Text(
                            widget.error!,
                            style: AppTextStyles.error,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          ElevatedButton(
                            style: AppButtons.dangerButton,
                            onPressed: widget.loading ? null : widget.onRetry,
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }

                    if (widget.isEmpty && !widget.loading) {
                      return ListView(
                        controller: scrollController,
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(AppSpacing.l),
                        children: const [
                          SizedBox(height: AppSpacing.s),
                          Text(
                            'No results yet — try a search.',
                            style: AppTextStyles.instruction,
                          ),
                        ],
                      );
                    }

                    return PrimaryScrollController(
                      controller: scrollController,
                      child: widget.bodyBuilder(scrollController),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
