# Firestore Security Rules

## Overview
These security rules ensure proper access control for the course management system while maintaining data integrity and user privacy.

## Rules Implementation

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isValidEmail(email) {
      return email.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && 
                       request.auth.uid == userId &&
                       isValidEmail(resource.data.email);
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }
    
    // Courses collection
    match /courses/{courseId} {
      // Public read access for published courses
      allow read: if resource.data.status == 'published';
      
      // Admin only access for draft/archived courses
      allow read: if isAdmin();
      
      // Only admins can create, update, or delete courses
      allow create: if isAdmin() && 
                       resource.data.createdBy == request.auth.uid;
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Modules collection
    match /modules/{moduleId} {
      // Public read access if parent course is published
      allow read: if isAuthenticated() && 
                     get(/databases/$(database)/documents/courses/$(resource.data.courseId)).data.status == 'published';
      
      // Admin read access for all modules
      allow read: if isAdmin();
      
      // Only admins can manage modules
      allow create: if isAdmin() && 
                       get(/databases/$(database)/documents/courses/$(resource.data.courseId)).data.createdBy == request.auth.uid;
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Videos collection
    match /videos/{videoId} {
      // Public read access if parent course is published
      allow read: if isAuthenticated() && 
                     get(/databases/$(database)/documents/courses/$(resource.data.courseId)).data.status == 'published';
      
      // Admin read access for all videos
      allow read: if isAdmin();
      
      // Only admins can manage videos
      allow create: if isAdmin() && 
                       get(/databases/$(database)/documents/courses/$(resource.data.courseId)).data.createdBy == request.auth.uid;
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Mentors collection
    match /mentors/{mentorId} {
      // Public read access for active mentors
      allow read: if resource.data.isActive == true;
      
      // Admin read access for all mentors
      allow read: if isAdmin();
      
      // Only admins can manage mentors
      allow create: if isAdmin();
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Enrollments collection
    match /enrollments/{enrollmentId} {
      // Users can read their own enrollments
      allow read: if isOwner(resource.data.userId);
      
      // Admins can read all enrollments
      allow read: if isAdmin();
      
      // Authenticated users can create their own enrollments
      allow create: if isAuthenticated() && 
                       request.auth.uid == resource.data.userId &&
                       exists(/databases/$(database)/documents/courses/$(resource.data.courseId)) &&
                       get(/databases/$(database)/documents/courses/$(resource.data.courseId)).data.status == 'published';
      
      // Users can update their own enrollment progress
      allow update: if isOwner(resource.data.userId) && 
                       // Prevent modification of sensitive fields
                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['userId', 'courseId', 'enrolledAt']);
      
      // Admins can update any enrollment
      allow update: if isAdmin();
      
      // Only admins can delete enrollments
      allow delete: if isAdmin();
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      // Public read access for all reviews
      allow read: if true;
      
      // Users can create reviews for published courses
      allow create: if isAuthenticated() && 
                       request.auth.uid == resource.data.userId &&
                       exists(/databases/$(database)/documents/courses/$(resource.data.courseId)) &&
                       get(/databases/$(database)/documents/courses/$(resource.data.courseId)).data.status == 'published' &&
                       // Ensure user is enrolled in the course
                       exists(/databases/$(database)/documents/enrollments/$(request.auth.uid + '_' + resource.data.courseId));
      
      // Users can update their own reviews
      allow update: if isOwner(resource.data.userId) && 
                       // Prevent modification of sensitive fields
                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['userId', 'courseId', 'createdAt']);
      
      // Users can delete their own reviews
      allow delete: if isOwner(resource.data.userId);
      
      // Admins can manage all reviews
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Analytics collection (for admin dashboard)
    match /analytics/{docId} {
      allow read, write: if isAdmin();
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      // Users can read their own notifications
      allow read: if isOwner(resource.data.userId);
      
      // Users can update their own notifications (mark as read)
      allow update: if isOwner(resource.data.userId) && 
                       // Only allow updating read status
                       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead', 'readAt']);
      
      // Admins can create notifications
      allow create: if isAdmin();
      
      // Admins can delete notifications
      allow delete: if isAdmin();
    }
  }
}
```

## Key Security Features

### 1. Authentication Requirements
- All operations require authentication except public read access
- User ID validation ensures users can only access their own data

### 2. Role-Based Access Control
- Admin role check for administrative operations
- Regular users have limited access to their own data

### 3. Data Validation
- Email format validation for user creation
- Course status validation for enrollment and reviews
- Enrollment existence check before allowing reviews

### 4. Field Protection
- Sensitive fields like `userId`, `courseId`, `createdAt` are protected from modification
- Users can only update specific fields (progress, read status)

### 5. Business Logic Enforcement
- Users can only enroll in published courses
- Users can only review courses they're enrolled in
- Admins can manage all content and user data

### 6. Denormalization Safety
- Cross-document validation ensures data integrity
- Existence checks prevent orphaned references

## Testing Security Rules

### Test Cases to Implement

1. **User Authentication**
   - Unauthenticated users cannot create/update data
   - Authenticated users can access their own data

2. **Admin Permissions**
   - Admins can access all data
   - Regular users cannot access admin-only data

3. **Course Access**
   - Published courses are publicly readable
   - Draft/archived courses are admin-only

4. **Enrollment Logic**
   - Users can only enroll in published courses
   - Users cannot modify other users' enrollments

5. **Review System**
   - Users can only review enrolled courses
   - Users cannot modify review metadata

6. **Data Integrity**
   - Protected fields cannot be modified
   - Cross-document references are validated

## Deployment

1. Save the rules to `firestore.rules`
2. Deploy using Firebase CLI: `firebase deploy --only firestore:rules`
3. Test rules using Firebase Emulator Suite
4. Monitor security rule violations in Firebase Console

## Monitoring

- Enable Firestore security rule monitoring
- Set up alerts for rule violations
- Regularly audit access patterns
- Review and update rules based on usage patterns
