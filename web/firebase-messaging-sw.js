// Firebase Cloud Messaging service worker for Rozgar web push notifications.
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAbvAip7Ezqt7J18qlTH7-3rezo5Bg5SOw',
  appId: '1:533986648017:web:7fbe77e80d90bb93488af0',
  messagingSenderId: '533986648017',
  projectId: 'jobportal-b7092',
  authDomain: 'jobportal-b7092.firebaseapp.com',
  storageBucket: 'jobportal-b7092.firebasestorage.app',
  measurementId: 'G-JLCWQ8DD9C',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message:', payload);
});
