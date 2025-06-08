// functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

/**
 * Рекурсивно оновлює лічильник totalCardCount у вказаній колоді
 * та всіх її батьківських колодах.
 * @param {string | null} deckId ID колоди для оновлення.
 * @param {number} incrementValue Значення, на яке змінити лічильник (+1/-1).
 * @param {import('firebase-admin').firestore.WriteBatch} batch Об'єкт WriteBatch.
 * @returns {Promise<void>}
 */
async function updateAncestorDeckCounts(deckId, incrementValue, batch) {
  if (!deckId) {
    return; // Досягли вершини ієрархії або deckId не передано
  }

  const deckRef = db.collection("decks").doc(deckId);
  let currentParentId = null;

  try {
    const deckSnapshot = await deckRef.get();

    if (deckSnapshot.exists) {
      batch.update(deckRef, {
        totalCardCount: admin.firestore.FieldValue.increment(incrementValue),
      });
      const deckData = deckSnapshot.data();
      // Перевіряємо, чи deckData існує перед доступом до parentId
      currentParentId = (deckData && deckData.parentId) ? deckData.parentId : null;
    } else {
      functions.logger.warn(
        `Deck ${deckId} not found during count update.`,
      );
      return; // Зупиняємо рекурсію для цієї гілки
    }

    // Рекурсивний виклик для батьківської колоди
    if (currentParentId) {
      await updateAncestorDeckCounts(currentParentId, incrementValue, batch);
    }
  } catch (error) {
    functions.logger.error(
      `Error processing deck ${deckId} for count update:`,
      error,
    );
  }
}

/**
 * Тригер Firestore, що спрацьовує при створенні нової картки.
 * Оновлює лічильник totalCardCount у відповідній колоді та її батьках.
 */
exports.onCardCreated = functions
  .region("europe-west1") // !! ВАЖЛИВО: Вкажіть ваш регіон !!
  .firestore.document("flashcards/{cardId}")
  .onCreate(async snapshot => {
    const cardData = snapshot.data();
    if (!cardData) {
      functions.logger.error("Card data is undefined for onCreate trigger");
      return null;
    }
    const deckId = cardData.deckId;

    if (deckId) {
      const batch = db.batch();
      await updateAncestorDeckCounts(deckId, 1, batch);
      try {
        await batch.commit();
        functions.logger.log(
          `Successfully updated counts for card creation in deck ${deckId}`,
        );
      } catch (error) {
        functions.logger.error(
          `Error committing batch for card creation in deck ${deckId}.`,
          error, // Додав помилку до логування
        );
      }
    } else {
      functions.logger.warn(
        `Card ${snapshot.id} created without a deckId.`,
      );
    }
    return null;
  });

/**
 * Тригер Firestore, що спрацьовує при видаленні картки.
 * Оновлює лічильник totalCardCount у відповідній колоді та її батьках.
 */
exports.onCardDeleted = functions
  .region("europe-west1") // !! ВАЖЛИВО: Вкажіть ваш регіон !!
  .firestore.document("flashcards/{cardId}")
  .onDelete(async snapshot => {
    const cardData = snapshot.data();
    // Дані можуть бути відсутні, якщо документ вже видалено певним чином
    if (!cardData) {
      functions.logger.warn(
        `Card data for ${snapshot.id} was undefined or missing on delete. ` +
        `This might happen if the document was already gone or had no data.`,
      );
      // Якщо deckId був частиною шляху або можна отримати інакше,
      // можна спробувати продовжити, але це залежить від логіки.
      // В даному випадку, якщо немає cardData, то немає і deckId.
      return null;
    }
    const deckId = cardData.deckId;

    if (deckId) {
      const batch = db.batch();
      await updateAncestorDeckCounts(deckId, -1, batch);
      try {
        await batch.commit();
        functions.logger.log(
          `Successfully updated counts for card deletion in deck ${deckId}`,
        );
      } catch (error) {
        functions.logger.error(
          `Error committing batch for card deletion in deck ${deckId}.`,
          error, // Додав помилку до логування
        );
      }
    } else {
      // Цей лог може бути корисним, якщо картка видаляється без deckId
      functions.logger.warn(
        `Card ${snapshot.id} (was) deleted, but its data did not contain a deckId.`,
      );
    }
    return null;
  });

// Переконайтеся, що файл закінчується новим рядком
