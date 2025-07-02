importScripts("https://www.gstatic.com/firebasejs/9.2.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/9.2.0/firebase-messaging.js");

// Initialize the Firebase app in the service worker by passing in the messagingSenderId.
firebase.initializeApp({
    apiKey: "AIzaSyAX836hfK3oL1clxNC4WFJQifQ53_oRjV0",
    authDomain: "cohousematch.firebaseapp.com",
    projectId: "cohousematch",
    storageBucket: "cohousematch.firebasestorage.app",
    messagingSenderId: "242037756353",
    appId: "1:242037756353:web:9c5d83a530dce871971f40"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();