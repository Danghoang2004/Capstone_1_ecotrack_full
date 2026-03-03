import 'package:flutter/material.dart';

class FlexibleLayout extends StatelessWidget {
  /// Hướng layout: 'row' (ngang) hoặc 'column' (dọc)
  final String direction;

  /// Danh sách widgets con
  final List<Widget> children;

  /// Khoảng cách giữa các items
  final double spacing;

  /// Main axis alignment (cho Row/Column)
  final MainAxisAlignment mainAxisAlignment;

  /// Cross axis alignment (cho Row/Column)
  final CrossAxisAlignment crossAxisAlignment;

  /// Số cột (cho Grid - tương lai)
  final int? crossAxisCount;

  /// Spacing giữa các items trong Grid (tương lai)
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  const FlexibleLayout({
    super.key,
    required this.direction,
    required this.children,
    this.spacing = 16,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.crossAxisCount,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu có crossAxisCount thì dùng Grid (tương lai)
    if (crossAxisCount != null) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount!,
          crossAxisSpacing: crossAxisSpacing ?? spacing,
          mainAxisSpacing: mainAxisSpacing ?? spacing,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      );
    }

    // Row hoặc Column
    if (direction == 'row') {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _buildChildrenWithSpacing(),
      );
    } else if (direction == 'column') {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _buildChildrenWithSpacing(),
      );
    } else {
      // Default: Column
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _buildChildrenWithSpacing(),
      );
    }
  }

  /// Thêm spacing giữa các children
  List<Widget> _buildChildrenWithSpacing() {
    if (children.isEmpty) return [];
    if (children.length == 1) return children;

    List<Widget> result = [children[0]];
    for (int i = 1; i < children.length; i++) {
      result.add(
        SizedBox(
          width: direction == 'row' ? spacing : 0,
          height: direction == 'column' ? spacing : 0,
        ),
      );
      result.add(children[i]);
    }
    return result;
  }
}
