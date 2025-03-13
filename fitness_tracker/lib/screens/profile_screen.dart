import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _gender = '';
  DateTime? _dateOfBirth;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _activityLevel = 'moderate';
  final _bioController = TextEditingController();
  File? _profileImage;
  
  final Map<String, String> _activityLevelLabels = {
    'sedentary': 'Sedentary (little or no exercise)',
    'light': 'Lightly active (light exercise 1-3 days/week)',
    'moderate': 'Moderately active (moderate exercise 3-5 days/week)',
    'active': 'Very active (hard exercise 6-7 days/week)',
    'very_active': 'Extra active (very hard exercise, physical job, or training 2x/day)',
  };
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      final userProfile = userProvider.userProfile;
      
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        
        if (userProfile != null) {
          _gender = userProfile['gender'] ?? '';
          
          if (userProfile['dateOfBirth'] != null) {
            _dateOfBirth = userProfile['dateOfBirth'].toDate();
          }
          
          if (userProfile['height'] != null) {
            final isMetric = Provider.of<SettingsProvider>(context, listen: false).useMetricSystem;
            final height = userProfile['height'] as num;
            
            if (isMetric) {
              _heightController.text = height.toString();
            } else {
              // Convert cm to feet and inches
              final feetAndInches = AppHelpers.cmToFtIn(height.toDouble());
              final feet = feetAndInches['feet'] ?? 0;
              final inches = feetAndInches['inches'] ?? 0;
              _heightController.text = '$feet\'$inches"';
            }
          }
          
          if (userProfile['weight'] != null) {
            final isMetric = Provider.of<SettingsProvider>(context, listen: false).useMetricSystem;
            final weight = userProfile['weight'] as num;
            
            if (isMetric) {
              _weightController.text = weight.toString();
            } else {
              // Convert kg to lbs
              final weightLbs = AppHelpers.kgToLbs(weight.toDouble());
              _weightController.text = weightLbs.toStringAsFixed(1);
            }
          }
          
          _activityLevel = userProfile['activityLevel'] ?? 'moderate';
          _bioController.text = userProfile['bio'] ?? '';
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user != null) {
        // Prepare data
        final Map<String, dynamic> data = {};
        
        // Basic info
        if (_nameController.text.isNotEmpty && _nameController.text != user.displayName) {
          // Update display name in Firebase Auth
          await user.updateDisplayName(_nameController.text);
          data['displayName'] = _nameController.text;
        }
        
        // Other profile data
        data['gender'] = _gender;
        data['dateOfBirth'] = _dateOfBirth;
        data['bio'] = _bioController.text;
        data['activityLevel'] = _activityLevel;
        
        // Height
        if (_heightController.text.isNotEmpty) {
          final isMetric = Provider.of<SettingsProvider>(context, listen: false).useMetricSystem;
          if (isMetric) {
            // Metric: value is already in cm
            data['height'] = double.parse(_heightController.text);
          } else {
            // Imperial: convert from feet'inches" to cm
            final heightText = _heightController.text;
            if (heightText.contains('\'')) {
              final parts = heightText.split('\'');
              final feet = int.parse(parts[0]);
              int inches = 0;
              
              if (parts.length > 1 && parts[1].isNotEmpty) {
                // Remove the trailing " if present
                final inchesText = parts[1].replaceAll('"', '');
                inches = int.parse(inchesText);
              }
              
              data['height'] = AppHelpers.ftInToCm(feet, inches);
            }
          }
        }
        
        // Weight
        if (_weightController.text.isNotEmpty) {
          final isMetric = Provider.of<SettingsProvider>(context, listen: false).useMetricSystem;
          if (isMetric) {
            // Metric: value is already in kg
            data['weight'] = double.parse(_weightController.text);
          } else {
            // Imperial: convert from lbs to kg
            data['weight'] = AppHelpers.lbsToKg(double.parse(_weightController.text));
          }
        }
        
        // Update profile
        await userProvider.updateUserProfile(data);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error saving profile: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _selectDate() async {
    final initialDate = _dateOfBirth ?? DateTime(2000);
    final firstDate = DateTime(1900);
    final lastDate = DateTime.now();
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    
    if (pickedDate != null) {
      setState(() => _dateOfBirth = pickedDate);
    }
  }
  
  Future<void> _selectProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
      
      // TODO: Implement image upload to Firebase Storage
      // This would be handled in a real app
    }
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    
    return DateFormat('MMMM d, yyyy').format(date);
  }
  
  @override
  Widget build(BuildContext context) {
    final isMetric = Provider.of<SettingsProvider>(context).useMetricSystem;
    final user = Provider.of<UserProvider>(context).user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading profile...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
                            child: user?.photoURL == null && _profileImage == null
                                ? Text(
                                    (_nameController.text.isNotEmpty ? _nameController.text[0] : 'U').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _selectProfilePicture,
                                tooltip: 'Change profile picture',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Basic information section
                    const Text(
                      'Basic Information',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter your full name',
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
                    
                    // Email (read-only)
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                        hintText: 'Your email address',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Gender
                    DropdownButtonFormField<String>(
                      value: _gender.isNotEmpty ? _gender : null,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      hint: const Text('Select your gender'),
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                        DropdownMenuItem(
                          value: 'prefer_not_to_say',
                          child: Text('Prefer not to say'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _gender = value ?? '');
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date of birth
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(_dateOfBirth)),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Body measurements section
                    const Text(
                      'Body Measurements',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Height
                    TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height',
                        hintText: isMetric ? 'Enter your height in cm' : 'Enter your height (e.g. 5\'10")',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.height),
                        suffixText: isMetric ? 'cm' : '',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your height';
                        }
                        
                        if (isMetric) {
                          // For metric, validate the number
                          final height = double.tryParse(value);
                          if (height == null || height <= 0 || height > 300) {
                            return 'Please enter a valid height';
                          }
                        } else {
                          // For imperial, validate the format (e.g., 5'10")
                          if (!value.contains('\'')) {
                            return 'Please use the format: feet\'inches" (e.g., 5\'10")';
                          }
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Weight
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight',
                        hintText: isMetric ? 'Enter your weight in kg' : 'Enter your weight in lbs',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.monitor_weight),
                        suffixText: isMetric ? 'kg' : 'lbs',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your weight';
                        }
                        
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0 || weight > 500) {
                          return 'Please enter a valid weight';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Activity level section
                    const Text(
                      'Activity Level',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Activity level radio buttons
                    ...['sedentary', 'light', 'moderate', 'active', 'very_active'].map((level) {
                      return RadioListTile<String>(
                        title: Text(_activityLevelLabels[level]!),
                        value: level,
                        groupValue: _activityLevel,
                        onChanged: (value) {
                          setState(() => _activityLevel = value ?? 'moderate');
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    
                    // Bio section
                    const Text(
                      'About You',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Bio
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us a bit about yourself and your fitness goals',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Save Profile',
                        icon: Icons.save,
                        onPressed: _saveProfile,
                        isFullWidth: true,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}