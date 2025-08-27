import 'package:flutter/material.dart';
import 'package:tong/utils/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const routeName = '/privacy-policy';

  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Introduction',
              'This Privacy Policy describes how টং (Tong) collects, uses, and protects your personal information when you use our expense tracking application.',
            ),
            _buildSection(
              'Information We Collect',
              'We collect information you provide directly to us, such as:\n'
              '• Account information (email, name)\n'
              '• Expense data and categories\n'
              '• Usage data and preferences\n'
              '• Device information for app functionality',
            ),
            _buildSection(
              'How We Use Your Information',
              'We use the collected information to:\n'
              '• Provide and maintain the app service\n'
              '• Process your expense tracking data\n'
              '• Improve app functionality and user experience\n'
              '• Send important updates and notifications\n'
              '• Ensure data security and prevent fraud',
            ),
            _buildSection(
              'Data Storage and Security',
              '• Your data is stored securely using Firebase Cloud Firestore\n'
              '• Local data is encrypted on your device\n'
              '• We implement industry-standard security measures\n'
              '• Regular security audits and updates are performed',
            ),
            _buildSection(
              'Data Sharing',
              'We do not sell, trade, or rent your personal information to third parties. We may share data only when:\n'
              '• Required by law or legal process\n'
              '• Protecting our rights and safety\n'
              '• With your explicit consent',
            ),
            _buildSection(
              'Your Rights',
              'You have the right to:\n'
              '• Access your personal data\n'
              '• Correct inaccurate information\n'
              '• Delete your account and data\n'
              '• Export your data\n'
              '• Opt-out of certain data processing',
            ),
            _buildSection(
              'Data Retention',
              '• Your data is retained as long as your account is active\n'
              '• Deleted data is permanently removed within 30 days\n'
              '• Backup data may be retained for legal compliance',
            ),
            _buildSection(
              'Children\'s Privacy',
              'Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13. If you are a parent and believe your child has provided us with personal information, please contact us.',
            ),
            _buildSection(
              'Third-Party Services',
              'We use the following third-party services:\n'
              '• Firebase (Google) for data storage and authentication\n'
              '• Google Sign-In for account creation\n'
              'These services have their own privacy policies.',
            ),
            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
            ),
            _buildSection(
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n'
              'Email: privacy@tong-app.com\n'
              'Address: [Your Company Address]\n'
              'Phone: [Your Contact Number]',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.infoColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppTheme.infoColor,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 