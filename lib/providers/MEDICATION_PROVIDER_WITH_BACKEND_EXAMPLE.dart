/// Example: Updated MedicationProvider with Backend Integration
/// This shows how to sync with the backend server
/// 
/// To use this, replace the current medication_provider.dart with this version
library;

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class MedicationProviderWithBackend extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load medications from backend
  Future<void> loadFromBackend(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (!authService.isAuthenticated) {
        _error = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final medications = await _apiService.getMedications();
      
      _items.clear();
      for (final med in medications) {
        _items.add(med);
      }
      
      debugPrint('[MedicationProvider] Loaded ${_items.length} medications from backend');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load medications: $e';
      debugPrint('[MedicationProvider] Error loading: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add medication (saves to backend)
  Future<void> addToBackend({
    required String name,
    required String dose,
    required int intervalHours,
    required DateTime nextDose,
    String? notes,
    int? quantity,
    String? startTime,
    String? startDate,
    String? imagePath,
  }) async {
    try {
      // Save to backend
      final result = await _apiService.addMedication(
        name: name,
        dose: dose,
        intervalHours: intervalHours,
        nextDose: nextDose,
        notes: notes,
        quantity: quantity,
      );

      // Add to local list
      _items.add(result);

      // Schedule notifications
      final prefix = result['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      await NotificationService().scheduleRepeatedOccurrences(
        prefix: prefix,
        title: 'Time to take $name',
        body: '$dose · every ${intervalHours}h',
        firstOccurrence: nextDose,
        intervalHours: intervalHours,
        occurrences: 30,
      );

      debugPrint('[MedicationProvider] Medication added successfully');
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add medication: $e';
      debugPrint('[MedicationProvider] Error adding: $e');
      notifyListeners();
    }
  }

  /// Update medication
  Future<void> updateMedication({
    required String medicationId,
    required String name,
    required String dose,
    required int intervalHours,
    required DateTime nextDose,
    String? notes,
    int? quantity,
  }) async {
    try {
      await _apiService.updateMedication(
        medicationId: medicationId,
        name: name,
        dose: dose,
        intervalHours: intervalHours,
        nextDose: nextDose,
        notes: notes,
        quantity: quantity,
      );

      // Update local list
      final index = _items.indexWhere((item) => item['id'] == medicationId);
      if (index != -1) {
        _items[index] = {
          ..._items[index],
          'name': name,
          'dose': dose,
          'intervalHours': intervalHours,
          'nextDose': nextDose.toIso8601String(),
          'notes': notes,
          'quantity': quantity,
        };
      }

      debugPrint('[MedicationProvider] Medication updated successfully');
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update medication: $e';
      debugPrint('[MedicationProvider] Error updating: $e');
      notifyListeners();
    }
  }

  /// Delete medication
  Future<void> deleteFromBackend(String medicationId) async {
    try {
      await _apiService.deleteMedication(medicationId);

      // Remove from local list
      _items.removeWhere((item) => item['id'] == medicationId);

      // Cancel notifications
      await NotificationService().cancelForPrefix(medicationId);

      debugPrint('[MedicationProvider] Medication deleted successfully');
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete medication: $e';
      debugPrint('[MedicationProvider] Error deleting: $e');
      notifyListeners();
    }
  }

  /// Record medication taken (for adherence tracking)
  Future<void> recordTaken(String medicationId) async {
    try {
      await _apiService.recordMedicationTaken(
        medicationId: medicationId,
        timestamp: DateTime.now(),
      );

      debugPrint('[MedicationProvider] Adherence recorded for: $medicationId');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to record adherence: $e';
      debugPrint('[MedicationProvider] Error recording adherence: $e');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
