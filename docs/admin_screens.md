# Admin Interface - Screens Documentation

## Overview
Complete catalog of all admin-side screens with their purposes and functionalities. The current navigation system uses a bottom navigation bar with three main tabs: Home, Create, and Profile.

---

## Navigation Structure

### **Bottom Navigation Bar**
- **Home** - Dashboard with course management actions
- **Create** - Quick access to admin tools and settings
- **Profile** - Admin profile and account settings

---

## Detailed Screen Inventory

### 1. **Admin Home Screen** (`admin_home_screen.dart`)
**Purpose:** Main dashboard for course management and administrative actions
**Features:** Displays welcome message with admin email. Provides quick action cards to create courses, create mentors, and manage all courses. Serves as the primary landing page after admin login.

### 2. **Admin Create Screen** (`admin_create_screen.dart`)
**Purpose:** Central hub for accessing all major admin tools and features
**Features:** Grid layout with 6 main feature cards - Settings, Coupons, Community, Reviews, Ads Banners, and Stats. Each card provides direct navigation to respective management screens with colorful gradient designs.

### 3. **Admin Profile Screen** (`admin_profile_screen.dart`)
**Purpose:** Admin account management and profile customization
**Features:** Displays admin profile information, settings access, and logout functionality. Allows admins to manage their personal account details and preferences.

### 4. **Admin Settings Screen** (`admin_settings_screen.dart`)
**Purpose:** System-wide configuration and user management
**Features:** Toggle for community features (enables/disables community tab for all users). Provides access to All Users screen for user account management. Includes settings for global app configurations.

### 5. **All Users Screen** (`all_users_screen.dart`)
**Purpose:** Comprehensive user management and administration
**Features:** View list of all registered users, manage user accounts and permissions. Access user details, enrollment status, and payment information. Monitor user activity and engagement.

### 6. **Coupon Management Screen** (`coupon_management_screen.dart`)
**Purpose:** Create and manage discount coupons for courses
**Features:** Create new discount coupons with custom codes and percentages. View active and inactive coupons. Edit existing coupons and toggle coupon status. Delete coupons and track usage statistics.

### 7. **Coupon Creation Screen** (`coupon_creation_screen.dart`)
**Purpose:** Detailed interface for creating new promotional coupons
**Features:** Form to input coupon code, discount percentage/amount, validity period. Set usage limits and expiration dates. Apply coupons to specific courses or make them universal.

### 8. **Community Chat Screen** (`community_chat_screen.dart`)
**Purpose:** Manage workspaces, groups, and community interactions
**Features:** Three-tab interface (Workspace, Groups, Chats). Create and manage workspaces for course communities. Organize groups within workspaces. Bulk delete functionality for multiple selections. View and moderate community conversations.

### 9. **Workspace Screen** (`workspace_screen.dart`)
**Purpose:** Detailed management of individual workspace settings
**Features:** Manage workspace details, members, and groups. Create new groups within the workspace. View workspace statistics and activity. Configure workspace-specific settings.

### 10. **Group Chat Screen** (`group_chat_screen.dart`)
**Purpose:** Real-time group chat management and moderation
**Features:** View and monitor group messages. Moderate chat content and manage group members. Send admin messages and announcements. Configure group settings and permissions.

### 11. **Admin Reviews Management Screen** (`admin_reviews_management_screen.dart`)
**Purpose:** Centralized review management across all courses
**Features:** View all course reviews and ratings in one place. Navigate to specific course reviews for detailed management. Monitor review statistics (total reviews, average ratings). Identify courses that need attention based on ratings.

### 12. **Course Reviews List Screen** (`course_reviews_list_screen.dart`)
**Purpose:** Manage reviews for a specific course
**Features:** View all reviews for a selected course. Moderate review content (approve/delete). Respond to user reviews as admin. Track course rating trends over time.

### 13. **Ads Banner Screen** (`ads_banner_screen.dart`)
**Purpose:** Create and manage promotional banner advertisements
**Features:** Upload custom banner images for homepage display. Optional YouTube URL linking for video promotions. Toggle banner active/inactive status. Delete outdated banners. Grid view of all banners with status indicators.

### 14. **Stats Screen** (`stats_screen.dart`)
**Purpose:** Comprehensive analytics dashboard for platform insights
**Features:** Overview cards (Total Users, Total Courses, Paid Users, Total Revenue). User payment status breakdown (paid vs free users). Monthly revenue charts and trends. Top users by enrollment and spending. Top courses by enrollment, ratings, and revenue. User progress tracking and course completion rates.

### 15. **Course Creation Screen** (`course_creation_screen.dart`)
**Purpose:** Create new courses with complete details and configuration
**Features:** Multi-step course creation wizard. Input course title, description, pricing, and thumbnail. Add course curriculum and module structure. Assign mentors to courses. Set course prerequisites and difficulty level.

