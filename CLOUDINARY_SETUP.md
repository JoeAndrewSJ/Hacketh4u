# Cloudinary Video Streaming Setup Guide

This guide explains how to set up and deploy the Cloudinary + Firebase integration for optimized video streaming in Hackethos4u.

## Overview

The integration provides:
- **HLS Adaptive Streaming**: Automatic quality adjustment based on network speed
- **Multiple Quality Options**: 1080p, 720p, 480p
- **CDN Delivery**: Global content delivery via Cloudinary
- **Backward Compatibility**: Existing Firebase Storage videos continue to work
- **Automatic Processing**: Videos are automatically optimized when uploaded

## Architecture

```
Firebase Storage Upload
        ↓
Cloud Function Triggered
        ↓
Upload to Cloudinary → Generate HLS Streams (1080p/720p/480p)
        ↓
Update Firestore → Add streaming URLs
        ↓
App Uses CloudinaryVideoPlayer → Shows optimized video
```

## Prerequisites

1. Firebase project set up
2. Cloudinary account (free tier available)
3. Firebase CLI installed: `npm install -g firebase-tools`
4. Node.js 18+ installed

## Step 1: Create Cloudinary Account

1. Go to https://cloudinary.com
2. Sign up for a free account
3. After login, go to Dashboard
4. Copy the following credentials:
   - **Cloud Name** (e.g., `dxxxxyyyy`)
   - **API Key** (e.g., `123456789012345`)
   - **API Secret** (e.g., `abcdefghijklmnopqrstuvwxyz`)

## Step 2: Set Up Firebase Functions

### 2.1 Install Dependencies

Navigate to the functions directory and install packages:

```bash
cd functions
npm install
```

This will install:
- firebase-admin
- firebase-functions
- cloudinary
- axios

### 2.2 Configure Cloudinary Credentials

Set the Cloudinary credentials in Firebase Functions config:

```bash
firebase functions:config:set \
  cloudinary.cloud_name="YOUR_CLOUD_NAME" \
  cloudinary.api_key="YOUR_API_KEY" \
  cloudinary.api_secret="YOUR_API_SECRET"
```

**Example:**
```bash
firebase functions:config:set \
  cloudinary.cloud_name="dxxxxyyyy" \
  cloudinary.api_key="123456789012345" \
  cloudinary.api_secret="abcdefghijklmnopqrstuvwxyz"
```

### 2.3 Verify Configuration

Check that credentials are set correctly:

```bash
firebase functions:config:get
```

You should see:
```json
{
  "cloudinary": {
    "cloud_name": "YOUR_CLOUD_NAME",
    "api_key": "YOUR_API_KEY",
    "api_secret": "YOUR_API_SECRET"
  }
}
```

## Step 3: Deploy Cloud Functions

### 3.1 Login to Firebase

```bash
firebase login
```

### 3.2 Initialize Project (if not already done)

```bash
firebase init functions
```

Select:
- Use existing project
- JavaScript
- Do not overwrite existing files

### 3.3 Deploy Functions

```bash
firebase deploy --only functions
```

This will deploy three functions:
- `processVideoUpload`: Auto-processes videos on upload
- `deleteVideoFromCloudinary`: Cleans up when videos are deleted
- `processExistingVideo`: HTTP function for manual processing

### 3.4 Verify Deployment

Check Firebase Console → Functions section. You should see:
- ✅ processVideoUpload
- ✅ deleteVideoFromCloudinary
- ✅ processExistingVideo

## Step 4: Update Firestore Security Rules

Add rules to allow video document updates from Cloud Functions:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Video collection rules
    match /videos/{videoId} {
      // Allow reading video metadata
      allow read: if true;

      // Allow admin and Cloud Functions to write
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
      );
    }

    // ... other rules ...
  }
}
```

Deploy security rules:
```bash
firebase deploy --only firestore:rules
```

## Step 5: Test the Integration

### 5.1 Upload a Test Video

1. Login as admin
2. Go to course management
3. Upload a video to any module
4. Video will be uploaded to Firebase Storage at: `videos/{courseId}/{moduleId}/{timestamp}`

### 5.2 Monitor Processing

Watch Cloud Function logs:
```bash
firebase functions:log
```

You should see:
```
[processVideoUpload] File uploaded: videos/course123/module456/1234567890
[processVideoUpload] Uploading to Cloudinary...
[processVideoUpload] ✅ Processing complete
[processVideoUpload] Streaming URL: https://res.cloudinary.com/...
```

### 5.3 Verify Firestore

Check the video document in Firestore. It should have new fields:
- `streamingUrl`: HLS streaming URL (.m3u8)
- `cloudinaryPublicId`: Cloudinary resource ID
- `qualities`: Object with 1080p/720p/480p URLs
- `thumbnailUrl`: Auto-generated thumbnail
- `isCloudinaryProcessed`: true
- `processedAt`: Timestamp

### 5.4 Test Playback

1. Open the course in user view
2. Play the video
3. You should see:
   - "HLS" badge in video controls
   - Smoother playback
   - Faster initial load
   - Automatic quality adjustment

## Step 6: Migrate Existing Videos (Optional)

If you have existing videos in Firebase Storage, you can process them manually:

### 6.1 Get Video IDs

List all videos from Firestore that need processing:
```javascript
// In Firebase Console or your app
db.collection('videos')
  .where('isCloudinaryProcessed', '==', false)
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      console.log('Video ID:', doc.id);
    });
  });
