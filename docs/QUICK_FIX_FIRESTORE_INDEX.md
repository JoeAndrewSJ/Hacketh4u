# Quick Fix: Create Required Firestore Index

## The Issue
The app is showing this error:
```
Listen for Query(target=Query(mentors where isActive==true order by -createdAt, -__name__);limitType=LIMIT_TO_FIRST) failed: Status{code=FAILED_PRECONDITION, description=The query requires an index.
```

## Quick Solution

### Option 1: Click the Direct Link (Easiest)
1. Click this link: https://console.firebase.google.com/v1/r/project/hackethos4u-8c9f0/firestore/indexes?create_composite=ClFwcm9qZWN0cy9oYWNrZXRob3M0dS04YzlmMC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbWVudG9ycy9pbmRleGVzL18QARoMCghpc0FjdGl2ZRABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
2. Click "Create Index"
3. Wait for the index to build (usually takes 1-2 minutes)
4. Restart the app

### Option 2: Manual Creation
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `hackethos4u-8c9f0`
3. Go to Firestore Database
4. Click "Indexes" tab
5. Click "Create Index"
6. Set:
   - Collection ID: `mentors`
   - Field 1: `isActive` (Ascending)
   - Field 2: `createdAt` (Descending)
7. Click "Create"

### Option 3: Code Already Fixed (Recommended)
The code has been updated to work without requiring this index:
- Uses simple query with `isActive == true`
- Sorts results in memory
- Includes fallback method
- Added debug logging

## What to Do Now

1. **Restart the app** to pick up the code changes
2. The mentors should now load without requiring the index
3. Check the debug logs to confirm mentors are loading
4. If you still get the error, create the index using Option 1 above

## Verification
After restarting, you should see debug logs like:
```
MentorRepository: Successfully loaded X mentors
MentorBloc: Loaded X mentors from Firebase
Mentors loaded: X
```

The mentor dropdown in course creation should now show the mentors you've created.
