import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'ios26/ios26_segmented_control.dart';

/// An adaptive segmented control that renders platform-specific styles
///
/// On iOS 26+: Uses native iOS 26 UISegmentedControl with Liquid Glass
/// On iOS <26 (iOS 18 and below): Uses CupertinoSlidingSegmentedControl
/// On Android: Uses Material SegmentedButton
class AdaptiveSegmentedControl extends StatelessWidget {
  /// Creates an adaptive segmented control
  const AdaptiveSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onValueChanged,
    this.enabled = true,
    this.color,
    this.height = 36.0,
    this.shrinkWrap = false,
    this.sfSymbols,
    this.segmentChildren,
    this.iconSize,
    this.iconColor,
  });

  /// Segment labels to display, in order
  final List<String> labels;

  /// The index of the selected segment
  final int selectedIndex;

  /// Called when the user selects a segment
  final ValueChanged<int> onValueChanged;

  /// Whether the control is interactive
  final bool enabled;

  /// Tint color for the selected segment
  final Color? color;

  /// Height of the control
  final double height;

  /// Whether the control should shrink to fit content
  final bool shrinkWrap;

  /// Optional SF Symbol names or IconData
  final List<dynamic>? sfSymbols;

  /// Optional custom widgets for each segment.
  ///
  /// When provided, these are rendered instead of generating content from
  /// [labels] and [sfSymbols]. On iOS 26+, this falls back to a Flutter
  /// implementation because the native platform view cannot host widgets.
  final List<Widget>? segmentChildren;

  /// Icon size
  final double? iconSize;

  /// Icon color
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    if (_usesCustomFlutterContent) {
      return _buildFlutterSegmentedControl(context);
    }

    // iOS 26+ - Use native iOS 26 segmented control
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26SegmentedControl(
        labels: labels,
        selectedIndex: selectedIndex,
        onValueChanged: onValueChanged,
        enabled: enabled,
        color: color,
        height: height,
        shrinkWrap: shrinkWrap,
        icons: sfSymbols,
        iconSize: iconSize,
        iconColor: iconColor,
      );
    }

    // iOS <26 (iOS 18 and below) - Use CupertinoSlidingSegmentedControl
    if (PlatformInfo.isIOS) {
      return _buildCupertinoSegmentedControl(context);
    }

    // Android - Use Material SegmentedButton
    if (PlatformInfo.isAndroid) {
      return _buildMaterialSegmentedButton(context);
    }

    // Fallback
    return _buildCupertinoSegmentedControl(context);
  }

  bool get _hasIcons => sfSymbols != null && sfSymbols!.isNotEmpty;

  bool get _hasLabels => labels.isNotEmpty;

  bool get _usesCustomFlutterContent =>
      segmentChildren != null || (_hasIcons && _hasLabels);

  int get _itemCount {
    if (segmentChildren != null) return segmentChildren!.length;
    if (_hasIcons && _hasLabels) {
      return labels.length < sfSymbols!.length
          ? labels.length
          : sfSymbols!.length;
    }
    if (_hasLabels) return labels.length;
    if (_hasIcons) return sfSymbols!.length;
    return 0;
  }

  double get _effectiveHeight {
    if (_usesCustomFlutterContent && height < 40) {
      return 40;
    }
    return height;
  }

  Widget _buildFlutterSegmentedControl(BuildContext context) {
    if (PlatformInfo.isAndroid) {
      return _buildMaterialSegmentedButton(context);
    }
    return _buildCupertinoSegmentedControl(context);
  }

  Widget _buildSegmentChild(int index) {
    if (segmentChildren != null) {
      return segmentChildren![index];
    }

    if (_hasIcons && _hasLabels) {
      final dynamic icon = sfSymbols![index];
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconWidget(icon),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              labels[index],
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
    }

    if (_hasIcons) {
      return _buildIconWidget(sfSymbols![index]);
    }

    return Text(
      labels[index],
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildIconWidget(dynamic icon) {
    if (icon is Widget) {
      return icon;
    }

    if (icon is IconData) {
      return Icon(icon, size: iconSize ?? 20, color: iconColor);
    }

    return Text(icon.toString());
  }

  Widget _buildCupertinoSegmentedControl(BuildContext context) {
    final Map<int, Widget> children = {};
    final itemCount = _itemCount;

    for (int i = 0; i < itemCount; i++) {
      children[i] = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _hasIcons && _hasLabels ? 10 : 12,
          vertical: 8,
        ),
        child: _buildSegmentChild(i),
      );
    }

    Widget control = CupertinoSlidingSegmentedControl<int>(
      children: children,
      groupValue: selectedIndex,
      onValueChanged: (int? value) {
        if (enabled && value != null) {
          onValueChanged(value);
        }
      },
    );

    if (shrinkWrap) {
      control = Center(child: IntrinsicWidth(child: control));
    }

    return SizedBox(height: _effectiveHeight, child: control);
  }

  Widget _buildMaterialSegmentedButton(BuildContext context) {
    final segments = <ButtonSegment<int>>[];
    final itemCount = _itemCount;

    for (int i = 0; i < itemCount; i++) {
      segments.add(
        ButtonSegment<int>(
          value: i,
          label: segmentChildren != null || _hasLabels
              ? _buildSegmentChild(i)
              : null,
          icon: segmentChildren == null && _hasIcons && !_hasLabels
              ? _buildIconWidget(sfSymbols![i])
              : null,
        ),
      );
    }

    Widget control = SegmentedButton<int>(
      segments: segments,
      selected: {selectedIndex},
      onSelectionChanged: enabled
          ? (Set<int> newSelection) {
              if (newSelection.isNotEmpty) {
                onValueChanged(newSelection.first);
              }
            }
          : null,
      style: SegmentedButton.styleFrom(
        minimumSize: Size.fromHeight(_effectiveHeight),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
    );

    if (shrinkWrap) {
      control = Center(child: IntrinsicWidth(child: control));
    }

    return control;
  }
}
