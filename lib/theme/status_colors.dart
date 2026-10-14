import 'package:flutter/material.dart';

/// The green "success" colours of the Figma frames (check marks, the Covered
/// chip). The Material 3 colour scheme has no success role.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.success, required this.successContainer});

  final Color success;
  final Color successContainer;

  static const StatusColors light = StatusColors(
    success: Color(0xFF146C2E),
    successContainer: Color(0xFFC4EED0),
  );

  static const StatusColors dark = StatusColors(
    success: Color(0xFF6DD58C),
    successContainer: Color(0xFF0A5223),
  );

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith({Color? success, Color? successContainer}) => StatusColors(
        success: success ?? this.success,
        successContainer: successContainer ?? this.successContainer,
      );

  @override
  StatusColors lerp(StatusColors? other, double t) => other == null
      ? this
      : StatusColors(
          success: Color.lerp(success, other.success, t)!,
          successContainer: Color.lerp(successContainer, other.successContainer, t)!,
        );
}
