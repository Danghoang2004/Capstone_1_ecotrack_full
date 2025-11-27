import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/welcome_card_controller.dart';

class WelcomeCard extends StatefulWidget {
  final WelcomeCardController controller;

  const WelcomeCard({super.key, required this.controller});

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard> {
  @override
  void initState() {
    super.initState();
    // Load profile và rebuild khi xong
    widget.controller.loadProfile().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: HomeColors.bgWelcome,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Xin chào, ${widget.controller.userName} !',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Điểm và xếp hạng
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_outline,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.controller.points} điểm',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: AppColors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.controller.rank > 0
                            ? 'Xếp hạng #${widget.controller.rank}'
                            : 'Chưa có xếp hạng',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
