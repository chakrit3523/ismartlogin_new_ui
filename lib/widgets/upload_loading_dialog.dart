import 'package:flutter/material.dart';

/// Beautiful loading dialog for image upload
class UploadLoadingDialog extends StatelessWidget {
  final String status;
  final double progress;

  const UploadLoadingDialog({
    Key? key,
    required this.status,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated upload icon
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4A90E2),
                          Color(0xFF357ABD),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4A90E2).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 24),

            // Status text
            Text(
              status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            // Progress bar
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 6,
                  width: MediaQuery.of(context).size.width * progress * 0.7,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4A90E2),
                        Color(0xFF50C878),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4A90E2).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Progress percentage
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show loading dialog
  static void show(
    BuildContext context, {
    required String status,
    required double progress,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => UploadLoadingDialog(
        status: status,
        progress: progress,
      ),
    );
  }

  /// Hide loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
