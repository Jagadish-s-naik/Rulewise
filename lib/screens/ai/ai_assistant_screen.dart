import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ai_service.dart';
import '../../services/compliance_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_plan.dart';
import '../../models/license_model.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final AIService _aiService = AIService();

  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  List<LicenseModel> _applicableLicenses = [];

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Load user profile
      final complianceService = context.read<ComplianceService>();
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (profileDoc.exists) {
        _userProfile = profileDoc.data();

        // Load applicable licenses
        if (!mounted) return;
        await complianceService.fetchApplicableLicenses(
          state: _userProfile!['location']['state'],
          city: _userProfile!['location']['city'],
          businessType: _userProfile!['business_type'],
        );

        setState(() {
          _applicableLicenses = complianceService.applicableLicenses;
        });

        // Add welcome message
        _addMessage(ChatMessage(
          text:
              'Hello! I\'m your RuleWise AI assistant. I have access to your business profile and all ${_applicableLicenses.length} applicable licenses for your ${_formatBusinessType(_userProfile!['business_type'])} in ${_formatLocation(_userProfile!['location']['city'])}.\n\nHow can I help you today?',
          isUser: false,
        ));
      }
    } catch (e) {
      _addMessage(ChatMessage(
        text:
            'Unable to load your profile. Please ensure you\'ve completed profile setup.',
        isUser: false,
      ));
    }
  }

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    // Check AI query limit
    final subscriptionService = context.read<SubscriptionService>();
    if (!subscriptionService.canUseAI()) {
      final tier = subscriptionService.currentTier;
      final limit = tier.aiQueriesPerWeek;
      _addMessage(ChatMessage(
        text:
            '🚫 AI Query Limit Reached\n\nYou\'ve used all $limit queries this week on the ${tier.name} plan.\n\nUpgrade your plan to get more AI queries!',
        isUser: false,
      ));
      return;
    }

    _addMessage(ChatMessage(text: question, isUser: true));
    _questionController.clear();

    setState(() => _isLoading = true);

    try {
      final response = await _aiService.askQuestion(
        question: question,
        userProfile: _userProfile ?? {},
        applicableLicenses: _applicableLicenses,
      );

      _addMessage(ChatMessage(text: response, isUser: false));

      // Increment AI usage after successful query
      await subscriptionService.incrementAIUsage();
    } catch (e) {
      _addMessage(ChatMessage(
        text: 'Error: Unable to get response. Please try again.',
        isUser: false,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatBusinessType(String type) {
    final Map<String, String> typeNames = {
      'retail_shop': 'Retail Shop',
      'food_beverage': 'Food & Beverage',
      'service_provider': 'Service Provider',
      'manufacturing': 'Manufacturing',
    };
    return typeNames[type] ?? type;
  }

  String _formatLocation(String location) {
    return location.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final businessInfo = _userProfile != null
        ? '${_formatBusinessType(_userProfile!['business_type'])} • ${_formatLocation(_userProfile!['location']['city'])}'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Assistant',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (businessInfo.isNotEmpty)
              Text(
                businessInfo,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About AI Assistant',
            onPressed: () => _showAboutDialog(),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Context indicator
          if (_applicableLicenses.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                border: Border(
                  bottom: BorderSide(color: Colors.blue[100]!),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.psychology,
                        color: Colors.blue[700], size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Analyzing ${_applicableLicenses.length} licenses for your specific profile',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.chat_bubble_outline_rounded,
                              size: 48, color: Colors.blue[400]),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'How can I help you today?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask about licenses, compliance, or regulations',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 32),
                        // Suggested questions
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildSuggestionChip('Available licenses?'),
                            _buildSuggestionChip('Application process?'),
                            _buildSuggestionChip('Renewal fees?'),
                          ],
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: _messages[index]);
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thinking...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendQuestion(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendQuestion,
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      tooltip: 'Send',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey[200]!),
      labelStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onPressed: () {
        _questionController.text = label;
        _sendQuestion();
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About AI Assistant'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This AI assistant has access to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeaturePoint('Your business profile'),
            _buildFeaturePoint(
                '${_applicableLicenses.length} applicable licenses'),
            _buildFeaturePoint('Government fees and requirements'),
            _buildFeaturePoint('Application portals and helplines'),
            const SizedBox(height: 16),
            const Text(
              'It provides personalized guidance based on your specific business type and location.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
  }) : timestamp = DateTime.now();
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment:
            CrossAxisAlignment.end, // Align to bottom for avatar
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(Icons.psychology, color: Colors.blue[600], size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: message.isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color:
                      message.isUser ? Colors.white : const Color(0xFF1E293B),
                  height: 1.4,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            // User avatar (placeholder)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE2E8F0),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF64748B),
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
