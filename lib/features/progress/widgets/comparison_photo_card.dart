import 'package:flutter/material.dart';
import '../../../common/constants/colors.dart';

class ComparisonPhotoCard extends StatelessWidget {
  final String date;
  final String beforeImagePath;
  final String? afterImagePath;
  final String caption;

  const ComparisonPhotoCard({
    super.key,
    required this.date,
    required this.beforeImagePath,
    required this.afterImagePath,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.photo_camera,
                      color: AppColors.primaryWineRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Progress Photos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Photo comparison
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Before',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          beforeImagePath,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'After',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: afterImagePath != null
                            ? Image.asset(
                                afterImagePath!,
                                height: 150,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Text(
                                    'No photo yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Caption
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              caption,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('EDIT'),
                  onPressed: () {
                    // Edit functionality
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.upload_outlined, size: 16),
                  label: const Text('UPDATE'),
                  onPressed: () {
                    // Update functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}