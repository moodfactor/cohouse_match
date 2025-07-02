importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: "AIzaSyAX836hfK3oL1clxNC4WFJQifQ53_oRjV0",
  authDomain: "cohousematch.firebaseapp.com",
  projectId: "cohousematch",
  storageBucket: "cohousematch.firebasestorage.app",
  messagingSenderId: "242037756353",
  appId: "1:242037756353:web:9c5d83a530dce871971f40"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// Optional: Handle background messages here
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = 'Background Message Title';
  const notificationOptions = {
    body: 'Background Message body.',
    icon: '/firebase-logo.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});