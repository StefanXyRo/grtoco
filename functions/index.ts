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

export const deleteDisappearingMessages = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    functions.logger.info("Running scheduled job to delete disappearing messages.");

    const conversationsSnapshot = await db.collection("conversations").get();
    if (conversationsSnapshot.empty) {
      functions.logger.info("No conversations found.");
      return null;
    }

    const promises: Promise<any>[] = [];

    for (const conversationDoc of conversationsSnapshot.docs) {
      const messagesQuery = conversationDoc.ref.collection("messages")
        .where("disappearAfter", ">", 0);

      const messagesSnapshot = await messagesQuery.get();

      if (!messagesSnapshot.empty) {
        const batch = db.batch();
        let deletedCount = 0;

        messagesSnapshot.docs.forEach((messageDoc) => {
          const message = messageDoc.data();
          const sentAt = (message.timestamp as admin.firestore.Timestamp).toDate();
          const hoursToDisappear = message.disappearAfter as number;
          const disappearsAt = new Date(sentAt.getTime() + hoursToDisappear * 60 * 60 * 1000);

          if (new Date() > disappearsAt) {
            batch.delete(messageDoc.ref);
            deletedCount++;
          }
        });

        if (deletedCount > 0) {
          promises.push(batch.commit());
          functions.logger.info(`Deleting ${deletedCount} messages from conversation ${conversationDoc.id}`);
        }
      }
    }

    await Promise.all(promises);
    functions.logger.info("Finished deleting disappearing messages.");
    return null;
  });

export const sendEventReminders = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    const now = new Date();
    const twentyFourHoursFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);

    const eventsSnapshot = await db
      .collection("interactive_posts")
      .where("postType", "==", "event")
      .where("eventDate", ">", now)
      .get();

    if (eventsSnapshot.empty) {
      functions.logger.info("No upcoming events found.");
      return null;
    }

    const notificationPromises: Promise<any>[] = [];

    eventsSnapshot.docs.forEach((doc) => {
      const event = doc.data();
      const eventDate = (event.eventDate as admin.firestore.Timestamp).toDate();

      const shouldSend24HourReminder =
        eventDate > now &&
        eventDate <= twentyFourHoursFromNow &&
        !event.sent24HourReminder;

      const shouldSend2HourReminder =
        eventDate > now &&
        eventDate <= twoHoursFromNow &&
        !event.sent2HourReminder;

      if (shouldSend24HourReminder || shouldSend2HourReminder) {
        const userIds: string[] = [
          ...(event.rsvpStatus?.going ?? []),
          ...(event.rsvpStatus?.interested ?? []),
        ];

        if (userIds.length > 0) {
          const message = shouldSend24HourReminder
            ? `Reminder: The event "${event.eventName}" is tomorrow.`
            : `Reminder: The event "${event.eventName}" starts in 2 hours.`;

          userIds.forEach((userId) => {
            notificationPromises.push(sendPushNotification(userId, message));
          });
        }

        const updatePayload: { [key: string]: boolean } = {};
        if (shouldSend24HourReminder) {
          updatePayload.sent24HourReminder = true;
        }
        if (shouldSend2HourReminder) {
          updatePayload.sent2HourReminder = true;
        }
        notificationPromises.push(doc.ref.update(updatePayload));
      }
    });

    await Promise.all(notificationPromises);
    functions.logger.info("Finished sending event reminders.");
    return null;
  });

async function sendPushNotification(userId: string, message: string) {
  // TODO: Implement push notification logic
  functions.logger.info(`Sending push notification to ${userId}: ${message}`);
  return Promise.resolve();
}

export const onPostCreate = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const post = snap.data();
    if (!post || !post.textContent) {
      functions.logger.info("Post has no text content, exiting.");
      return null;
    }

    const textContent = post.textContent as string;
    const updatePayload: { [key: string]: any } = {};
    const notificationPromises: Promise<any>[] = [];

    // 1. Parse hashtags
    const hashtagRegex = /#(\w+)/g;
    const hashtags = textContent.match(hashtagRegex) || [];
    if (hashtags.length > 0) {
      updatePayload.hashtags = hashtags;
      functions.logger.info(`Found hashtags: ${hashtags.join(", ")}`);
    }

    // 2. Parse mentions
    const mentionRegex = /@(\w+)/g;
    const mentions = textContent.match(mentionRegex);
    if (mentions && mentions.length > 0) {
      const mentionedUsernames = mentions.map((m) => m.substring(1)); // Remove "@"
      const mentionedUserIds: string[] = [];

      // Find user IDs from usernames.
      // This is a simplified approach. A real-world app would need a more
      // robust user search/mention system.
      const usersQuery = await db.collection("users")
        .where("displayName", "in", mentionedUsernames)
        .get();

      usersQuery.forEach((doc) => {
        const user = doc.data();
        mentionedUserIds.push(doc.id);

        // 3. Prepare notifications
        const notificationMessage =
          `You were mentioned in a post by ${post.authorId}`;
        notificationPromises.push(
          sendPushNotification(doc.id, notificationMessage)
        );
      });

      if (mentionedUserIds.length > 0) {
        updatePayload.mentionedUserIds = mentionedUserIds;
        functions.logger.info(`Found mentioned user IDs: ${mentionedUserIds.join(", ")}`);
      }
    }

    // 4. Update post document if needed
    if (Object.keys(updatePayload).length > 0) {
      await snap.ref.update(updatePayload);
      functions.logger.info(`Updated post ${context.params.postId} with parsed data.`);
    }

    // 5. Send all notifications
    await Promise.all(notificationPromises);

    return null;
  });
