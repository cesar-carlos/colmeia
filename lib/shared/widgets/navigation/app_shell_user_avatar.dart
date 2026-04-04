import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_user_initials.dart';
import 'package:flutter/material.dart';

class AppShellUserAvatar extends StatelessWidget {
  const AppShellUserAvatar({
    required this.name,
    super.key,
    this.thumbnailUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
  });

  final String name;
  final String? thumbnailUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final resolvedBackground = backgroundColor ?? colors.primaryContainer;
    final resolvedForeground = foregroundColor ?? colors.onPrimaryContainer;
    final resolvedUrl = thumbnailUrl?.trim();
    final hasThumbnail = resolvedUrl != null && resolvedUrl.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: resolvedBackground,
      foregroundColor: resolvedForeground,
      child: ClipOval(
        child: SizedBox.expand(
          child: hasThumbnail
              ? Image.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return _AvatarFallback(
                      name: name,
                      textStyle: textStyle,
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }
                    return Center(
                      child: SizedBox(
                        width: radius,
                        height: radius,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: resolvedForeground,
                        ),
                      ),
                    );
                  },
                )
              : _AvatarFallback(
                  name: name,
                  textStyle: textStyle,
                ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.name,
    this.textStyle,
  });

  final String name;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        appShellUserInitials(name),
        style: textStyle,
      ),
    );
  }
}
