import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/profile_service.dart';
import '../../screens/main_screen.dart'; // Fixed import
import 'aadhaar_validation_screen.dart';
import 'pan_validation_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();

  String? _selectedState;
  String? _selectedCity;
  String? _selectedBusinessType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingProfile();
    });
  }

  Future<void> _loadExistingProfile() async {
    final profileService = context.read<ProfileService>();
    await profileService.loadUserProfile();

    final profile = profileService.userProfile;
    if (profile != null && mounted) {
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _businessNameController.text = profile['business_name'] ?? '';
        // Fix: Ensure values match dropdown items (lowercase) to prevent crash
        String? type = profile['business_type']?.toString().toLowerCase();

        // Handle legacy value mapping
        if (type == 'retail_shop') type = 'retail';

        // Only set if it exists in our list
        if (_businessTypes.contains(type)) {
          _selectedBusinessType = type;
        } else {
          _selectedBusinessType = null; // Clear if invalid to prevent crash
        }

        // Validate state exists in list, else null
        String? state = profile['location']?['state']?.toString().toLowerCase();
        if (_states.contains(state)) {
          _selectedState = state;
        }

        // Validate city exists in map, else null
        String? city = profile['location']?['city']?.toString().toLowerCase();
        if (state != null && _cities[state]?.contains(city) == true) {
          _selectedCity = city;
        }
      });
    }
  }

  final _states = ['karnataka', 'maharashtra', 'delhi'];
  final Map<String, List<String>> _cities = {
    'karnataka': ['bengaluru', 'mysuru', 'mangaluru'],
    'maharashtra': ['mumbai', 'pune', 'nagpur'],
    'delhi': ['new_delhi', 'south_delhi'],
  };
  final _businessTypes = [
    'retail', // retail_shop maps to this
    'food_beverage',
    'service_provider',
    'manufacturing'
  ];

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'location': {
          'state': _selectedState,
          'city': _selectedCity,
        },
        'business_type': _selectedBusinessType,
        'profile_completed': true,
      });

      if (mounted) {
        // Navigate to MainScreen (which holds Dashboard) to ensure proper Scaffold structure
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell us about your business',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This helps us show you relevant compliance requirements',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                initialValue: _selectedState,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _states.map((state) {
                  return DropdownMenuItem(
                    value: state,
                    child: Text(state.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                    _selectedCity = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a state' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _selectedState == null
                    ? []
                    : _cities[_selectedState]!.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city.replaceAll('_', ' ').toUpperCase()),
                        );
                      }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a city' : null,
              ),
              const SizedBox(height: 16),

              // Verification Section
              const Text(
                'Identity Verification (Recommended)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AadhaarValidationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.credit_card),
                label: const Text('Verify Aadhaar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PANValidationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.badge),
                label: const Text('Verify PAN'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _selectedBusinessType,
                decoration: InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _businessTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBusinessType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a business type' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleComplete,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Complete Setup',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
