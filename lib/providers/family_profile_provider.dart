// providers/family_profile_provider.dart

import 'package:flutter/foundation.dart';
import '../models/family_profile_model.dart';

class FamilyProfileProvider extends ChangeNotifier {
  List<FamilyProfileModel> _familyProfiles = [];

  List<FamilyProfileModel> get familyProfiles => _familyProfiles;

  // Add a new family profile
  void addFamilyProfile(FamilyProfileModel profile) {
    profile.id = DateTime.now().millisecondsSinceEpoch.toString();
    profile.createdAt = DateTime.now();
    _familyProfiles.add(profile);
    notifyListeners();
  }

  // Update existing family profile
  void updateFamilyProfile(String id, FamilyProfileModel updatedProfile) {
    final index = _familyProfiles.indexWhere((p) => p.id == id);
    if (index != -1) {
      _familyProfiles[index] = updatedProfile;
      notifyListeners();
    }
  }

  // Delete family profile
  void deleteFamilyProfile(String id) {
    _familyProfiles.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Get family profile by ID
  FamilyProfileModel? getFamilyProfileById(String id) {
    try {
      return _familyProfiles.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get profiles by relationship
  List<FamilyProfileModel> getProfilesByRelationship(String relationship) {
    return _familyProfiles
        .where((p) => p.relationship == relationship)
        .toList();
  }

  // Clear all family profiles
  void clearAllProfiles() {
    _familyProfiles.clear();
    notifyListeners();
  }

  // Get total count
  int get profileCount => _familyProfiles.length;


}