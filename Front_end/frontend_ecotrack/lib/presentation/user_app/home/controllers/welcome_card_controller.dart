// Welcome Card Controller - Quản lý dữ liệu cho Welcome Card
import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';

class WelcomeCardController {
  final UserService _userService = UserService();
  ProfileView? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileView? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get userName {
    if (_profile == null) return 'Người dùng';
    final name = _profile!.fullName.trim();
    if (name.isNotEmpty) return name;
    final username = _profile!.username.trim();
    if (username.isNotEmpty) return username;
    return 'Người dùng';
  }

  int get points => _profile?.points ?? 0;

  int get rank {
    final rankValue = _profile?.rank;
    if (rankValue == null) return 0;
    return rankValue;
  }

  String get badge {
    if (_profile == null) return 'Eco Warrior';
    if (_profile!.badges.isNotEmpty) {
      return _profile!.badges.first.badgeName;
    }
    return _profile!.levelName ?? 'Eco Warrior';
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    try {
      _profile = await _userService.getProfileView();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }
}
