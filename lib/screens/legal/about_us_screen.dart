import 'package:flutter/material.dart';
import 'package:tong/utils/constants.dart';
import 'package:tong/utils/theme.dart';

class AboutUsScreen extends StatelessWidget {
  static const routeName = '/about-us';

  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        Constants.tongDokanImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Constants.appName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Mission Section
            _buildSection(
              'Our Mission',
              'At টং (Tong), we believe that financial awareness starts with simple, daily habits. Our mission is to empower individuals and families to take control of their finances through intuitive, accessible, and reliable expense tracking.',
              Icons.flag,
              AppTheme.primaryColor,
            ),

            // Vision Section
            _buildSection(
              'Our Vision',
              'We envision a world where everyone has the tools and insights they need to make informed financial decisions. Through technology and user-centered design, we aim to make financial management accessible to everyone.',
              Icons.visibility,
              AppTheme.secondaryColor,
            ),

            // Story Section
            _buildSection(
              'Our Story',
              'টং (Tong) was born from a simple observation: traditional expense tracking was either too complex or too basic. We wanted to create something that was both powerful and easy to use, something that could grow with our users\' needs.',
              Icons.book,
              AppTheme.infoColor,
            ),

            // Values Section
            _buildSection(
              'Our Values',
              '• **Simplicity**: We believe in making complex tasks simple\n'
              '• **Privacy**: Your financial data is yours, and we protect it fiercely\n'
              '• **Reliability**: You can count on us to work when you need it\n'
              '• **Innovation**: We continuously improve based on user feedback\n'
              '• **Accessibility**: Our app works for everyone, everywhere',
              Icons.favorite,
              AppTheme.successColor,
            ),

            // Features Section
            _buildSection(
              'What Makes Us Different',
              '• **Offline-First**: Works without internet, syncs when connected\n'
              '• **Smart Analytics**: Get insights into your spending patterns\n'
              '• **Budget Tracking**: Set limits and stay on track\n'
              '• **Data Export**: Your data, your control\n'
              '• **Cross-Platform**: Works seamlessly across all your devices\n'
              '• **Privacy-Focused**: Your data stays private and secure',
              Icons.star,
              AppTheme.warningColor,
            ),

            // Team Section
            _buildSection(
              'Our Team',
              'We are a passionate team of developers, designers, and financial experts dedicated to creating the best expense tracking experience. Our diverse backgrounds help us understand and solve real-world financial challenges.',
              Icons.people,
              AppTheme.primaryColor,
            ),

            // Technology Section
            _buildSection(
              'Technology',
              'Built with modern technologies including Flutter, Firebase, and advanced security protocols. We use industry best practices to ensure your data is safe, your app is fast, and your experience is seamless.',
              Icons.phone_android,
              AppTheme.infoColor,
            ),

            // Community Section
            _buildSection(
              'Community',
              'We believe in the power of community. Your feedback drives our development, and we\'re committed to building features that matter to you. Join our community of users who are taking control of their finances.',
              Icons.forum,
              AppTheme.secondaryColor,
            ),

            // Contact Section
            _buildSection(
              'Get in Touch',
              'We\'d love to hear from you! Whether you have feedback, questions, or just want to say hello, we\'re here to help.\n\n'
              'Email: hello@tong-app.com\n'
              'Support: support@tong-app.com\n'
              'Website: www.tong-app.com',
              Icons.email,
              AppTheme.successColor,
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Thank you for choosing টং',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Together, let\'s build better financial habits',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialButton(Icons.facebook, 'Facebook'),
                      _buildSocialButton(Icons.twitter, 'Twitter'),
                      _buildSocialButton(Icons.linkedin, 'LinkedIn'),
                      _buildSocialButton(Icons.telegram, 'Telegram'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Copyright
            Center(
              child: Text(
                '© ${DateTime.now().year} টং (Tong). All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
} 