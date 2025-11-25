import 'package:flutter/material.dart';

class CheckIn_screen extends StatelessWidget {
  const CheckIn_screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 128, 127, 127),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          title: const Text(
            "Quét Mã QR",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),

      body: Stack(
        children: [
          Container(color: const Color.fromARGB(255, 34, 34, 34)),
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Quét mã QR để Check-in chiến dịch môi trường",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFF00E676), width: 4),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "EcoTrack QR",
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.eco, color: Colors.white70, size: 22),
                    SizedBox(width: 10),
                    Icon(Icons.public, color: Colors.white70, size: 22),
                    SizedBox(width: 10),
                    Icon(
                      Icons.volunteer_activism,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Text(
                  "EcoTrack  •  Green Campaign  •  Community",
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color.fromARGB(255, 32, 32, 32).withOpacity(0.75),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _BottomItem(icon: Icons.qr_code, text: "Ảnh có sẵn"),
                  _BottomItem(icon: Icons.history, text: "Lịch sử"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BottomItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}
