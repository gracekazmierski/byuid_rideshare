// Required for Firebase Cloud Messaging
importScripts('https://www.gstatic.com/firebasejs/10.12.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.1/firebase-messaging-compat.js');

// Initialize Firebase
firebase.initializeApp({
  apiKey: "AIzaSyA-tJ6PwtYBQbEKhVxIDQ8g2cIWvxAx5L4",
  authDomain: "byuirideshare.firebaseapp.com",
  projectId: "byuirideshare",
  messagingSenderId: "527415309529",
  appId: "1:527415309529:android:96908e26b8b7111034bac8"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();
