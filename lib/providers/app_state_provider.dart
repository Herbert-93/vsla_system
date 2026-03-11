import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  String? _selectedBank;
  String? _currentUserId;
  String? _currentGroupId;
  bool _isOnline = true;

  String? get selectedBank => _selectedBank;
  String? get currentUserId => _currentUserId;
  String? get currentGroupId => _currentGroupId;
  bool get isOnline => _isOnline;

  void setSelectedBank(String bank) {
    _selectedBank = bank;
    notifyListeners();
  }

  void setCurrentUser(String userId, {String? groupId}) {
    _currentUserId = userId;
    notifyListeners();
  }

  void setCurrentGroup(String groupId) {
    _currentGroupId = groupId;
    notifyListeners();
  }

  void setOnlineStatus(bool status) {
    _isOnline = status;
    notifyListeners();
  }

  void clearState() {
    _selectedBank = null;
    _currentUserId = null;
    _currentGroupId = null;
    _isOnline = true;
    notifyListeners();
  }
}
