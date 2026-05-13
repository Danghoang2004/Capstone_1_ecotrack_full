import 'package:flutter/material.dart';

class InAppNotificationDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    String type = "SUCCESS",
  }) async {
    final (IconData icon, Color color, Color bgColor) = _getNotificationStyle(
      type,
    );

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AnimatedNotificationDialog(
          title: title,
          content: content,
          icon: icon,
          color: color,
          bgColor: bgColor,
        );
      },
    );
  }

  static (IconData, Color, Color) _getNotificationStyle(String type) {
    switch (type) {
      case "ERROR":
        return (
          Icons.close_rounded,
          const Color(0xFFE74C3C),
          const Color(0xFFFFEBEE),
        );
      case "PENDING":
        return (
          Icons.access_time_rounded,
          const Color(0xFFF39C12),
          const Color(0xFFFFF3E0),
        );
      case "SUCCESS":
      default:
        return (
          Icons.check_circle_rounded,
          const Color.fromARGB(255, 51, 112, 4),
          const Color(0xFFF1F8E9),
        );
    }
  }
}

class _AnimatedNotificationDialog extends StatefulWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _AnimatedNotificationDialog({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  State<_AnimatedNotificationDialog> createState() =>
      _AnimatedNotificationDialogState();
}

class _AnimatedNotificationDialogState
    extends State<_AnimatedNotificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Icon with animated background ---
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.bgColor,
                  border: Border.all(
                    color: widget.color.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(widget.icon, size: 48, color: widget.color),
              ),

              const SizedBox(height: 24),

              // --- Title ---
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              // --- Content ---
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // --- Button ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          "Đã hiểu",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
