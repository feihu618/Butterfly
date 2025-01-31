import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class OptionButton extends StatefulWidget {
  final Widget icon;
  final Widget? selectedIcon;
  final VoidCallback? onPressed, onLongPressed;
  final bool selected, highlighted, focussed;
  final String tooltip;

  const OptionButton({
    super.key,
    this.tooltip = '',
    required this.icon,
    this.selectedIcon,
    this.onPressed,
    this.onLongPressed,
    this.selected = false,
    this.highlighted = false,
    this.focussed = false,
  });

  @override
  State<OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey();

  @override
  void didUpdateWidget(covariant OptionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const selectedBottom = PhosphorIcon(
      PhosphorIconsLight.caretDown,
      size: 12,
    );
    return Tooltip(
      triggerMode: TooltipTriggerMode.manual,
      message: widget.tooltip,
      key: _tooltipKey,
      child: InkWell(
        radius: 12,
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onPressed,
        onLongPress: () {
          _tooltipKey.currentState?.ensureTooltipVisible();
          widget.onLongPressed?.call();
        },
        child: Container(
          decoration: widget.highlighted
              ? BoxDecoration(
                  // Border
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : (widget.focussed
                  ? BoxDecoration(
                      // Border
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null),
          margin: (widget.highlighted || widget.focussed)
              ? null
              : const EdgeInsets.all(2),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: IconTheme(
                data: Theme.of(context).iconTheme.copyWith(
                    size: 28,
                    color: widget.selected
                        ? Theme.of(context).colorScheme.primary
                        : null),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.selected
                        ? (widget.selectedIcon ?? widget.icon)
                        : widget.icon,
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      height: widget.selected ? 12 : 0,
                      width: 12,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(),
                      child: const OverflowBox(
                        maxHeight: 12,
                        maxWidth: 12,
                        minHeight: 12,
                        minWidth: 12,
                        alignment: Alignment.topCenter,
                        child: selectedBottom,
                      ),
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
