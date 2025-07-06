import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onNewMatch = onDocumentCreated(
  "matches/{matchId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return;
    }
    try {
      const matchData = snapshot.data();
      if (!matchData) {
        console.log("No match data found.");
        return;
      }

      const matchMembers: string[] = matchData.members;
      if (!matchMembers || matchMembers.length === 0) {
        console.log("No members in the match.");
        return;
      }

      // Get the user who INITIATED the match
      const initiatorId = matchData.user1Id;
      const initiatorDoc = await admin.firestore()
        .collection("users").doc(initiatorId).get();
      const initiatorName = initiatorDoc.data()?.name || "Someone";

      // Prepare a notification payload
      const payload = {
        notification: {
          title: "You have a new match! 🎉",
          body: `${initiatorName} matched with you. Start a conversation!`,
          badge: "1",
          sound: "default",
        },
      };

      // Send notifications to all OTHER members of the match
      const messaging = admin.messaging();
      for (const memberId of matchMembers) {
        if (memberId === initiatorId) continue;

        try {
          const memberDoc = await admin.firestore()
            .collection("users").doc(memberId).get();
          const memberTokens: string[] = memberDoc.data()?.fcmTokens;

          if (memberTokens && memberTokens.length > 0) {
            console.log(`Sending match notification to ${memberId}`);
            await messaging.sendToDevice(memberTokens, payload);
          }
        } catch (error) {
          console.error(`Failed to process member ${memberId}:`, error);
        }
      }
    } catch (error) {
      console.error("Error in onNewMatch function:", error);
    }
  });

/**
 * Triggered when a new message is sent in any chat room.
 * Sends a notification to all other members of the chat.
 */
export const onNewMessage = onDocumentCreated(
  "messages/{matchId}/chats/{messageId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return;
    }

    try {
      const messageData = snapshot.data();
      if (!messageData) {
        console.log("No message data found.");
        return;
      }

      const senderId = messageData.senderId;
      const messageContent = messageData.content;
      const matchId = event.params.matchId;

      // Get the sender's name
      const senderDoc = await admin.firestore()
        .collection("users").doc(senderId).get();
      const senderName = senderDoc.data()?.name || "Someone";

      // Get the list of all members in this chat from the parent match
      const matchDoc = await admin.firestore()
        .collection("matches").doc(matchId).get();
      const matchMembers: string[] = matchDoc.data()?.members;

      if (!matchMembers || matchMembers.length === 0) {
        console.log("No members found for this chat.");
        return;
      }

      // Prepare the notification payload
      const payload = {
        notification: {
          title: `New message from ${senderName}`,
          body: messageContent.length > 100 ?
            messageContent.substring(0, 100) + "..." : messageContent,
          badge: "1",
          sound: "default",
        },
        data: {
          "chatRoomId": matchId,
        },
      };

      // Send notifications to all members of the chat EXCEPT the sender
      const messaging = admin.messaging();
      for (const memberId of matchMembers) {
        if (memberId === senderId) continue;

        try {
          const memberDoc = await admin.firestore()
            .collection("users").doc(memberId).get();
          const memberTokens: string[] = memberDoc.data()?.fcmTokens;

          if (memberTokens && memberTokens.length > 0) {
            console.log(`Sending message notification to ${memberId}`);
            await messaging.sendToDevice(memberTokens, payload);
          }
        } catch (error) {
          console.error(`Failed to process member ${memberId}:`, error);
        }
      }
    } catch (error) {
      console.error("Error in onNewMessage function:", error);
    }
  });

export const updateAllUserProfiles = onCall(async (request) => {
  // IMPORTANT: This function is for demonstration and development purposes only.
  // In a production environment, you should implement proper authentication
  // and authorization checks to ensure only authorized users can trigger this
  // function. For example, check if request.auth.token.admin === true

  console.log("Starting updateAllUserProfiles function...");

  const usersRef = admin.firestore().collection("users");
  const snapshot = await usersRef.get();

  if (snapshot.empty) {
    console.log("No users found.");
    return {success: true, message: "No users to update."};
  }

  const photoUrls: string[] = request.data.photoUrls || [];
  if (photoUrls.length === 0) {
    return {success: false, message: "No photo URLs provided."};
  }

  const batch = admin.firestore().batch();
  let updatedCount = 0;
  let photoUrlIndex = 0;

  for (const doc of snapshot.docs) {
    const uid = doc.id;

    // Generate artificial data
    const newName = `User ${Math.random().toString(36).substring(7)}`;
    const newBio = `This is an artificially generated bio for user ${uid}. ` +
                   `They are interested in co-housing and community living.`;

    // Assign photoUrl in a round-robin fashion
    const newPhotoUrl = photoUrls[photoUrlIndex];
    photoUrlIndex = (photoUrlIndex + 1) % photoUrls.length;

    batch.update(doc.ref, {
      name: newName,
      bio: newBio,
      photoUrl: newPhotoUrl,
    });
    updatedCount++;
  }

  await batch.commit();
  console.log(`Successfully updated ${updatedCount} user profiles.`);

  return {success: true, message: `Updated ${updatedCount} user profiles.`};
});

export const deleteProfileImages = onCall(async () => {
  console.log("Starting deleteProfileImages function...");

  const usersRef = admin.firestore().collection("users");
  const snapshot = await usersRef.get();

  if (snapshot.empty) {
    console.log("No users found to delete images for.");
    return {success: true, message: "No users to process."};
  }

  const storage = admin.storage();
  const bucket = storage.bucket(); // Gets the default bucket

  let deletedCount = 0;
  const batch = admin.firestore().batch();

  for (const doc of snapshot.docs) {
    const userData = doc.data();
    const uid = doc.id;
    const photoUrl = userData.photoUrl;

    if (photoUrl && typeof photoUrl === "string" &&
        photoUrl.includes("firebasestorage.googleapis.com")) {
      try {
        // Extract the path from the Firebase Storage URL
        // Example URL: https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/images%2Fprofile%2Fuser123.jpg?alt=media...
        const url = new URL(photoUrl);
        const path = decodeURIComponent(url.pathname.split("/o/")[1].split("?")[0]);

        console.log(`Attempting to delete image: ${path} for user: ${uid}`);
        await bucket.file(path).delete();
        console.log(`Successfully deleted image: ${path}`);

        batch.update(doc.ref, {photoUrl: null}); // Clear photoUrl in Firestore
        deletedCount++;
      } catch (error) {
        console.error(`Failed to delete image for user ${uid} (${photoUrl}):`,
          error);
      }
    } else if (photoUrl) {
      console.log(`Skipping non-Firebase Storage URL for user ${uid}: ${photoUrl}`);
    }
  }

  await batch.commit();
  console.log(`Successfully processed and deleted ${deletedCount} profile images.`);

  return {success: true, message: `Deleted ${deletedCount} profile images.`};
});
