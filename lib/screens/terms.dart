import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms and Conditions',
          style: TextStyle(fontSize: 20.sp),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0.sp),
        child: SingleChildScrollView(
          child: Text(
            '''
**Terms and Conditions**

**Last Updated: September 16, 2024**

Welcome to the UTB Codebase application (the “App”). By accessing or using this App, you agree to be bound by the following terms and conditions (the “Terms”). If you do not agree to these Terms, please do not use the App.

**1. Acceptance of Terms**

By using this App, you agree to these Terms and our Privacy Policy. If you do not agree, please discontinue use of the App.

**2. Use of the App**

The UTB Codebase App is designed for UTB students to manage and showcase their applications, including uploading APK files, viewing screenshots, and interacting with other students' applications.

**3. User Responsibilities**

- **Account Creation**: You must provide accurate and complete information when creating an account and keep your account information up-to-date.
- **Security**: You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.
- **Prohibited Activities**: You agree not to engage in any activities that are illegal, harmful, or disruptive. This includes, but is not limited to, uploading malicious content, infringing on intellectual property rights, or harassing other users.

**4. Content**

- **Ownership**: You retain ownership of the content you create and upload to the App, but you grant us a non-exclusive, royalty-free, worldwide license to use, reproduce, and display that content for the purpose of operating and improving the App.
- **Responsibility**: You are solely responsible for the content you upload and share. We are not liable for any content created by users.

**5. Privacy**

Your use of the App is also governed by our Privacy Policy, which details how we collect, use, and protect your personal information.

**6. Intellectual Property**

All intellectual property rights in the App, including trademarks, service marks, and copyrights, are owned by or licensed to us. You may not use these intellectual property rights without our prior written consent.

**7. Limitation of Liability**

The App is provided on an “as-is” and “as-available” basis. We do not guarantee that the App will be available at all times or that it will be free from errors or interruptions. To the fullest extent permitted by law, we are not liable for any damages arising out of or in connection with your use of the App.

**8. Indemnification**

You agree to indemnify, defend, and hold harmless us and our affiliates, officers, directors, employees, and agents from and against any claims, liabilities, damages, losses, and expenses (including reasonable attorneys’ fees) arising out of or in connection with your use of the App or your violation of these Terms.

**9. Modifications**

We may update these Terms from time to time. We will notify you of any significant changes by posting the new Terms on the App. Your continued use of the App after any changes constitutes your acceptance of the updated Terms.

**10. Termination**

We reserve the right to terminate or suspend your account and access to the App if you violate these Terms or if we believe that your actions may harm the App or other users.

**11. Governing Law**

These Terms are governed by and construed in accordance with the laws of Kingdom of Bahrain, without regard to its conflict of law principles.

**12. Contact Us**

If you have any questions or concerns about these Terms, please contact us at BH21500282@utb.edu.bh .
            ''',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      ),
    );
  }
}
