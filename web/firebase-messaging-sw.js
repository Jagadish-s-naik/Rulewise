// Minimal Firebase Messaging Service Worker
importScripts("https://www.gstatic.com/firebasejs/9.1.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.1.1/firebase-messaging-compat.js");

// This is a minimal placeholder. 
// Firebase initialization on web will handle registration if not already present.
// For real background notifications, the config should match firebase_options.dart
console.log('Firebase Messaging Service Worker loaded.');
