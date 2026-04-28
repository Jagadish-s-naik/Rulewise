import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import '../../screens/main_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import 'aadhaar_validation_screen.dart';
import 'pan_validation_screen.dart';
import 'gst_validation_screen.dart';

class ProfileCompletionWizard extends StatefulWidget {
  const ProfileCompletionWizard({super.key});

  @override
  State<ProfileCompletionWizard> createState() =>
      _ProfileCompletionWizardState();
}

class _ProfileCompletionWizardState extends State<ProfileCompletionWizard> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileService = context.read<ProfileService>();
    await profileService.loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        elevation: 0,
      ),
      body: Consumer<ProfileService>(
        builder: (context, profileService, _) {
          if (profileService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final completionPercentage = profileService.getCompletionPercentage();
          final missingFields = profileService.getMissingFields();
          final isComplete = profileService.isProfileComplete();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Profile Completion',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${completionPercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: completionPercentage / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completionPercentage >= 100
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (!isComplete) ...[
                  const Text(
                    'Complete These Steps',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Missing Fields
                  ...missingFields.map((field) {
                    return _buildStepCard(
                      title: _getFieldTitle(field),
                      description: _getFieldDescription(field),
                      isComplete: false,
                      onTap: () => _handleFieldAction(field),
                    );
                  }),
                ] else ...[
                  // All Complete
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Colors.green[600],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Profile Complete!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can now access your compliance dashboard',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DashboardScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Go to Dashboard',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const MainScreen(),
              ),
            );
          },
          child: const Text(
            'Skip for Now',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String title,
    required String description,
    required bool isComplete,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isComplete ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _getFieldTitle(String field) {
    switch (field) {
      case 'aadhaar_verified':
        return 'Verify Aadhaar';
      case 'pan_verified':
        return 'Verify PAN';
      case 'business_name':
        return 'Add Business Name';
      case 'business_type':
        return 'Select Business Type';
      case 'state':
        return 'Select State';
      case 'city':
        return 'Select City';
      default:
        return field;
    }
  }

  String _getFieldDescription(String field) {
    switch (field) {
      case 'aadhaar_verified':
        return 'Verify your identity with Aadhaar';
      case 'pan_verified':
        return 'Verify your PAN for tax compliance';
      case 'business_name':
        return 'Enter your business name';
      case 'business_type':
        return 'Choose your business category';
      case 'state':
        return 'Select your business state';
      case 'city':
        return 'Select your business city';
      default:
        return 'Complete this field';
    }
  }

  Future<void> _handleFieldAction(String field) async {
    switch (field) {
      case 'aadhaar_verified':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AadhaarValidationScreen(),
          ),
        );
        if (result == true && mounted) {
          setState(() {});
        }
        break;
      case 'pan_verified':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PANValidationScreen(),
          ),
        );
        if (result == true && mounted) {
          setState(() {});
        }
        break;
      case 'business_name':
      case 'gst_verified':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GSTValidationScreen(),
          ),
        );
        if (result == true && mounted) {
          setState(() {});
        }
        break;
      default:
        // Navigate to profile setup for other fields
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete this in Profile Setup'),
          ),
        );
    }
  }
}
