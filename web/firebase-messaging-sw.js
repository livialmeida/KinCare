// Technical: Import Firebase Web compatibility scripts for background push
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Technical: Initialize Firebase instance within Service Worker environment
// Values mapped to the KinCare project (kincare-9b1d4)
firebase.initializeApp({
  apiKey: "AIzaSyDHvHQXQEyQOZ2eZA68CurMgOgS2ZU1WOg", // Technical: Copied from DefaultFirebaseOptions.web in firebase_options.dart
  appId: "1:180428775925:web:d365f8dd3d778520f340bc",   // Technical: Copied from DefaultFirebaseOptions.web in firebase_options.dart
  messagingSenderId: "180428775925",
  projectId: "kincare-9b1d4",
  authDomain: "kincare-9b1d4.firebaseapp.com",
  storageBucket: "kincare-9b1d4.firebasestorage.app",
});

const messaging = firebase.messaging();

// Technical: 1x1 transparent PNG data URI to eliminate the right-hand thumbnail
const EMPTY_ICON = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

// Technical: Map notification payload type to Flutter Web routing destination
function resolveRouteFromType(type) {
  switch (type) {
    case 'new_order':
    case 'order_status':
    case 'order_accepted':
    case 'surprise':
      return '/#/orders';

    case 'stock_expiry':
      return '/#/stock';

    case 'pantry_access_request':
    case 'pending_user_registration':
    case 'pantry_access_granted':
    case 'user_approved':
      return '/#/account';

    default:
      return '/#/stock';
  }
}

// Technical: Resolve target route prioritizing explicit route over inferred type
function getTargetRoute(data) {
  if (!data) return '/#/stock';

  let rawRoute = data.route || data.targetRoute;

  if (rawRoute) {
    // Technical: Sanitize route string to prevent duplicate hashes or slashes
    rawRoute = rawRoute.replace(/^(\/#|\/|#\/|#)+/, '');
    return `/#/${rawRoute}`;
  }

  return resolveRouteFromType(data.type || '');
}

// Technical: Background push listener with deduplication guard
messaging.onBackgroundMessage((payload) => {
  // Technical: Prevent duplicate banners if the browser natively rendered payload.notification
  if (payload.notification) {
    return;
  }

  const type = payload.data?.type || 'general';
  const title = payload.data?.title || 'KinCare';
  const body = payload.data?.body || 'Nova notificação recebida.';

  const notificationOptions = {
    body: body,
    icon: EMPTY_ICON,
    data: payload.data,
    tag: type,
    requireInteraction: true,
  };

  return self.registration.showNotification(title, notificationOptions);
});

// Technical: Notification click handler supporting live tab switching via postMessage
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification.data || {};
  const targetPath = getTargetRoute(data);
  const targetUrl = new URL(targetPath, self.location.origin).href;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Technical: Check if app is already open in an existing browser tab
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          // Technical: Send target route to active tab without full page reload or splash screen
          client.postMessage({
            type: 'NAVIGATE_TAB',
            route: targetPath,
          });
          return client.focus();
        }
      }

      // Technical: Fallback for cold boot when no tab is open
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});