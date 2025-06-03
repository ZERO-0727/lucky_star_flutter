import 'package:flutter/material.dart';

class TrustReputationPage extends StatefulWidget {
  const TrustReputationPage({super.key});

  @override
  State<TrustReputationPage> createState() => _TrustReputationPageState();
}

class _TrustReputationPageState extends State<TrustReputationPage> {
  // Mock data for trust score and references
  final int trustScore = 100;
  final String trustStatus = 'Improving';
  final int referencesCount = 12;
  final List<Map<String, dynamic>> references = [
    {
      'quote': 'Very responsive and reliable. Great experience!',
      'userName': 'Yuki T.',
      'date': 'May 15, 2025',
      'rating': 5.0,
    },
    {
      'quote': 'Helped me a lot with my Japanese studies. Highly recommended!',
      'userName': 'Michael K.',
      'date': 'April 28, 2025',
      'rating': 4.8,
    },
    {
      'quote': 'Always on time and very friendly. Would meet again!',
      'userName': 'Sophia L.',
      'date': 'April 10, 2025',
      'rating': 4.9,
    },
  ];

  final List<Map<String, dynamic>> badges = [
    {
      'icon': Icons.phone_android,
      'label': 'Phone Verified',
      'isVerified': true,
    },
    {
      'icon': Icons.email,
      'label': 'Email Verified',
      'isVerified': true,
    },
    {
      'icon': Icons.badge,
      'label': 'Gov ID Verified',
      'isVerified': false,
    },
    {
      'icon': Icons.people,
      'label': 'Social Verified',
      'isVerified': true,
    },
  ];

  final List<Map<String, dynamic>> behaviorRecords = [
    {
      'title': 'Late Response Warning',
      'description': 'You responded to messages after 24 hours on 3 occasions',
      'date': 'May 20, 2025',
      'type': 'warning', // warning, success
    },
    {
      'title': 'Perfect Month',
      'description': 'You had perfect attendance and communication for all your exchanges',
      'date': 'April 2025',
      'type': 'success',
    },
  ];

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Trust & Reputation',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trust Score Display
              _buildTrustScoreDisplay(),
              const SizedBox(height: 24),

              // References Summary
              _buildReferencesSummary(),
              const SizedBox(height: 24),

              // Verified Badges Section
              _buildVerifiedBadges(),
              const SizedBox(height: 24),

              // Trust Score Explanation
              _buildTrustScoreExplanation(),
              const SizedBox(height: 24),

              // Behavior Record
              _buildBehaviorRecord(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustScoreDisplay() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    trustScore.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7153DF),
                    ),
                  ),
                  const Text(
                    'out of 100',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              trustStatus,
              style: const TextStyle(
                color: Color(0xFF7153DF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferencesSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'References',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$referencesCount total',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...references.map((reference) => _buildReferenceItem(reference)).toList(),
      ],
    );
  }

  Widget _buildReferenceItem(Map<String, dynamic> reference) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_quote,
                color: Color(0xFF7153DF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reference['quote'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reference['userName'],
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                reference['date'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                size: 16,
                color: index < reference['rating']
                    ? const Color(0xFFFFD700)
                    : Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verified Badges',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: badge['isVerified']
                      ? const Color(0xFF7153DF).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badge['isVerified']
                          ? const Color(0xFFF5F0FF)
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      badge['icon'],
                      color: badge['isVerified']
                          ? const Color(0xFF7153DF)
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    badge['label'],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: badge['isVerified'] ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrustScoreExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How Trust Score Works',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ExpansionTile(
            title: const Text(
              'Tap to see how your score is calculated',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF7153DF),
            ),
            onExpansionChanged: (value) {
              setState(() {
                _isExpanded = value;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExplanationItem(
                      'Verified Personal Information',
                      'Having verified contact information, government ID, and social accounts increases your trust score.',
                    ),
                    _buildExplanationItem(
                      'Positive References',
                      'Each positive reference from other users adds to your trust score.',
                    ),
                    _buildExplanationItem(
                      'Transaction History',
                      'Successful completion of exchanges and activities improves your score.',
                    ),
                    _buildExplanationItem(
                      'Response Time',
                      'Quick responses to messages and requests positively impact your score.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF7153DF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorRecord() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Behavior Record',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...behaviorRecords.map((record) => _buildBehaviorRecordItem(record)).toList(),
      ],
    );
  }

  Widget _buildBehaviorRecordItem(Map<String, dynamic> record) {
    final bool isWarning = record['type'] == 'warning';
    final Color backgroundColor = isWarning
        ? const Color(0xFFFFF9E6)
        : const Color(0xFFEDF9F0);
    final Color iconColor = isWarning
        ? const Color(0xFFFFB800)
        : const Color(0xFF4CAF50);
    final IconData iconData = isWarning
        ? Icons.warning_amber_rounded
        : Icons.check_circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record['description'],
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record['date'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
