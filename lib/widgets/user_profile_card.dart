import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final bool showDetailedStats;

  const UserProfileCard({
    Key? key,
    required this.user,
    this.onTap,
    this.showDetailedStats = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar, name, and status badge
              _buildHeader(),
              const SizedBox(height: 12),

              // Location
              if (user.location.isNotEmpty) _buildLocation(),
              if (user.location.isNotEmpty) const SizedBox(height: 12),

              // Statistics
              _buildStatistics(),
              const SizedBox(height: 12),

              // Languages
              if (user.languages.isNotEmpty) _buildLanguages(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[300],
          backgroundImage:
              user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
          child:
              user.avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
        ),
        const SizedBox(width: 12),

        // Name and status label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user.isVerified)
                Row(
                  children: [
                    const Icon(Icons.verified, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Verified User',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Status badge
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    switch (user.status) {
      case 'Available':
        badgeColor = Colors.green;
        break;
      case 'Limited':
        badgeColor = Colors.orange;
        break;
      case 'Unavailable':
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        user.status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          user.location,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(user.experiencesCount.toString(), 'Experiences'),
        _buildStatItem(
          user.wishesFullfilledCount.toString(),
          'Wishes Fulfilled',
        ),
        _buildStatItem('${user.responseRate}%', 'Response Rate'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLanguages() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          user.languages.map((language) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(language, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
    );
  }
}
