import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const storage = admin.storage();

// This function runs on a schedule, e.g., every hour.
export const deleteExpiredStories = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    functions.logger.info("Running scheduled story deletion job at", now.toDate());

    // 1. Query for expired stories
    const expiredStoriesQuery = db.collection("stories")
      .where("expiresAt", "<=", now);

    const snapshot = await expiredStoriesQuery.get();

    if (snapshot.empty) {
      functions.logger.info("No expired stories found. Exiting job.");
      return null;
    }

    functions.logger.info(`Found ${snapshot.size} expired stories to delete.`);

    // 2. Prepare batch deletion for Firestore documents
    const batch = db.batch();
    const storageDeletePromises: Promise<any>[] = [];

    snapshot.docs.forEach((doc) => {
      // Add Firestore document to batch delete
      batch.delete(doc.ref);

      // 3. Prepare deletion for associated media file in Storage
      const storyData = doc.data();
      const mediaUrl = storyData.mediaUrl;

      if (mediaUrl && typeof mediaUrl === "string") {
        const filePath = getPathFromUrl(mediaUrl);
        if (filePath) {
          functions.logger.log(`Queueing storage file for deletion: ${filePath}`);
          const file = storage.bucket().file(filePath);
          storageDeletePromises.push(file.delete().catch((err) => {
            // Log error but don't fail the whole job if one file fails
            functions.logger.error(
              `Failed to delete file: ${filePath} for story ${doc.id}`,
              err
            );
          }));
        } else {
          functions.logger.warn(
            `Could not parse file path from URL: ${mediaUrl} for story ${doc.id}`
          );
        }
      }
    });

    // 4. Execute all deletions
    await Promise.all([
      batch.commit(),
      ...storageDeletePromises,
    ]);

    functions.logger.info(
      `Successfully deleted ${snapshot.size} stories from Firestore and attempted to delete ${storageDeletePromises.length} files from Storage.`
    );
    return null;
  });

/**
 * Extracts the file path from a Firebase Storage download URL.
 * @param {string} url The download URL.
 * @return {string | null} The decoded file path or null if parsing fails.
 */
function getPathFromUrl(url: string): string | null {
  try {
    // The path is the segment after /o/ and before ?alt=media
    const pathSegment = url.split("/o/")[1];
    const filePath = pathSegment.split("?alt=media")[0];
    return decodeURIComponent(filePath);
  } catch (error) {
    functions.logger.error(`Error parsing URL: "${url}"`, error);
    return null;
  }
}
