import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/widgets/partner_sidebar.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/widgets/partner_header.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/control/screens/control_screen.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/coupon/screens/coupon_management_screen.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/campaign/screens/campaign_sponsorship_screen.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/analysis/screens/analysis_reports_screen.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/settings/screens/partner_settings_screen.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  String _selectedMenu = 'coupon'; // Mặc định là Quản Lý Coupon

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      // Drawer cho mobile
      drawer: isMobile
          ? Drawer(
              child: PartnerSidebar(
                selectedMenu: _selectedMenu,
                isMobile: true,
                onMenuSelected: (menu) {
                  setState(() {
                    _selectedMenu = menu;
                  });
                  Navigator.pop(context); // Đóng drawer trên mobile
                },
                onLogout: () async {
                  await _authService.logout();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/partner_login',
                      (route) => false,
                    );
                  }
                },
              ),
            )
          : null,
      body: Column(
        children: [
          // Header luôn hiển thị ở trên
          const PartnerHeader(),
          // Body với sidebar và content
          Expanded(
            child: Row(
              children: [
                // Sidebar cho desktop/tablet
                if (!isMobile)
                  PartnerSidebar(
                    selectedMenu: _selectedMenu,
                    isMobile: false,
                    onMenuSelected: (menu) {
                      setState(() {
                        _selectedMenu = menu;
                      });
                    },
                    onLogout: () async {
                      await _authService.logout();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/partner_login',
                          (route) => false,
                        );
                      }
                    },
                  ),
                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // AppBar cho mobile (nếu cần)
                      if (isMobile)
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                              ),
                            ],
                          ),
                        ),
                      // Content
                      Expanded(child: _buildSelectedScreen()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedScreen() {
    switch (_selectedMenu) {
      case 'dashboard':
        return const DashboardScreen();
      case 'coupon':
        return const CouponManagementScreen();
      case 'campaign':
        return const CampaignSponsorshipScreen();
      case 'analysis':
        return const AnalysisReportsScreen();
      case 'settings':
        return const PartnerSettingsScreen();
      default:
        return const CouponManagementScreen();
    }
  }
}
