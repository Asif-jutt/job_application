import 'package:flutter/material.dart';

/// Top inset for tab bodies rendered behind [GlassmorphicAppBar].
class RozgarShellBody extends StatelessWidget {
  const RozgarShellBody({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  /// Safe top offset: status bar + glass app bar (title + optional subtitle).
  static double topInset(BuildContext context, {bool hasSubtitle = true}) {
    final barHeight = hasSubtitle ? 88.0 : 72.0;
    return MediaQuery.paddingOf(context).top + barHeight + 8;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = padding ?? EdgeInsets.fromLTRB(0, topInset(context), 0, 0);
    return Padding(padding: resolved, child: child);
  }
}
