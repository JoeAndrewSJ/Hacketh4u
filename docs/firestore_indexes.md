# Firestore Indexes Setup

## Required Indexes for the Application

### 1. Mentors Collection

#### Index 1: isActive + createdAt (Composite)
```
Collection: mentors
Fields:
- isActive (Ascending)
- createdAt (Descending)

Index ID: mentors_isActive_createdAt
```

#### Alternative: Use Single Field Indexes
If you prefer not to create composite indexes, the application has been updated to sort mentors in memory after fetching from Firestore.

### 2. Courses Collection

#### Index 1: createdAt (Single Field)
```
Collection: courses
Fields:
- createdAt (Descending)

Index ID: courses_createdAt
```

### 3. Modules Collection

#### Index 1: courseId + order (Composite)
```
Collection: modules
Fields:
- courseId (Ascending)
- order (Ascending)

Index ID: modules_courseId_order
```

### 4. Videos Collection

#### Index 1: moduleId + order (Composite)
```
Collection: videos
Fields:
- moduleId (Ascending)
- order (Ascending)

Index ID: videos_moduleId_order
```

#### Index 2: courseId + order (Composite)
```
Collection: videos
Fields:
- courseId (Ascending)
- order (Ascending)

Index ID: videos_courseId_order
```

### 5. Enrollments Collection

#### Index 1: userId + enrolledAt (Composite)
```
Collection: enrollments
Fields:
- userId (Ascending)
- enrolledAt (Descending)

Index ID: enrollments_userId_enrolledAt
```

#### Index 2: courseId + enrolledAt (Composite)
```
Collection: enrollments
Fields:
- courseId (Ascending)
- enrolledAt (Descending)

Index ID: enrollments_courseId_enrolledAt
```

### 6. Reviews Collection

#### Index 1: courseId + createdAt (Composite)
```
Collection: reviews
Fields:
- courseId (Ascending)
- createdAt (Descending)

Index ID: reviews_courseId_createdAt
```

## How to Create Indexes

### Method 1: Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Firestore Database
4. Click on "Indexes" tab
5. Click "Create Index"
6. Enter the collection name and fields as specified above

### Method 2: Firebase CLI
Create a `firestore.indexes.json` file in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "mentors",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isActive",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "courses",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "modules",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "courseId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "order",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "videos",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "moduleId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "order",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "videos",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "courseId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "order",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "enrollments",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "enrolledAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "enrollments",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "courseId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "enrolledAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "courseId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then deploy using:
```bash
firebase deploy --only firestore:indexes
```

### Method 3: Auto-Generated Indexes
The application can automatically generate some indexes when you run queries. However, for production, it's recommended to create them manually for better performance.

## Performance Considerations

1. **Composite Indexes**: Required for queries with multiple fields and ordering
2. **Single Field Indexes**: Automatically created by Firestore
3. **Memory Sorting**: Used as fallback to avoid composite index requirements
4. **Index Limits**: Firestore has limits on the number of indexes per project

## Current Implementation

The application has been updated to handle the mentor query without requiring a composite index by:
1. Fetching mentors with only the `isActive` filter
2. Sorting by `createdAt` in memory
3. This approach works for small to medium datasets

For better performance with large datasets, create the composite index as specified above.
