import 'package:flutter/material.dart';

/// The green "success" colours (check marks, the Covered chip) and the yellow
/// "warning" colours (U3-2 "Awaiting your confirmation") of the Figma frames.
/// The Material 3 colour scheme has no success or warning role.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;

  static const StatusColors light = StatusColors(
    success: Color(0xFF146C2E),
    successContainer: Color(0xFFC4EED0),
    warning: Color(0xFF6D5000),
    warningContainer: Color(0xFFFFE08B),
  );

  static const StatusColors dark = StatusColors(
    success: Color(0xFF6DD58C),
    successContainer: Color(0xFF0A5223),
    warning: Color(0xFFF2C14B),
    warningContainer: Color(0xFF523C00),
  );

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith({Color? success, Color? successContainer, Color? warning, Color? warningContainer}) =>
      StatusColors(
        success: success ?? this.success,
        successContainer: successContainer ?? this.successContainer,
        warning: warning ?? this.warning,
        warningContainer: warningContainer ?? this.warningContainer,
      );

  @override
  StatusColors lerp(StatusColors? other, double t) => other == null
      ? this
      : StatusColors(
          success: Color.lerp(success, other.success, t)!,
          successContainer: Color.lerp(successContainer, other.successContainer, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
        );
}
