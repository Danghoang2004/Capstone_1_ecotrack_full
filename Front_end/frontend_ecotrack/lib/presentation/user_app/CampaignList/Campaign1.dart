import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: CampaignDetailPage()),
  );
}

class CampaignDetailPage extends StatefulWidget {
  @override
  _CampaignDetailPageState createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  bool hasJoined = false;
  static const primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          "Chi tiết chiến dịch",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) ẢNH + BADGE (+50 điểm)
            Stack(
              children: [
                Image.network(
                  "Back_end/Ecotrack_backend/uploads/reports/CampaignImg/vungtauBeach.png",
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),

                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flash_on, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          "+ 50 điểm",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2) TIÊU ĐỀ
                  Text(
                    "Dọn Dẹp Bãi Biển Vũng Tàu",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),

                  SizedBox(height: 14),

                  // 3) TỔ CHỨC
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          "eco",
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(width: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "EcoVietnam",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("Tổ chức", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 18),

                  // 4) TAGS
                  Row(
                    children: [
                      _buildTag("Bãi biển"),
                      SizedBox(width: 8),
                      _buildTag("Môi trường"),
                      SizedBox(width: 8),
                      _buildTag("Cộng đồng"),
                    ],
                  ),

                  SizedBox(height: 18),

                  // 5) LIKE - COMMENT - HUY HIỆU
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_border),
                          SizedBox(width: 4),
                          Text("230"),
                          SizedBox(width: 16),
                          Icon(Icons.chat_bubble_outline),
                          SizedBox(width: 4),
                          Text("30"),
                        ],
                      ),

                      Row(
                        children: [
                          Icon(Icons.emoji_events, color: primaryGreen),
                          SizedBox(width: 4),
                          Text(
                            "Huy hiệu môi trường",
                            style: TextStyle(color: primaryGreen),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  // 6) NGƯỜI THAM GIA
                  _buildParticipantSection(),

                  SizedBox(height: 20),

                  // 7) MÔ TẢ CHIẾN DỊCH
                  _buildDescription(),

                  SizedBox(height: 30),

                  // 8) NÚT THAM GIA / CHECK-IN
                  _buildJoinSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget: Tag
  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 13)),
    );
  }

  // Widget: Người tham gia
  Widget _buildParticipantSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Người tham gia", style: TextStyle(fontWeight: FontWeight.bold)),

          SizedBox(height: 10),

          LinearPercentIndicator(
            lineHeight: 14,
            percent: 156 / 200,
            backgroundColor: Colors.grey.shade300,
            progressColor: primaryGreen,
            barRadius: Radius.circular(10),
            center: Text(
              "156/200",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),

          SizedBox(height: 6),
          Text("78% đã đăng ký", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Widget: Mô tả chiến dịch
  Widget _buildDescription() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mô tả chiến dịch",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Cùng nhau bảo vệ môi trường biển, tạo ra một bãi biển sạch đẹp cho cộng đồng và du khách.",
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  // Widget: Tham gia / Check in
  Widget _buildJoinSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() => hasJoined = true);
            },
            child: hasJoined
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Check in bằng mã QR",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : Text(
                    "Tham gia chiến dịch",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),

        SizedBox(height: 16),

        if (hasJoined)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black54),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time),
                SizedBox(width: 8),
                Text(
                  "Đã tham gia - chờ check in",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
