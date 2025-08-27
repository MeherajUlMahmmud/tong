import 'package:flutter/material.dart';
import 'package:tong/utils/theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  static const routeName = '/terms-conditions';

  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Acceptance of Terms',
              'By downloading, installing, or using the টং (Tong) app, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the app.',
            ),
            _buildSection(
              'Description of Service',
              'টং (Tong) is an expense tracking application that allows users to:\n'
              '• Track daily expenses by category\n'
              '• Manage expense categories\n'
              '• View analytics and insights\n'
              '• Set and monitor budgets\n'
              '• Export expense data\n'
              '• Sync data across devices',
            ),
            _buildSection(
              'User Accounts',
              '• You must create an account to use the app\n'
              '• You are responsible for maintaining account security\n'
              '• You must provide accurate and complete information\n'
              '• You are responsible for all activities under your account\n'
              '• You must notify us immediately of any unauthorized use',
            ),
            _buildSection(
              'Acceptable Use',
              'You agree to use the app only for lawful purposes and in accordance with these terms. You agree not to:\n'
              '• Use the app for any illegal or unauthorized purpose\n'
              '• Attempt to gain unauthorized access to our systems\n'
              '• Interfere with or disrupt the app\'s functionality\n'
              '• Share your account credentials with others\n'
              '• Use the app to store sensitive financial information',
            ),
            _buildSection(
              'Data and Privacy',
              '• Your data is processed according to our Privacy Policy\n'
              '• You retain ownership of your expense data\n'
              '• We may use anonymized data for app improvement\n'
              '• You can export and delete your data at any time\n'
              '• We implement security measures to protect your data',
            ),
            _buildSection(
              'Intellectual Property',
              '• The app and its content are owned by us\n'
              '• You may not copy, modify, or distribute the app\n'
              '• You retain rights to your user-generated content\n'
              '• Our trademarks and logos are protected\n'
              '• Third-party content is subject to their terms',
            ),
            _buildSection(
              'Service Availability',
              '• We strive to maintain high service availability\n'
              '• The app may be temporarily unavailable for maintenance\n'
              '• We are not liable for service interruptions\n'
              '• Offline functionality is provided when possible\n'
              '• We may update or discontinue features with notice',
            ),
            _buildSection(
              'Limitation of Liability',
              '• The app is provided "as is" without warranties\n'
              '• We are not liable for indirect or consequential damages\n'
              '• Our liability is limited to the amount you paid for the app\n'
              '• We are not responsible for third-party services\n'
              '• You use the app at your own risk',
            ),
            _buildSection(
              'Indemnification',
              'You agree to indemnify and hold us harmless from any claims, damages, or expenses arising from:\n'
              '• Your use of the app\n'
              '• Your violation of these terms\n'
              '• Your violation of any third-party rights\n'
              '• Any unauthorized use of your account',
            ),
            _buildSection(
              'Termination',
              '• You may terminate your account at any time\n'
              '• We may terminate accounts for terms violations\n'
              '• Upon termination, your data will be deleted\n'
              '• Some terms survive termination\n'
              '• We will provide notice before account termination',
            ),
            _buildSection(
              'Governing Law',
              'These terms are governed by the laws of [Your Country/State]. Any disputes will be resolved in the courts of [Your Jurisdiction].',
            ),
            _buildSection(
              'Changes to Terms',
              'We may update these terms from time to time. We will notify you of significant changes through the app or email. Continued use of the app after changes constitutes acceptance of the new terms.',
            ),
            _buildSection(
              'Contact Information',
              'For questions about these Terms and Conditions, contact us at:\n'
              'Email: legal@tong-app.com\n'
              'Address: [Your Company Address]\n'
              'Phone: [Your Contact Number]',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppTheme.warningColor,
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