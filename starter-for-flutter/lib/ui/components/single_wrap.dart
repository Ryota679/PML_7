import 'package:flutter/material.dart';

class SingleWrap extends StatelessWidget {
  final Widget child;

  const SingleWrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [child],
    );
  }
}
