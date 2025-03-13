import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Track Your Activities',
      description: 'Record your workouts, runs, walks and other physical activities. Monitor your progress over time.',
      image: 'assets/images/onboarding_activity.png',
      color: AppColors.running,
      icon: Icons.directions_run,
    ),
    OnboardingPage(
      title: 'Monitor Your Nutrition',
      description: 'Track your meals, water intake and calories. Stay on top of your nutritional goals.',
      image: 'assets/images/onboarding_nutrition.png',
      color: AppColors.carbs,
      icon: Icons.restaurant_menu,
    ),
    OnboardingPage(
      title: 'Optimize Your Sleep',
      description: 'Log your sleep patterns and quality. Improve your rest for better overall health.',
      image: 'assets/images/onboarding_sleep.png',
      color: Colors.indigo,
      icon: Icons.nightlight,
    ),
    OnboardingPage(
      title: 'Build Healthy Habits',
      description: 'Create and maintain healthy habits. Break bad ones. Track your streaks and celebrate milestones.',
      image: 'assets/images/onboarding_habits.png',
      color: AppColors.tertiary,
      icon: Icons.repeat,
    ),
    OnboardingPage(
      title: 'Visualize Your Progress',
      description: 'See your health journey with detailed charts and analytics. Gain insights to improve your fitness.',
      image: 'assets/images/onboarding_progress.png',
      color: AppColors.primary,
      icon: Icons.bar_chart,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
          _isLastPage = page == _pages.length - 1;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isLastPage = page == _pages.length - 1;
    });
  }
  
  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  Future<void> _completeOnboarding() async {
    // Save that onboarding is completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);
    
    // Navigate to login screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Skip'),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon or image
                        if (page.image != null) ...[
                          // Try to load image, if not available, show icon
                          Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              color: page.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              page.icon,
                              size: 100,
                              color: page.color,
                            ),
                          ),
                        ] else ...[
                          Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              color: page.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              page.icon,
                              size: 100,
                              color: page.color,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        
                        // Title
                        Text(
                          page.title,
                          style: AppTextStyles.heading2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          page.description,
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AppButton(
                label: _isLastPage ? 'Get Started' : 'Next',
                icon: _isLastPage ? Icons.rocket_launch : Icons.arrow_forward,
                onPressed: _nextPage,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String? image;
  final Color color;
  final IconData icon;
  
  OnboardingPage({
    required this.title,
    required this.description,
    this.image,
    required this.color,
    required this.icon,
  });
}