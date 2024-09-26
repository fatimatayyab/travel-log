import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Tab> tabs;

  const CustomTabBar({super.key, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: tabs,
      indicator: CustomUnderlineIndicator(),
    );
  }

  @override
 
  Size get preferredSize => throw UnimplementedError();
}

class CustomUnderlineIndicator extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomUnderlinePainter();
  }
}

class _CustomUnderlinePainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final width = configuration.size!.width;
    final height = configuration.size!.height;

    final paint = Paint()
      ..color = Colors.blue // Customize the indicator color here
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(offset.dx, offset.dy + height)
      ..lineTo(offset.dx + width / 2, offset.dy + height);

    canvas.drawPath(path, paint);
  }
}
