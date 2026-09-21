import { config } from '../config/env.js';
import { deviceTokenStore } from './deviceTokenStore.js';
import { createNotificationService } from './notificationService.js';
import { createPushSender } from './pushSenders.js';

/**
 * The app-wide notification service, built once on first use from the
 * environment (FCM_ENABLED / FIREBASE_SERVICE_ACCOUNT). Callers get a promise
 * so building it (which may load firebase-admin) never blocks a request.
 */
let servicePromise;

export function getNotificationService() {
  servicePromise ??= createPushSender({ config: config.push }).then((sender) =>
    createNotificationService({ store: deviceTokenStore, sender })
  );
  return servicePromise;
}
