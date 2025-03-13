import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  final FirebaseService _firebaseService = FirebaseService();
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _selectedGender = 'male';
  final List<String> _genderOptions = ['male', 'female', 'other'];
  String _selectedActivityLevel = 'moderate';
  final Map<String, String> _activityLevelOptions = {
    'sedentary': 'Sedentary (little or no exercise)',
    'light': 'Light (light exercise 1-3 days/week)',
    'moderate': 'Moderate (moderate exercise 3-5 days/week)',
    'active': 'Active (hard exercise 6-7 days/week)',
    'very_active': 'Very Active (hard daily exercise & physical job)',
  };
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Load user profile if not already loaded
      if (userProvider.userProfile == null) {
        await userProvider.loadUserProfile();
      }
      
      final userProfile = userProvider.userProfile;
      
      if (userProfile != null) {
        _nameController.text = userProfile['name'] ?? '';
        _ageController.text = userProfile['age']?.toString() ?? '';
        
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        final isMetric = settingsProvider.useMetricSystem;
        
        // Handle weight based on unit system
        if (userProfile['weight'] != null) {
          double weight = userProfile['weight'].toDouble();
          if (!isMetric) {
            // Convert kg to lbs for display
            weight = AppHelpers.kgToLbs(weight);
          }
          _weightController.text = weight.toStringAsFixed(1);
        }
        
        // Handle height based on unit system
        if (userProfile['height'] != null) {
          double height = userProfile['height'].toDouble();
          if (!isMetric) {
            // Convert cm to in for display
            height = AppHelpers.cmToIn(height);
          }
          _heightController.text = height.toStringAsFixed(1);
        }
        
        _selectedGender = userProfile['gender'] ?? 'male';
        _selectedActivityLevel = userProfile['activityLevel'] ?? 'moderate';
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user profile: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _updateUserProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final isMetric = settingsProvider.useMetricSystem;
      
      // Parse form values
      final name = _nameController.text.trim();
      int? age;
      double? weight;
      double? height;
      
      if (_ageController.text.isNotEmpty) {
        age = int.parse(_ageController.text);
      }
      
      if (_weightController.text.isNotEmpty) {
        weight = double.parse(_weightController.text);
        
        // Convert lbs to kg for storage if using imperial
        if (!isMetric) {
          weight = AppHelpers.lbsToKg(weight);
        }
      }
      
      if (_heightController.text.isNotEmpty) {
        height = double.parse(_heightController.text);
        
        // Convert inches to cm for storage if using imperial
        if (!isMetric) {
          height = AppHelpers.inToCm(height);
        }
      }
      
      // Create profile data
      final profileData = {
        'name': name,
        'gender': _selectedGender,
        'age': age,
        'weight': weight,
        'height': height,
        'activityLevel': _selectedActivityLevel,
        'updatedAt': DateTime.now(),
      };
      
      // Save to Firebase
      await _firebaseService.updateUserProfile(userId, profileData);
      
      // Update user provider
      await userProvider.loadUserProfile();
      
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating user profile: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isMetric = settingsProvider.useMetricSystem;
    final weightUnit = isMetric ? AppConstants.unitKg : AppConstants.unitLbs;
    final heightUnit = isMetric ? AppConstants.unitCm : AppConstants.unitIn;
    
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final userProfile = userProvider.userProfile;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading profile...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text
                                      : 'User',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (user?.email != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    user!.email!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Member since ${user?.metadata.creationTime != null ? DateFormat.yMMMd().format(user!.metadata.creationTime!) : 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile form or display
                  _isEditing
                      ? _buildProfileForm(isMetric, weightUnit, heightUnit)
                      : _buildProfileInfo(isMetric, weightUnit, heightUnit),
                ],
              ),
            ),
      bottomNavigationBar: _isEditing
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _loadUserProfile();  // Reset form values
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        label: 'Save',
                        onPressed: _updateUserProfile,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
  
  Widget _buildProfileForm(bool isMetric, String weightUnit, String heightUnit) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),
          
          // Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Gender
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people),
            ),
            items: _genderOptions.map((gender) {
              String label = gender.substring(0, 1).toUpperCase() + gender.substring(1);
              
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedGender = value);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Age
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.cake),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                try {
                  final age = int.parse(value);
                  if (age <= 0 || age > 120) {
                    return 'Please enter a valid age';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Body Measurements',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),
          
          // Weight
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Weight',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.monitor_weight),
              suffixText: weightUnit,
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                try {
                  final weight = double.parse(value);
                  if (weight <= 0) {
                    return 'Weight must be greater than 0';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Height
          TextFormField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Height',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.height),
              suffixText: heightUnit,
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                try {
                  final height = double.parse(value);
                  if (height <= 0) {
                    return 'Height must be greater than 0';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Lifestyle',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),
          
          // Activity Level
          DropdownButtonFormField<String>(
            value: _selectedActivityLevel,
            decoration: const InputDecoration(
              labelText: 'Activity Level',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.fitness_center),
            ),
            items: _activityLevelOptions.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedActivityLevel = value);
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildProfileInfo(bool isMetric, String weightUnit, String heightUnit) {
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = userProvider.userProfile;
    
    if (userProfile == null) {
      return const Center(
        child: Text('No profile information available'),
      );
    }
    
    // Format values for display
    String genderDisplay = '';
    if (userProfile['gender'] != null) {
      genderDisplay = userProfile['gender'].toString();
      genderDisplay = genderDisplay.substring(0, 1).toUpperCase() + genderDisplay.substring(1);
    }
    
    String ageDisplay = userProfile['age'] != null ? '${userProfile['age']} years' : 'Not specified';
    
    String weightDisplay = 'Not specified';
    if (userProfile['weight'] != null) {
      double weight = userProfile['weight'].toDouble();
      if (!isMetric) {
        weight = AppHelpers.kgToLbs(weight);
      }
      weightDisplay = '${weight.toStringAsFixed(1)} $weightUnit';
    }
    
    String heightDisplay = 'Not specified';
    if (userProfile['height'] != null) {
      double height = userProfile['height'].toDouble();
      if (!isMetric) {
        height = AppHelpers.cmToIn(height);
      }
      heightDisplay = '${height.toStringAsFixed(1)} $heightUnit';
    }
    
    String activityLevelDisplay = 'Not specified';
    if (userProfile['activityLevel'] != null) {
      activityLevelDisplay = _activityLevelOptions[userProfile['activityLevel']] ?? 'Not specified';
    }
    
    // Calculate BMI if weight and height are available
    String bmiDisplay = 'Not available';
    String bmiCategory = '';
    if (userProfile['weight'] != null && userProfile['height'] != null) {
      final weight = userProfile['weight'].toDouble();
      final height = userProfile['height'].toDouble() / 100; // cm to m
      
      final bmi = weight / (height * height);
      bmiDisplay = bmi.toStringAsFixed(1);
      
      if (bmi < 18.5) {
        bmiCategory = 'Underweight';
      } else if (bmi < 25) {
        bmiCategory = 'Normal weight';
      } else if (bmi < 30) {
        bmiCategory = 'Overweight';
      } else {
        bmiCategory = 'Obese';
      }
    }
    
    // Calculate daily calorie needs if all required fields are available
    String calorieNeedsDisplay = 'Not available';
    if (userProfile['weight'] != null && 
        userProfile['height'] != null && 
        userProfile['age'] != null &&
        userProfile['gender'] != null &&
        userProfile['activityLevel'] != null) {
      
      final calorieNeeds = userProvider.getUserDailyCalorieNeeds();
      if (calorieNeeds != null) {
        calorieNeedsDisplay = '$calorieNeeds kcal';
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          InfoItem(label: 'Gender', value: genderDisplay),
          InfoItem(label: 'Age', value: ageDisplay),
        ]),
        const SizedBox(height: 24),
        
        const Text(
          'Body Measurements',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          InfoItem(label: 'Weight', value: weightDisplay),
          InfoItem(label: 'Height', value: heightDisplay),
          InfoItem(label: 'BMI', value: '$bmiDisplay ($bmiCategory)'),
        ]),
        const SizedBox(height: 24),
        
        const Text(
          'Lifestyle',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          InfoItem(label: 'Activity Level', value: activityLevelDisplay),
          InfoItem(label: 'Daily Calorie Needs', value: calorieNeedsDisplay),
        ]),
        const SizedBox(height: 32),
        
        // Edit button
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Edit Profile',
            icon: Icons.edit,
            onPressed: () {
              setState(() => _isEditing = true);
            },
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoCard(List<InfoItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${item.label}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.value.isNotEmpty ? item.value : 'Not specified',
                      style: TextStyle(
                        color: item.value.isNotEmpty ? null : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class InfoItem {
  final String label;
  final String value;
  
  InfoItem({required this.label, required this.value});
}