import 'package:flutter/material.dart';

/// Top inset for tab bodies rendered behind [GlassmorphicAppBar].
class RozgarShellBody extends StatelessWidget {
  const RozgarShellBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(0, 80, 0, 0),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}
