import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

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
