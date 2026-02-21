import 'package:flutter/material.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';

/// Industrial Input Type
enum IndustrialInputType {
  /// Standard text input
  text,

  /// Password input (obscured)
  password,

  /// Multiline text input
  multiline,

  /// Numeric input
  number,

  /// Email input
  email,
}

/// Industrial Input
///
/// A custom text input widget implementing Industrial Minimalism design.
/// Features:
/// - Border-focused design
/// - Focus illumination with Signal Orange
/// - Monospace label support
/// - Technical annotation style
/// - WCAG AA compliant touch targets
///
/// Usage:
/// ```dart
/// IndustrialInput(
///   label: 'Email',
///   hintText: 'Enter your email',
///   onChanged: (value) => print('Changed: $value'),
///   validator: (value) => value!.isEmpty ? 'Required' : null,
/// )
/// ```
class IndustrialInput extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? initialValue;
  final TextEditingController? controller;
  final IndustrialInputType inputType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? helperText;
  final String? errorText;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;

  const IndustrialInput({
    super.key,
    this.label,
    this.hintText,
    this.initialValue,
    this.controller,
    this.inputType = IndustrialInputType.text,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.helperText,
    this.errorText,
    this.semanticLabel,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  State<IndustrialInput> createState() => _IndustrialInputState();
}

class _IndustrialInputState extends State<IndustrialInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _borderController;
  late Animation<double> _borderAnimation;
  bool _isFocused = false;
  bool _isHovered = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _obscureText = widget.inputType == IndustrialInputType.password;

    _borderController = AnimationController(
      vsync: this,
      duration: AppAnimations.durationNormal,
    );

    _borderAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.easeInOutCubic),
    );

    if (_focusNode.hasFocus) {
      _isFocused = true;
      _borderController.value = 1.0;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    _borderController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      _borderController.forward();
    } else {
      _borderController.reverse();
    }
  }

  void _onHoverEnter() {
    if (!widget.readOnly && widget.enabled) {
      setState(() => _isHovered = true);
    }
  }

  void _onHoverExit() {
    setState(() => _isHovered = false);
  }

  void _toggleObscureText() {
    setState(() => _obscureText = !_obscureText);
  }

  TextInputType get _keyboardType {
    switch (widget.inputType) {
      case IndustrialInputType.number:
        return TextInputType.number;
      case IndustrialInputType.email:
        return TextInputType.emailAddress;
      case IndustrialInputType.multiline:
        return TextInputType.multiline;
      case IndustrialInputType.password:
      case IndustrialInputType.text:
      default:
        return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final isEnabled = widget.enabled && !widget.readOnly;

    // Border color based on state
    Color borderColor;
    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      borderColor = industrialTheme.statusError;
    } else if (_isFocused) {
      borderColor = industrialTheme.accentPrimary;
    } else if (_isHovered && isEnabled) {
      borderColor = industrialTheme.borderPrimary.withOpacity(0.7);
    } else {
      borderColor = industrialTheme.borderPrimary;
    }

    // Label color
    Color labelColor;
    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      labelColor = industrialTheme.statusError;
    } else if (_isFocused) {
      labelColor = industrialTheme.accentPrimary;
    } else {
      labelColor = industrialTheme.textSecondary;
    }

    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          if (widget.label != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    widget.label!,
                    style: AppTypography.labelMedium.copyWith(
                      color: labelColor,
                      fontFamily: AppTypography.fontFamilySecondary,
                    ),
                  ),
                  if (!isEnabled) ...[
                    const SizedBox(width: AppSpacing.xxs),
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: industrialTheme.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Input field
          AnimatedBuilder(
            animation: _borderController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: isEnabled
                      ? industrialTheme.surfaceElevated
                      : industrialTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: borderColor,
                    width: _borderAnimation.value,
                  ),
                ),
                child: Row(
                  children: [
                    // Prefix icon
                    if (widget.prefixIcon != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.xs,
                        ),
                        child: widget.prefixIcon,
                      ),
                    ],

                    // Text field
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        obscureText: _obscureText,
                        readOnly: widget.readOnly,
                        enabled: widget.enabled,
                        maxLines:
                            widget.inputType == IndustrialInputType.multiline
                            ? (widget.maxLines ?? 5)
                            : widget.maxLines,
                        minLines: widget.minLines,
                        keyboardType: _keyboardType,
                        textInputAction: widget.textInputAction,
                        autofocus: widget.autofocus,
                        style: AppTypography.bodyMedium.copyWith(
                          color: industrialTheme.textPrimary,
                          fontFamily:
                              widget.inputType == IndustrialInputType.multiline
                              ? AppTypography.fontFamilyPrimary
                              : AppTypography.fontFamilyPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: industrialTheme.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: widget.prefixIcon != null
                                ? AppSpacing.xs
                                : AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          suffixIcon: _buildSuffixIcon(industrialTheme),
                        ),
                        onChanged: widget.onChanged,
                        onSubmitted: widget.onSubmitted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Helper/Error text
          if (widget.helperText != null || widget.errorText != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Row(
                children: [
                  if (widget.errorText != null && widget.errorText!.isNotEmpty)
                    Icon(
                      Icons.error_outline,
                      size: 14,
                      color: industrialTheme.statusError,
                    )
                  else if (_isFocused)
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: industrialTheme.accentPrimary,
                    ),
                  if (widget.errorText != null && widget.errorText!.isNotEmpty)
                    const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      widget.errorText ?? widget.helperText ?? '',
                      style: AppTypography.captionSmall.copyWith(
                        color:
                            widget.errorText != null &&
                                widget.errorText!.isNotEmpty
                            ? industrialTheme.statusError
                            : industrialTheme.textTertiary,
                        fontFamily: AppTypography.fontFamilySecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildSuffixIcon(IndustrialThemeData industrialTheme) {
    // Show toggle for password fields
    if (widget.inputType == IndustrialInputType.password) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          size: 20,
          color: industrialTheme.textSecondary,
        ),
        onPressed: _toggleObscureText,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }

    // Show custom suffix icon if provided
    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: widget.suffixIcon,
      );
    }

    return null;
  }
}
