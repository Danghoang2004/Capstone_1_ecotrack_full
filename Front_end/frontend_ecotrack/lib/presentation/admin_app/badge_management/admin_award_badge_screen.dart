import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/admin_badge_service.dart';

class AdminAwardBadgeScreen extends StatefulWidget {
  const AdminAwardBadgeScreen({Key? key}) : super(key: key);

  @override
  State<AdminAwardBadgeScreen> createState() =>
      _AdminAwardBadgeScreenState();
}

class _AdminAwardBadgeScreenState extends State<AdminAwardBadgeScreen> {
  final AdminBadgeService _service = AdminBadgeService();
  List<BadgeModel> _badges = [];
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  
  int? _selectedUserId;
  int? _selectedBadgeId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final badges = await _service.getAllBadges();
      final users = await _service.getUsersForAwarding();
      setState(() {
        _badges = badges;
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _awardBadge() async {
    if (_selectedUserId == null || _selectedBadgeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn User và huy hiệu')),
      );
      return;
    }

    try {
      await _service.awardBadge(
        userId: _selectedUserId!,
        badgeId: _selectedBadgeId!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trao huy hiệu thành công')),
      );
      setState(() {
        _selectedUserId = null;
        _selectedBadgeId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trao huy hiệu cho người dùng'),
        backgroundColor: const Color(0xFF2F6B2F),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lỗi: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn người dùng và huy hiệu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // User Selection
                      const Text(
                        'Chọn người dùng:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _users.isEmpty
                          ? const Center(
                              child: Text('Chưa có người dùng nào'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _users.length,
                              itemBuilder: (ctx, idx) {
                                final user = _users[idx];
                                final isSelected = _selectedUserId == user['userId'];
                                return Card(
                                  color: isSelected
                                      ? const Color(0xFFE3F5D8)
                                      : Colors.white,
                                  child: ListTile(
                                    onTap: () {
                                      setState(() {
                                        _selectedUserId =
                                            isSelected ? null : user['userId'];
                                      });
                                    },
                                    leading: isSelected
                                        ? const Icon(Icons.check_circle,
                                            color: Color(0xFF2F6B2F))
                                        : const Icon(Icons.person_outline),
                                    title: Text(user['fullName']),
                                    subtitle: Text(user['email']),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 20),
                      // Badge Selection
                      const Text(
                        'Chọn huy hiệu:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _badges.isEmpty
                          ? const Center(
                              child: Text('Chưa có huy hiệu nào'),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: _badges.length,
                              itemBuilder: (ctx, idx) {
                                final badge = _badges[idx];
                                final isSelected =
                                    _selectedBadgeId == badge.badgeId;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedBadgeId = isSelected
                                          ? null
                                          : badge.badgeId;
                                    });
                                  },
                                  child: Card(
                                    elevation: isSelected ? 8 : 2,
                                    color: isSelected
                                        ? const Color(0xFFE3F5D8)
                                        : Colors.white,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (badge.iconUrl.isNotEmpty)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    8),
                                            child: Image.network(
                                              badge.iconUrl,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (ctx, err,
                                                      stack) =>
                                                  Container(
                                                width: 60,
                                                height: 60,
                                                decoration:
                                                    BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              8),
                                                  color: const Color(
                                                      0xFF2F6B2F),
                                                ),
                                                child: const Icon(
                                                  Icons
                                                      .image_not_supported,
                                                  color: Colors
                                                      .white,
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                              color: const Color(
                                                  0xFF2F6B2F),
                                            ),
                                            child: const Icon(
                                              Icons.image_outlined,
                                              color: Colors.white,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(
                                          badge.badgeName,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        if (isSelected)
                                          const Padding(
                                            padding: EdgeInsets.only(
                                                top: 8),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF2F6B2F),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 30),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _awardBadge,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F6B2F),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                          ),
                          child: const Text(
                            'Trao huy hiệu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
