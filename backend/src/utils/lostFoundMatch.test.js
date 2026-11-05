/**
 * Offline unit tests for Lost & Found matching:  npm test
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { keywords, matchScore, possibleMatches } from './lostFoundMatch.js';

const post = (itemId, kind, title, location = null, status = 'open') => ({ itemId, kind, title, location, status });

test('keywords drop short and common words, case and simple plurals', () => {
  assert.deepEqual([...keywords('Lost my BLACK HP Laptop Chargers at the JQB')], ['laptop', 'charger', 'jqb']);
  assert.deepEqual([...keywords('Glasses')], ['glasses']);
  assert.deepEqual([...keywords(null)], []);
});

test('a lost post and a found post sharing a title word match; a shared place adds weight', () => {
  const lost = post(1, 'lost', 'Black HP laptop charger', 'Balme Library');
  assert.equal(matchScore(lost, post(2, 'found', 'Laptop charger', 'Balme Library')), 2 * 2 + 2);
  assert.equal(matchScore(lost, post(3, 'found', 'Charger found')), 2);
});

test('no match for the same kind, a closed post, or only a shared place or colour', () => {
  const lost = post(1, 'lost', 'Black water bottle', 'Balme Library');
  assert.equal(matchScore(lost, post(2, 'lost', 'Water bottle')), 0);
  assert.equal(matchScore(lost, post(3, 'found', 'Water bottle', null, 'returned')), 0);
  assert.equal(matchScore(lost, post(4, 'found', 'Calculator', 'Balme Library')), 0);
  assert.equal(matchScore(lost, post(5, 'found', 'Black umbrella')), 0);
});

test('possibleMatches ranks the best first, skips the item itself, and caps the list', () => {
  const lost = post(1, 'lost', 'Student ID card', 'Commonwealth Hall');
  const others = [
    lost,
    post(2, 'found', 'ID card'),
    post(3, 'found', 'Student ID card', 'Commonwealth Hall'),
    post(4, 'found', 'Card holder'),
    post(5, 'found', 'Card'),
    post(6, 'found', 'Umbrella'),
  ];
  assert.deepEqual(possibleMatches(lost, others).map((m) => m.itemId), [3, 2, 4]);
});
