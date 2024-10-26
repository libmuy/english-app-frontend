const CACHE_NAME = 'my-cache-v1';
// const urlsToCache = [
//   '/',
//   '/index.html',
//   '/main.dart.js',
//   // Add other assets you want to cache
// ];

self.addEventListener('install', (event) => {
  console.log('[Service Worker] Install Event');
  //   event.waitUntil(
  //     caches.open(CACHE_NAME).then((cache) => {
  //       console.log('[Service Worker] Caching App Shell');
  //       return cache.addAll(urlsToCache);
  //     })
  //   );
  self.skipWaiting(); // Activate the new service worker immediately
});

self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activate Event');
  return self.clients.claim(); // Take control immediately without clearing cache
});

self.addEventListener('fetch', (event) => {
  const requestUrl = new URL(event.request.url);
  console.log('[Service Worker] Fetch Event for ', requestUrl.href);

  if (!requestUrl.pathname.startsWith('/resources/')) {
    console.log('[Service Worker] Skip cache request: ', requestUrl.href);
    event.respondWith(
      fetch(event.request).catch(function(error) {
          console.error('[Service Worker] Fetch failed:', error);
          throw error;
      })
  );
    return;
  }

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((response) => {
        if (response) {
          console.log('[Service Worker] Returning Cached Resource:', requestUrl.href);
          return response;
        }
        console.log('[Service Worker] Fetching Resource:', requestUrl.href);
        return fetch(event.request).then((networkResponse) => {
          console.log('[Service Worker] Caching New Resource:', requestUrl.href);
          cache.put(event.request, networkResponse.clone());
          return networkResponse;
        });
      });
    })
  );
});

// Listen for messages from the main thread to clear cache
self.addEventListener('message', (event) => {
  if (event.data.action === 'clearCache') {
    console.log('[Service Worker] Clearing Cache');
    caches.keys().then((cacheNames) => {
      cacheNames.forEach((cacheName) => {
        console.log('[Service Worker] Deleting Cache:', cacheName);
        caches.delete(cacheName);
      });
    });
  } else if (event.data.action === 'cacheResource') {
    console.log('[Service Worker] Caching Resource:', event.data.url);
    caches.open(CACHE_NAME).then((cache) => {
      cache.add(event.data.url).then(() => {
        console.log('[Service Worker] Resource Cached:', event.data.url);
      }).catch((error) => {
        console.error('[Service Worker] Resource Caching Failed:', event.data.url, error);
      });
    });
  } else if (event.data.action === 'getCachedUrl') {
    console.log('[Service Worker] Getting Cached URL:', event.data.url);
    caches.open(CACHE_NAME).then((cache) => {
      cache.match(event.data.url).then((response) => {
        if (response) {
          console.log('[Service Worker] Cached URL Found:', event.data.url);
          response.blob().then((blob) => {
            event.ports[0].postMessage(blob);
          });
        } else {
          console.log('[Service Worker] Cached URL Not Found:', event.data.url);
          event.ports[0].postMessage(null);
        }
      });
    });
  }
});

