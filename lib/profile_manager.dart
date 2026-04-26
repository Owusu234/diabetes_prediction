import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String name;
  final String? imagePath;

  UserProfile({required this.id, required this.name, this.imagePath});
}

class ProfileManager extends ChangeNotifier {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;
  ProfileManager._internal();

  List<UserProfile> _profiles = [];
  String? _currentProfileId;

  List<UserProfile> get profiles => _profiles;
  String? get currentProfileId => _currentProfileId;

  UserProfile? get currentProfile {
    if (_currentProfileId == null || _profiles.isEmpty) return null;
    try {
      return _profiles.firstWhere((p) => p.id == _currentProfileId);
    } catch (e) {
      return _profiles.isNotEmpty ? _profiles.first : null;
    }
  }

  Future<void> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profileIds = prefs.getStringList('profile_ids') ?? [];
    _currentProfileId = prefs.getString('current_profile_id');

    List<UserProfile> loaded = [];
    for (String id in profileIds) {
      final name = prefs.getString('username_$id');
      if (name != null) {
        final imagePath = prefs.getString('profile_image_$id');
        loaded.add(UserProfile(id: id, name: name, imagePath: imagePath));
      }
    }

    _profiles = loaded;
    
    if (_profiles.isEmpty) {
      _currentProfileId = null;
      await prefs.remove('current_profile_id');
    } else {
      if (_currentProfileId == null || !_profiles.any((p) => p.id == _currentProfileId)) {
        _currentProfileId = _profiles.first.id;
        await prefs.setString('current_profile_id', _currentProfileId!);
      }
    }
    notifyListeners();
  }

  Future<void> clearAllProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profileIds = prefs.getStringList('profile_ids') ?? [];
    for (var id in profileIds) {
      await prefs.remove('username_$id');
      await prefs.remove('profile_image_$id');
    }
    await prefs.remove('profile_ids');
    await prefs.remove('current_profile_id');
    
    // Legacy keys
    await prefs.remove('username');
    await prefs.remove('profile_image');
    await prefs.remove('has_seen_welcome');
    
    _profiles = [];
    _currentProfileId = null;
    notifyListeners();
  }

  Future<void> createProfile(String name, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    await prefs.setString('username_$id', name);
    if (imagePath != null) await prefs.setString('profile_image_$id', imagePath);
    
    final profileIds = prefs.getStringList('profile_ids') ?? [];
    profileIds.add(id);
    await prefs.setStringList('profile_ids', profileIds);
    
    // Switch to the newly created profile immediately
    _currentProfileId = id;
    await prefs.setString('current_profile_id', id);
    
    // Legacy sync
    await prefs.setString('username', name);
    if (imagePath != null) {
      await prefs.setString('profile_image', imagePath);
    } else {
      await prefs.remove('profile_image');
    }

    await loadProfiles();
  }

  Future<void> switchProfile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    
    UserProfile? target;
    try {
      target = _profiles.firstWhere((p) => p.id == id);
    } catch (e) {
      return;
    }

    _currentProfileId = id;
    await prefs.setString('current_profile_id', id);
    
    // Legacy sync
    await prefs.setString('username', target.name);
    if (target.imagePath != null) {
      await prefs.setString('profile_image', target.imagePath!);
    } else {
      await prefs.remove('profile_image');
    }
    
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final profileIds = prefs.getStringList('profile_ids') ?? [];
    profileIds.remove(id);
    await prefs.setStringList('profile_ids', profileIds);
    
    await prefs.remove('username_$id');
    await prefs.remove('profile_image_$id');

    if (_currentProfileId == id) {
      if (profileIds.isNotEmpty) {
        await switchProfile(profileIds.first);
      } else {
        _currentProfileId = null;
        await prefs.remove('current_profile_id');
        await prefs.remove('username');
        await prefs.remove('profile_image');
      }
    }
    await loadProfiles();
  }
}
