import 'package:flutter/material.dart';

/// Change uniquement la disposition des mêmes éléments, dans leur ordre mobile.
class ResponsiveSections extends StatelessWidget {
  const ResponsiveSections({
    super.key,
    required this.first,
    required this.second,
  });
  final List<Widget> first, second;
  @override
  Widget build(BuildContext context) {
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (MediaQuery.sizeOf(context).width < 900)
      return column([...first, ...second]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(first)),
        const SizedBox(width: 32),
        Expanded(child: column(second)),
      ],
    );
  }
}

class ResponsiveListingGrid extends StatelessWidget {
  const ResponsiveListingGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (MediaQuery.sizeOf(context).width < 700)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      final columns = constraints.maxWidth >= 1150 ? 3 : 2;
      final width = (constraints.maxWidth - 20 * (columns - 1)) / columns;
      return Wrap(
        spacing: 20,
        runSpacing: 6,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class ResponsiveAction extends StatelessWidget {
  const ResponsiveAction({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 700) return child;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
