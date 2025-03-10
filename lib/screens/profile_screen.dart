import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../services/auth_service.dart';
import '../utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  // Text editing controllers for form fields
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _dietaryController = TextEditingController();
  final _goalsController = TextEditingController();
  
  // Form state
  String _gender = 'unknown';
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  Map<String, dynamic>? _userProfile;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _dietaryController.dispose();
    _goalsController.dispose();
    super.dispose();
  }
  
  /// Load user profile data from Firestore
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      _userProfile = await _authService.getUserProfile();
      
      // Populate form fields
      if (_userProfile != null) {
        _weightController.text = (_userProfile!['weight'] ?? 70.0).toString();
        _heightController.text = (_userProfile!['height'] ?? 170.0).toString();
        _ageController.text = (_userProfile!['age'] ?? 25).toString();
        _dietaryController.text = _userProfile!['dietary_restrictions'] ?? '';
        _goalsController.text = _userProfile!['fitness_goals'] ?? '';
        _gender = _userProfile!['gender'] ?? 'unknown';
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stack) {
      Logger.logError('Failed to load user profile', e, stack);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile: $e';
      });
    }
  }
  
  /// Save updated profile to Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });
    
    try {
      final updatedData = {
        'weight': double.parse(_weightController.text),
        'height': double.parse(_heightController.text),
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'dietary_restrictions': _dietaryController.text.trim(),
        'fitness_goals': _goalsController.text.trim(),
      };
      
      bool success = await _authService.updateUserProfile(updatedData);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green)
        );
      } else {
        throw Exception('Profile update failed');
      }
    } catch (e, stack) {
      Logger.logError('Failed to save profile', e, stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'), 
          backgroundColor: Colors.red
        )
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildProfileForm(),
    );
  }
  
  /// Build error state view
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserProfile,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  /// Build the profile form
  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Physical Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Weight field
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight <= 0 || weight > 300) {
                  return 'Please enter a valid weight (1-300 kg)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Height field
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.height),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your height';
                }
                final height = double.tryParse(value);
                if (height == null || height <= 0 || height > 250) {
                  return 'Please enter a valid height (1-250 cm)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Age field
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your age';
                }
                final age = int.tryParse(value);
                if (age == null || age <= 0 || age > 120) {
                  return 'Please enter a valid age (1-120)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Gender selection
            Text(
              'Gender',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Male'),
                    value: 'male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Female'),
                    value: 'female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            RadioListTile<String>(
              title: const Text('Prefer not to say'),
              value: 'unknown',
              groupValue: _gender,
              onChanged: (value) {
                setState(() {
                  _gender = value!;
                });
              },
            ),
            const SizedBox(height: 32),
            
            Text(
              'Fitness Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Dietary restrictions field
            TextFormField(
              controller: _dietaryController,
              decoration: const InputDecoration(
                labelText: 'Dietary Restrictions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.food_bank),
                hintText: 'E.g., Vegetarian, Gluten-free, etc.',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Fitness goals field
            TextFormField(
              controller: _goalsController,
              decoration: const InputDecoration(
                labelText: 'Fitness Goals',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
                hintText: 'E.g., Lose weight, Build muscle, etc.',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            
            // Save button
            Center(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('SAVE PROFILE'),
              ),
            ),
            
            // Delete account option
            const SizedBox(height: 48),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  _showDeleteAccountDialog();
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show confirmation dialog for account deletion
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted. '
          'Are you sure you want to delete your account?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              // Prompt for reauthentication (for security)
              try {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.delete();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    // Navigate back to login screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              } catch (e, stack) {
                Logger.logError('Failed to delete account', e, stack);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
