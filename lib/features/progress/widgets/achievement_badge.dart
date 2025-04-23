import 'package:flutter/material.dart';
import '../../../common/constants/colors.dart';

class AchievementBadge extends StatelessWidget {
  final String title;
  final String description;
  final String? date;
  final IconData icon;
  final Color color;
  final bool unlocked;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    required this.color,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: unlocked ? color.withOpacity(0.1) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: unlocked ? color : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: unlocked ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (unlocked && date != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWineRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            date!,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryWineRed,
                            ),
                          ),
                        ),
                      if (!unlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Locked',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: unlocked ? Colors.grey[600] : Colors.grey[500],
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