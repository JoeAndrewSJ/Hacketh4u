# Firestore Database Structure

## Collections Overview

### 1. courses
```javascript
{
  id: "course_123",
  title: "Complete Web Development Bootcamp",
  description: "Learn HTML, CSS, JavaScript, React, Node.js and build real-world projects",
  thumbnailUrl: "https://storage.googleapis.com/...",
  mentorId: "mentor_456", // optional
  isCertificateCourse: true,
  certificateTemplateUrl: "https://storage.googleapis.com/...", // if certificate course
  completionPercentage: 80, // minimum completion for certificate
  certificateAvailability: "after_review", // or "immediate"
  curriculum: "Rich text content with HTML formatting",
  status: "published", // published, draft, archived
  rating: 4.8,
  studentCount: 1250,
  duration: "40 hours",
  createdAt: Timestamp,
  updatedAt: Timestamp,
  createdBy: "admin_789"
}
```

### 2. modules
```javascript
{
  id: "module_123",
  courseId: "course_123",
  title: "Introduction to HTML",
  description: "Learn the basics of HTML structure and elements",
  order: 1,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 3. videos
```javascript
{
  id: "video_123",
  moduleId: "module_123",
  courseId: "course_123", // denormalized for easier queries
  title: "HTML Basics - Part 1",
  description: "Introduction to HTML tags and structure",
  videoUrl: "https://storage.googleapis.com/...",
  thumbnailUrl: "https://storage.googleapis.com/...",
  duration: 1800, // seconds
  order: 1,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 4. mentors
```javascript
{
  id: "mentor_456",
  name: "John Doe",
  email: "john@example.com",
  avatarUrl: "https://storage.googleapis.com/...",
  primaryExpertise: "Web Development",
  expertiseTags: ["React", "Node.js", "JavaScript", "HTML", "CSS"],
  bio: "Experienced full-stack developer with 5+ years...",
  yearsOfExperience: 5,
  socialLinks: {
    linkedin: "https://linkedin.com/in/johndoe",
    twitter: "https://twitter.com/johndoe",
    website: "https://johndoe.dev"
  },
  isActive: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 5. enrollments
```javascript
{
  id: "enrollment_123",
  userId: "user_789",
  courseId: "course_123",
  enrolledAt: Timestamp,
  completionPercentage: 65.5,
  completedModules: ["module_123", "module_124"],
  completedVideos: ["video_123", "video_124", "video_125"],
  lastWatchedVideo: "video_125",
  lastWatchedAt: Timestamp,
  certificateEarned: false,
  certificateUrl: null, // populated when certificate is earned
  certificateEarnedAt: null
}
```

### 6. reviews
```javascript
{
  id: "review_123",
  userId: "user_789",
  courseId: "course_123",
  rating: 5,
  comment: "Excellent course! Very well structured and easy to follow.",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 7. users
```javascript
{
  id: "user_789",
  email: "student@example.com",
  displayName: "Jane Student",
  photoUrl: "https://storage.googleapis.com/...",
  role: "student", // student, admin
  enrolledCourses: ["course_123", "course_124"],
  createdAt: Timestamp,
  lastLoginAt: Timestamp
}
```

## Query Patterns

### Get all published courses with enrollment count
```javascript
// Query courses collection
db.collection('courses')
  .where('status', '==', 'published')
  .orderBy('createdAt', 'desc')
  .get()

// Count enrollments for each course
// This would be done in a Cloud Function or client-side
```

### Get course details with mentor information
```javascript
// Get course
const course = await db.collection('courses').doc(courseId).get()

// Get mentor if assigned
if (course.data().mentorId) {
  const mentor = await db.collection('mentors').doc(course.data().mentorId).get()
}
```

### Get user's enrollment progress
```javascript
db.collection('enrollments')
  .where('userId', '==', userId)
  .where('courseId', '==', courseId)
  .get()
```

### Get course modules and videos
```javascript
// Get modules
const modules = await db.collection('modules')
  .where('courseId', '==', courseId)
  .orderBy('order')
  .get()

// Get videos for each module
for (const module of modules.docs) {
  const videos = await db.collection('videos')
    .where('moduleId', '==', module.id)
    .orderBy('order')
    .get()
}
```

### Get course reviews with user information
```javascript
const reviews = await db.collection('reviews')
  .where('courseId', '==', courseId)
  .orderBy('createdAt', 'desc')
  .get()

// Get user details for each review
for (const review of reviews.docs) {
  const user = await db.collection('users').doc(review.data().userId).get()
}
```

## Indexes Required

### courses collection
- status (Ascending) + createdAt (Descending)
- mentorId (Ascending) + createdAt (Descending)
- status (Ascending) + studentCount (Descending)

### modules collection
- courseId (Ascending) + order (Ascending)

### videos collection
- moduleId (Ascending) + order (Ascending)
- courseId (Ascending) + order (Ascending)

### enrollments collection
- userId (Ascending) + enrolledAt (Descending)
- courseId (Ascending) + enrolledAt (Descending)

### reviews collection
- courseId (Ascending) + createdAt (Descending)

## Security Rules

See `firestore_security_rules.md` for detailed security rules.

## Performance Considerations

1. **Denormalization**: Course ID is stored in videos collection for easier queries
2. **Batch Operations**: Use batch writes for related operations
3. **Pagination**: Implement pagination for large collections
4. **Caching**: Cache frequently accessed data on the client
5. **Cloud Functions**: Use Cloud Functions for complex operations and data aggregation
