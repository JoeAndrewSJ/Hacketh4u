/**
 * Hackethos4u Cloud Functions
 * Video Processing with Cloudinary Integration
 *
 * This function automatically processes videos uploaded to Firebase Storage
 * and creates optimized streaming versions via Cloudinary
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cloudinary = require('cloudinary').v2;
const axios = require('axios');

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Configure Cloudinary
// These values should be set in Firebase Functions config
// Run: firebase functions:config:set cloudinary.cloud_name="YOUR_CLOUD_NAME" cloudinary.api_key="YOUR_API_KEY" cloudinary.api_secret="YOUR_API_SECRET"
// Note: In firebase-functions v5+, we use process.env to access config values
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Cloud Function: Process Video Upload
 * Triggers when a file is uploaded to Firebase Storage
 * Filters for video files in the 'videos/' path
 */
exports.processVideoUpload = functions
  .runWith({
    timeoutSeconds: 540, // 9 minutes (max for Cloud Functions)
    memory: '2GB',
  })
  .storage
  .object()
  .onFinalize(async (object) => {
    try {
      const filePath = object.name;
      const contentType = object.contentType;

      console.log(`[processVideoUpload] File uploaded: ${filePath}`);
      console.log(`[processVideoUpload] Content type: ${contentType}`);

      // Only process video files in the videos/ directory
      if (!filePath.startsWith('videos/')) {
        console.log(`[processVideoUpload] Skipping - not in videos/ directory`);
        return null;
      }

      if (!contentType || !contentType.startsWith('video/')) {
        console.log(`[processVideoUpload] Skipping - not a video file`);
        return null;
      }

      // Extract course and module IDs from path
      // Path format: videos/{courseId}/{moduleId}/{timestamp}
      const pathParts = filePath.split('/');
      if (pathParts.length < 4) {
        console.log(`[processVideoUpload] Skipping - invalid path structure`);
        return null;
      }

      const courseId = pathParts[1];
      const moduleId = pathParts[2];
      const fileName = pathParts[3];

      console.log(`[processVideoUpload] Course ID: ${courseId}, Module ID: ${moduleId}`);

      // Get Firebase Storage download URL
      const bucket = admin.storage().bucket(object.bucket);
      const file = bucket.file(filePath);

      // Make file temporarily public for Cloudinary to access
      await file.makePublic();
      const firebaseUrl = `https://storage.googleapis.com/${object.bucket}/${encodeURIComponent(filePath)}`;

      console.log(`[processVideoUpload] Firebase URL: ${firebaseUrl}`);

      // Find the video document in Firestore
      const videosSnapshot = await db.collection('videos')
        .where('courseId', '==', courseId)
        .where('moduleId', '==', moduleId)
        .where('videoUrl', '==', await file.getSignedUrl({
          action: 'read',
          expires: '03-01-2500'
        }).then(urls => urls[0]))
        .limit(1)
        .get();

      let videoDocId = null;

      if (!videosSnapshot.empty) {
        videoDocId = videosSnapshot.docs[0].id;
        console.log(`[processVideoUpload] Found video document: ${videoDocId}`);
      } else {
        // Try to find by matching timestamp in filename
        const timestamp = fileName.split('.')[0]; // Remove extension
        const allVideos = await db.collection('videos')
          .where('courseId', '==', courseId)
          .where('moduleId', '==', moduleId)
          .get();

        for (const doc of allVideos.docs) {
          const videoUrl = doc.data().videoUrl || '';
          if (videoUrl.includes(timestamp)) {
            videoDocId = doc.id;
            console.log(`[processVideoUpload] Found video by timestamp match: ${videoDocId}`);
            break;
          }
        }
      }

      if (!videoDocId) {
        console.log(`[processVideoUpload] Video document not found in Firestore, will create placeholder`);
      }

      // Upload to Cloudinary with streaming configuration
      console.log(`[processVideoUpload] Starting Cloudinary upload...`);

      const uploadResult = await cloudinary.uploader.upload(firebaseUrl, {
        resource_type: 'video',
        folder: `hackethos4u/courses/${courseId}/modules/${moduleId}`,
        public_id: fileName.split('.')[0], // Use timestamp as public ID
        overwrite: true,

        // Streaming configuration
        eager: [
          // HLS streaming - adaptive bitrate
          {
            streaming_profile: 'full_hd', // 1080p
            format: 'm3u8',
          },
          {
            streaming_profile: 'hd', // 720p
            format: 'm3u8',
          },
          {
            streaming_profile: 'sd', // 480p
            format: 'm3u8',
          },
        ],
        eager_async: true, // Process in background

        // Generate thumbnail
        eager_notification_url: functions.config().app?.url || undefined,
      });

      console.log(`[processVideoUpload] Cloudinary upload successful!`);
      console.log(`[processVideoUpload] Public ID: ${uploadResult.public_id}`);
      console.log(`[processVideoUpload] Secure URL: ${uploadResult.secure_url}`);

      // Construct streaming URLs
      const streamingData = {
        cloudinaryPublicId: uploadResult.public_id,
        cloudinaryUrl: uploadResult.secure_url,

        // HLS streaming URLs (will be available after eager processing)
        streamingUrl: uploadResult.secure_url.replace(/\.(mp4|mov|avi)$/, '.m3u8'),

        // Quality-specific URLs
        qualities: {
          '1080p': `https://res.cloudinary.com/${cloudinary.config().cloud_name}/video/upload/sp_full_hd/${uploadResult.public_id}.m3u8`,
          '720p': `https://res.cloudinary.com/${cloudinary.config().cloud_name}/video/upload/sp_hd/${uploadResult.public_id}.m3u8`,
          '480p': `https://res.cloudinary.com/${cloudinary.config().cloud_name}/video/upload/sp_sd/${uploadResult.public_id}.m3u8`,
        },

        // Thumbnail URL
        thumbnailUrl: uploadResult.secure_url.replace(/\.(mp4|mov|avi)$/, '.jpg'),

        // Metadata
        duration: uploadResult.duration,
        format: uploadResult.format,
        width: uploadResult.width,
        height: uploadResult.height,

        // Processing status
        isCloudinaryProcessed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Update Firestore video document
      if (videoDocId) {
        await db.collection('videos').doc(videoDocId).update(streamingData);
        console.log(`[processVideoUpload] Updated video document with streaming URLs`);
      } else {
        console.log(`[processVideoUpload] No video document to update, streaming data saved:`, streamingData);
      }

      // Log success
      console.log(`[processVideoUpload] ✅ Processing complete for ${fileName}`);
      console.log(`[processVideoUpload] Streaming URL: ${streamingData.streamingUrl}`);

      return { success: true, videoDocId, streamingData };

    } catch (error) {
      console.error(`[processVideoUpload] ❌ Error processing video:`, error);
      console.error(`[processVideoUpload] Error details:`, error.message, error.stack);

      // Don't throw - just log the error
      // This prevents retries that would waste resources
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: Delete Video from Cloudinary
 * Triggers when a video document is deleted from Firestore
 */
exports.deleteVideoFromCloudinary = functions
  .firestore
  .document('videos/{videoId}')
  .onDelete(async (snapshot, context) => {
    try {
      const videoData = snapshot.data();
      const videoId = context.params.videoId;

      console.log(`[deleteVideoFromCloudinary] Video deleted from Firestore: ${videoId}`);

      // Check if video was processed by Cloudinary
      if (!videoData.cloudinaryPublicId) {
        console.log(`[deleteVideoFromCloudinary] No Cloudinary public ID, skipping deletion`);
        return null;
      }

      // Delete from Cloudinary
      console.log(`[deleteVideoFromCloudinary] Deleting from Cloudinary: ${videoData.cloudinaryPublicId}`);

      const deleteResult = await cloudinary.uploader.destroy(
        videoData.cloudinaryPublicId,
        { resource_type: 'video' }
      );

      console.log(`[deleteVideoFromCloudinary] ✅ Deleted from Cloudinary:`, deleteResult);

      return { success: true, result: deleteResult };

    } catch (error) {
      console.error(`[deleteVideoFromCloudinary] ❌ Error:`, error);
      // Don't throw - video is already deleted from Firestore
      return { success: false, error: error.message };
    }
  });

/**
 * HTTP Function: Manual Video Processing
 * Call this to manually process existing videos
 *
 * Usage: POST https://<region>-<project-id>.cloudfunctions.net/processExistingVideo
 * Body: { "videoId": "VIDEO_DOCUMENT_ID" }
 */
exports.processExistingVideo = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '2GB',
  })
  .https
  .onCall(async (data, context) => {
    try {
      // Verify authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Must be authenticated to process videos'
        );
      }

      const videoId = data.videoId;
      if (!videoId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'videoId is required'
        );
      }

      console.log(`[processExistingVideo] Processing video: ${videoId}`);

      // Get video document
      const videoDoc = await db.collection('videos').doc(videoId).get();

      if (!videoDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          `Video document ${videoId} not found`
        );
      }

      const videoData = videoDoc.data();
      const videoUrl = videoData.videoUrl;

      if (!videoUrl) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Video URL not found in document'
        );
      }

      // Check if already processed
      if (videoData.isCloudinaryProcessed) {
        console.log(`[processExistingVideo] Video already processed`);
        return {
          success: true,
          message: 'Video already processed',
          streamingUrl: videoData.streamingUrl,
        };
      }

      console.log(`[processExistingVideo] Uploading to Cloudinary: ${videoUrl}`);

      // Upload to Cloudinary
      const uploadResult = await cloudinary.uploader.upload(videoUrl, {
        resource_type: 'video',
        folder: `hackethos4u/courses/${videoData.courseId}/modules/${videoData.moduleId}`,
        public_id: videoId,
        overwrite: true,
        eager: [
          { streaming_profile: 'full_hd', format: 'm3u8' },
          { streaming_profile: 'hd', format: 'm3u8' },
          { streaming_profile: 'sd', format: 'm3u8' },
        ],
        eager_async: true,
      });

      // Construct streaming data
      const streamingData = {
        cloudinaryPublicId: uploadResult.public_id,
        cloudinaryUrl: uploadResult.secure_url,
        streamingUrl: uploadResult.secure_url.replace(/\.(mp4|mov|avi)$/, '.m3u8'),
        qualities: {
          '1080p': `https://res.cloudinary.com/${cloudinary.config().cloud_name}/video/upload/sp_full_hd/${uploadResult.public_id}.m3u8`,
          '720p': `https://res.cloudinary.com/${cloudinary.config().cloud_name}/video/upload/sp_hd/${uploadResult.public_id}.m3u8`,
          '480p': `https://res.cloudinary.com/${cloudinary.config().cloud_name}/video/upload/sp_sd/${uploadResult.public_id}.m3u8`,
        },
        thumbnailUrl: uploadResult.secure_url.replace(/\.(mp4|mov|avi)$/, '.jpg'),
        duration: uploadResult.duration || videoData.duration,
        isCloudinaryProcessed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Update Firestore
      await db.collection('videos').doc(videoId).update(streamingData);

      console.log(`[processExistingVideo] ✅ Processing complete`);

      return {
        success: true,
        message: 'Video processed successfully',
        streamingUrl: streamingData.streamingUrl,
        qualities: streamingData.qualities,
      };

    } catch (error) {
      console.error(`[processExistingVideo] ❌ Error:`, error);
      throw new functions.https.HttpsError(
        'internal',
        `Error processing video: ${error.message}`
      );
    }
  });