### 16. **Course Modules Screen** (`course_modules_screen.dart`)
**Purpose:** Manage modules and lessons within a course
**Features:** Create, edit, and organize course modules. Add video lessons, quizzes, and resources to modules. Reorder modules and lessons for optimal learning flow. Manage module visibility and prerequisites.

### 17. **Module Creation Screen** (`module_creation_screen.dart`)
**Purpose:** Create individual modules with lessons and content
**Features:** Define module title and description. Add video lessons with durations and URLs. Upload supplementary materials and resources. Set module order and visibility settings.

### 18. **Quiz Creation Screen** (`quiz_creation_screen.dart`)
**Purpose:** Create quizzes and assessments for course modules
**Features:** Design multiple-choice and true/false questions. Set quiz duration and passing criteria. Add question explanations for learning reinforcement. Configure quiz availability and retry policies.

### 19. **Mentor Creation Screen** (`mentor_creation_screen.dart`)
**Purpose:** Add new mentors and instructors to the platform
**Features:** Input mentor profile information (name, bio, expertise). Upload mentor profile picture and credentials. Assign courses to mentors. Manage mentor permissions and access levels.

### 20. **Mentors List Screen** (`mentors_list_screen.dart`)
**Purpose:** View and manage all platform mentors
**Features:** Comprehensive list of all mentors with their details. View mentor course assignments and student counts. Edit mentor profiles and reassign courses. Activate/deactivate mentor accounts.

### 21. **All Courses Screen** (`all_courses_screen.dart`)
**Purpose:** Complete course library management interface
**Features:** View all published and draft courses. Search and filter courses by category, price, rating. Edit existing courses and update content. Publish/unpublish courses. View enrollment statistics per course.

---

## Current Navigation Pain Points

### **Issue:** Navigation Inefficiency
**Problem:** When accessing specific pages (Community, Reviews, Ads Banners, etc.) from the Create screen, users must return to Home to navigate elsewhere. This creates unnecessary navigation steps and poor user experience.

**Example Flow:**
1. Home → Create → Community
2. To access Settings: Community → Back → Create → Back → Create → Settings
3. This requires 4 navigation actions instead of 1 direct navigation

---

## Proposed Solution: Universal Navigation Menu

### **Design Concept**
Implement a **top-right hamburger menu** (three-line icon) available on ALL admin screens that provides instant access to all major admin features.

### **Menu Structure**
```
☰ Menu
├── Home
├── Settings
├── Coupons
├── Community
├── Reviews
├── Ads Banners
├── Stats
├── All Courses
├── All Users
├── Mentors
└── Profile
```

### **Benefits**
1. **Single-Click Access:** Navigate to any screen from anywhere
2. **Workflow Efficiency:** Eliminate back-navigation loops
3. **Better UX:** Modern, intuitive navigation pattern
4. **Consistency:** Same menu available across all screens
5. **Scalability:** Easy to add new features to the menu

### **Visual Placement**
- **Position:** Top-right corner of AppBar
- **Icon:** Hamburger menu (☰) or grid icon
- **Behavior:** Slides in from right as drawer/bottom sheet
- **Theme:** Follows app theme (dark/light mode)

---

## Implementation Priority

### **High Priority Screens** (Need universal navigation most)
1. Community Chat Screen
2. Reviews Management Screen
3. Course Reviews List Screen
4. Ads Banner Screen
5. Stats Screen
6. Workspace Screen
7. Group Chat Screen

### **Medium Priority Screens**
8. All Courses Screen
9. All Users Screen
10. Coupon Management Screen

### **Lower Priority Screens** (Already accessible via bottom nav)
11. Admin Home Screen
12. Admin Create Screen
13. Admin Profile Screen

---

## Technical Considerations

### **Widget to Create**
- `AdminNavigationDrawer` or `AdminNavigationMenu`
- Reusable component that can be added to any admin screen's AppBar
- Maintains current page indicator in the menu

### **Navigation State**
- Highlight current active screen in the menu
- Close menu automatically after navigation
- Preserve navigation history for proper back-button behavior

### **Responsive Design**
- **Mobile:** Slide-in drawer from right
- **Tablet:** Could be expanded menu or permanent sidebar
- **Animations:** Smooth slide/fade transitions

---

## Next Steps

1. ✅ Document all admin screens
2. ⏭️ Design the universal navigation menu widget
3. ⏭️ Implement the menu component
4. ⏭️ Integrate menu into all admin screens
5. ⏭️ Test navigation flow and user experience
6. ⏭️ Gather feedback and iterate on design

---

**Last Updated:** 2025-11-03
**Documented By:** Admin UI/UX Enhancement Team
