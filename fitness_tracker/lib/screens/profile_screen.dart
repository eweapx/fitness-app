import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController(text: '35');
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '70');
  
  String _selectedGender = 'Male';
  String _selectedActivityLevel = 'Moderately Active';
  
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extremely Active',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Set name and email from user provider
    _nameController.text = userProvider.userName ?? '';
    _emailController.text = userProvider.user?.email ?? '';
    
    // Set other profile data from profile data if available
    final profile = userProvider.userProfile;
    if (profile != null) {
      setState(() {
        _ageController.text = (profile['age'] ?? 35).toString();
        _heightController.text = (profile['height'] ?? 175).toString();
        _weightController.text = (profile['weight'] ?? 70).toString();
        _selectedGender = profile['gender'] ?? 'Male';
        _selectedActivityLevel = profile['activityLevel'] ?? 'Moderately Active';
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final useMetric = settingsProvider.useMetricUnits;
    
    // Convert values as needed
    int height;
    double weight;
    
    if (useMetric) {
      height = int.tryParse(_heightController.text) ?? 175;
      weight = double.tryParse(_weightController.text) ?? 70.0;
    } else {
      // Convert imperial to metric
      final heightStr = _heightController.text;
      height = heightStr.contains("'") 
        ? AppHelpers.imperialHeightToCm(heightStr) 
        : 175;
      
      weight = AppHelpers.lbsToKg(double.tryParse(_weightController.text) ?? 154.0);
    }
    
    final data = {
      'age': int.tryParse(_ageController.text) ?? 35,
      'height': height,
      'weight': weight,
      'gender': _selectedGender,
      'activityLevel': _selectedActivityLevel,
      'bmr': AppHelpers.calculateBasalMetabolicRate(
        int.tryParse(_ageController.text) ?? 35,
        _selectedGender,
        weight,
        height,
      ),
      'bmi': AppHelpers.calculateBMI(weight, height),
    };
    
    final success = await userProvider.updateUserProfile(data);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final useMetric = settingsProvider.useMetricUnits;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
              // TODO: Implement settings screen navigation
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header with Avatar
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      backgroundImage: _getProfileImage(),
                      child: _getProfileImage() == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userProvider.userName ?? 'User',
                      style: AppTextStyles.heading2,
                    ),
                    Text(
                      userProvider.user?.email ?? '',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Personal Information Section
              Text(
                'Personal Information',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
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
              
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                readOnly: true, // Email is typically not editable after signup
                enabled: false,
              ),
              const SizedBox(height: 24),
              
              // Physical Details Section
              Text(
                'Physical Details',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              
              // Age field
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 120) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Gender selection
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.people),
                ),
                items: _genders.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGender = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Height field
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: useMetric ? 'Height (cm)' : 'Height (ft\'in")',
                  prefixIcon: const Icon(Icons.height),
                  hintText: useMetric ? 'e.g. 175' : 'e.g. 5\'9"',
                ),
                keyboardType: useMetric ? TextInputType.number : TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  if (useMetric) {
                    final height = int.tryParse(value);
                    if (height == null || height < 50 || height > 300) {
                      return 'Please enter a valid height in cm';
                    }
                  }
                  // For imperial we would need more complex validation
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Weight field
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: useMetric ? 'Weight (kg)' : 'Weight (lbs)',
                  prefixIcon: const Icon(Icons.fitness_center),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 1) {
                    return 'Please enter a valid weight';
                  }
                  if (useMetric && (weight < 20 || weight > 300)) {
                    return 'Please enter a valid weight in kg';
                  }
                  if (!useMetric && (weight < 40 || weight > 660)) {
                    return 'Please enter a valid weight in lbs';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Activity Level Section
              Text(
                'Activity Level',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              
              // Activity level selection
              DropdownButtonFormField<String>(
                value: _selectedActivityLevel,
                decoration: const InputDecoration(
                  labelText: 'Activity Level',
                  prefixIcon: Icon(Icons.directions_run),
                ),
                items: _activityLevels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedActivityLevel = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Activity level description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_getActivityLevelDescription(_selectedActivityLevel)),
              ),
              const SizedBox(height: 32),
              
              // Nutritional Info Section
              Text(
                'Nutritional Information',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              
              // BMI display
              _buildInfoCard(
                'BMI',
                _calculateBMI().toStringAsFixed(1),
                _getBMICategory(_calculateBMI()),
                Icons.monitor_weight,
                _getBMIColor(_calculateBMI()),
              ),
              const SizedBox(height: 12),
              
              // Daily calorie needs
              _buildInfoCard(
                'Daily Calorie Needs',
                _calculateCalorieNeeds().toString(),
                'Based on your profile',
                Icons.local_fire_department,
                Colors.orange,
              ),
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('SAVE PROFILE'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  ImageProvider? _getProfileImage() {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.userPhotoUrl != null) {
      return NetworkImage(userProvider.userPhotoUrl!);
    }
    return null;
  }
  
  String _getActivityLevelDescription(String level) {
    switch (level) {
      case 'Sedentary':
        return 'Little to no exercise, desk job';
      case 'Lightly Active':
        return 'Light exercise 1-3 days per week';
      case 'Moderately Active':
        return 'Moderate exercise 3-5 days per week';
      case 'Very Active':
        return 'Hard exercise 6-7 days per week';
      case 'Extremely Active':
        return 'Very hard exercise, physical job or training twice a day';
      default:
        return '';
    }
  }
  
  double _calculateBMI() {
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final useMetric = settingsProvider.useMetricUnits;
      
      double height;
      double weight;
      
      if (useMetric) {
        height = double.tryParse(_heightController.text) ?? 175.0;
        weight = double.tryParse(_weightController.text) ?? 70.0;
      } else {
        // For non-metric, use a default height for placeholder purposes
        height = 175.0; // Default to 5'9" in cm
        
        // Convert weight from lbs to kg
        weight = AppHelpers.lbsToKg(double.tryParse(_weightController.text) ?? 154.0);
      }
      
      return AppHelpers.calculateBMI(weight, height.round());
    } catch (e) {
      return 0;
    }
  }
  
  String _getBMICategory(double bmi) {
    return AppHelpers.getBMICategory(bmi);
  }
  
  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.blue;
    } else if (bmi < 25) {
      return Colors.green;
    } else if (bmi < 30) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }
  
  int _calculateCalorieNeeds() {
    try {
      final age = int.tryParse(_ageController.text) ?? 35;
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final useMetric = settingsProvider.useMetricUnits;
      
      double weight;
      int height;
      
      if (useMetric) {
        weight = double.tryParse(_weightController.text) ?? 70.0;
        height = int.tryParse(_heightController.text) ?? 175;
      } else {
        weight = AppHelpers.lbsToKg(double.tryParse(_weightController.text) ?? 154.0);
        height = 175; // Default to 5'9" in cm
      }
      
      // Calculate BMR using the Mifflin-St Jeor Equation
      final bmr = AppHelpers.calculateBasalMetabolicRate(
        age, 
        _selectedGender, 
        weight, 
        height
      );
      
      // Apply activity multiplier
      return AppHelpers.calculateTotalDailyEnergyExpenditure(
        bmr, 
        _selectedActivityLevel
      );
    } catch (e) {
      return 2000; // Default value if calculation fails
    }
  }
  
  Widget _buildInfoCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}