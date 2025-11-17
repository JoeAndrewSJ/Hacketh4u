class FaqModel {
  final String question;
  final String answer;
  final String category;

  FaqModel({
    required this.question,
    required this.answer,
    required this.category,
  });

  static List<FaqModel> getFaqs() {
    return [
      // General
      FaqModel(
        question: 'What is Hackethos4u?',
        answer: 'Hackethos4u is a comprehensive learning platform designed to help you master new skills through interactive courses, expert instructors, and a supportive community. We offer a wide range of courses in technology, programming, and professional development.',
        category: 'General',
      ),
      FaqModel(
        question: 'How do I get started with courses?',
        answer: 'Browse our course catalog, select a course that interests you, and add it to your cart. After purchase, you can access the course from "My Purchases" section in your profile.',
        category: 'General',
      ),

      // Courses
      // FaqModel(
      //   question: 'Can I access courses offline?',
      //   answer: 'Currently, course videos require an internet connection to stream. We are working on adding offline download capabilities in future updates.',
      //   category: 'Courses',
      // ),
      FaqModel(
        question: 'How do I track my course progress?',
        answer: 'Your course progress is automatically saved as you complete lessons. You can view your progress on the course details page and on your home screen under "My Courses".',
        category: 'Courses',
      ),
      FaqModel(
        question: 'Can I get a certificate after completing a course?',
        answer: 'Yes! Upon completing all modules & Quiz of a course, you will receive a digital certificate in overview of the courses that you can download and share.',
        category: 'Courses',
      ),

      // Purchases & Payments
      FaqModel(
        question: 'What payment methods are accepted?',
        answer: 'We accept various payment methods including credit/debit cards, UPI, and net banking through our secure payment gateway.',
        category: 'Payments',
      ),
      // FaqModel(
      //   question: 'Can I get a refund for a course?',
      //   answer: 'We offer a refund within 7 days of purchase if you are not satisfied with the course. Please contact our support team with your order details.',
      //   category: 'Payments',
      // ),
      FaqModel(
        question: 'Where can I find my invoices?',
        answer: 'You can access all your purchase invoices from "My Purchases" → "Invoice History" in your profile section. Invoices can be downloaded as PDF.',
        category: 'Payments',
      ),

      // Account & Profile
      FaqModel(
        question: 'How do I update my profile information?',
        answer: 'Tap on your profile card at the top of the Profile screen. You can update your name, phone number, and profile picture.',
        category: 'Account',
      ),
      // FaqModel(
      //   question: 'I forgot my password. How can I reset it?',
      //   answer: 'On the login screen, tap "Forgot Password?" and enter your email address. You will receive a password reset link in your email.',
      //   category: 'Account',
      // ),
      // FaqModel(
      //   question: 'Can I change my email address?',
      //   answer: 'Yes, you can update your email address from your profile settings. You will need to verify your new email address.',
      //   category: 'Account',
      // ),

      // Technical Support
      // FaqModel(
      //   question: 'The video is not playing. What should I do?',
      //   answer: 'Try the following: 1) Check your internet connection, 2) Restart the app, 3) Clear app cache from device settings. If the issue persists, contact our support team.',
      //   category: 'Technical',
      // ),
      FaqModel(
        question: 'How do I switch between light and dark mode?',
        answer: 'Go to your Profile screen and toggle the "Dark Mode" option in the settings section.',
        category: 'Technical',
      ),

      // Community
      FaqModel(
        question: 'How do I join community discussions?',
        answer: 'Navigate to the Community tab from the bottom navigation bar. You can join workspaces, participate in group chats, and connect with other learners.',
        category: 'Community',
      ),
      FaqModel(
        question: 'Can I ask questions to instructors?',
        answer: 'Yes! Each course has a dedicated community workspace where you can ask questions, share insights, and interact with instructors and fellow learners.',
        category: 'Community',
      ),
    ];
  }

  static List<String> getCategories() {
    return [
      'All',
      'General',
      'Courses',
      'Payments',
      'Account',
      'Technical',
      'Community',
    ];
  }
}