```

### 6.2 Process Videos

For each video ID, call the `processExistingVideo` function:

```javascript
const functions = firebase.functions();
const processVideo = functions.httpsCallable('processExistingVideo');

// Process single video
processVideo({ videoId: 'VIDEO_ID_HERE' })
  .then(result => {
    console.log('✅ Processed:', result.data);
  })
  .catch(error => {
    console.error('❌ Error:', error);
  });
```

### 6.3 Batch Processing Script

Create a script to process all videos:

```javascript
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const functions = admin.functions();

async function processAllVideos() {
  const snapshot = await db.collection('videos')
    .where('isCloudinaryProcessed', '==', false)
    .get();

  console.log(`Found ${snapshot.size} videos to process`);

  for (const doc of snapshot.docs) {
    try {
      const result = await functions.httpsCallable('processExistingVideo')({
        videoId: doc.id
      });
      console.log(`✅ Processed ${doc.id}:`, result.data);

      // Wait 5 seconds between videos to avoid rate limits
      await new Promise(resolve => setTimeout(resolve, 5000));
    } catch (error) {
      console.error(`❌ Failed to process ${doc.id}:`, error.message);
    }
  }

  console.log('Migration complete!');
}

processAllVideos();
```

## Monitoring and Maintenance

### Check Function Logs

View real-time logs:
```bash
firebase functions:log --only processVideoUpload
```

### Monitor Cloudinary Usage

1. Go to Cloudinary Dashboard
2. Check Usage → Transformations
3. Monitor bandwidth and storage

### Error Handling

Common errors and solutions:

**Error: "Cloudinary credentials not configured"**
- Run: `firebase functions:config:get`
- Verify credentials are set
- Redeploy functions

**Error: "Video document not found"**
- Video was likely deleted before processing completed
- This is normal and can be ignored

**Error: "Timeout"**
- Large videos may timeout (9-minute limit)
- Consider using smaller videos or splitting into parts

## Cost Considerations

### Firebase Functions
- **Free Tier**: 2M invocations/month, 400K GB-seconds
- **Video Processing**: ~1-5 seconds per video
- **Typical Cost**: Free for most use cases

### Cloudinary Free Tier
- **Storage**: 25GB
- **Bandwidth**: 25GB/month
- **Transformations**: 25,000/month
- **Videos**: Unlimited

### Upgrade Paths
- Cloudinary Plus: $89/month (100GB storage, 100GB bandwidth)
- Firebase Blaze: Pay-as-you-go for functions

## Troubleshooting

### Videos Not Processing

1. Check Cloud Function logs:
   ```bash
   firebase functions:log --only processVideoUpload
   ```

2. Verify Cloudinary credentials:
   ```bash
   firebase functions:config:get
   ```

3. Test Cloudinary connection manually

### Videos Playing Slowly

1. Check network connection
2. Verify HLS URLs are being used (look for "HLS" badge)
3. Check Cloudinary dashboard for delivery stats

### Old Videos Still Using Firebase

This is normal! The system maintains backward compatibility:
- Old videos continue using Firebase Storage URLs
- Only newly uploaded videos use Cloudinary
- You can manually process old videos (see Step 6)

## Benefits Summary

✅ **Faster Loading**: HLS streaming loads progressively
✅ **Better Quality**: Adaptive bitrate based on network
✅ **Global CDN**: Cloudinary serves from nearest location
✅ **Lower Bandwidth**: Users get appropriate quality for their connection
✅ **Automatic Thumbnails**: Generated during processing
✅ **Zero Downtime**: Existing videos continue working
✅ **Cost Effective**: Free tier covers most educational apps

## Support

If you encounter issues:
1. Check Firebase Console → Functions → Logs
2. Check Cloudinary Dashboard → Reports → Activity
3. Review error messages in Flutter app console
4. Check Firestore video documents for processing status

## Next Steps

After setup:
1. Monitor first few video uploads
2. Verify HLS streaming works on different devices
3. Check Cloudinary usage dashboard
4. Consider migrating existing videos
5. Set up alerts for function errors

---

**Congratulations!** Your video streaming is now optimized with Cloudinary + Firebase.
