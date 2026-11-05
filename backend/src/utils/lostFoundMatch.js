/**
 * Suggests which open Lost & Found posts may be the same item: a "lost" post
 * and a "found" post whose titles share a meaningful word ("Black HP laptop
 * charger" and "Laptop charger found at JQB"). A shared place adds weight but
 * never matches on its own, since many items are lost in the same library.
 * Deliberately simple and explainable: it suggests, the people involved decide.
 */

// Words too common in posts to say anything about the item.
const STOP_WORDS = new Set([
  'the', 'and', 'for', 'with', 'from', 'near', 'this', 'that', 'its', 'one', 'some', 'any', 'has', 'have',
  'lost', 'found', 'missing', 'item', 'left', 'please', 'someone', 'anyone', 'black', 'white', 'blue', 'red',
  'green', 'brown', 'grey', 'gray', 'small', 'big', 'new', 'old', 'my', 'was', 'were', 'at', 'in', 'on',
]);

/** Lower-cased meaningful words (3+ letters, not a stop word, simple plural folded). */
export function keywords(text) {
  if (!text) return new Set();
  const words = text.toLowerCase().match(/[a-z0-9]+/g) ?? [];
  return new Set(
    words
      .filter((w) => w.length >= 3 && !STOP_WORDS.has(w))
      .map((w) => (w.length > 4 && w.endsWith('s') && !w.endsWith('ss') && !w.endsWith('es') ? w.slice(0, -1) : w))
  );
}

/**
 * How strongly two posts look like the same item: 0 means no match. Only an
 * open "lost" against an open "found" can match, and the titles must share a
 * word; each shared title word scores 2, each shared location word 1.
 */
export function matchScore(a, b) {
  if (a.kind === b.kind || a.status !== 'open' || b.status !== 'open') return 0;
  const sharedTitle = [...keywords(a.title)].filter((w) => keywords(b.title).has(w)).length;
  if (sharedTitle === 0) return 0;
  const sharedPlace = [...keywords(a.location)].filter((w) => keywords(b.location).has(w)).length;
  return sharedTitle * 2 + sharedPlace;
}

/** The posts in [others] that may match [item], best first (at most [limit]). */
export function possibleMatches(item, others, limit = 3) {
  return others
    .filter((other) => other.itemId !== item.itemId)
    .map((other) => ({ other, score: matchScore(item, other) }))
    .filter(({ score }) => score > 0)
    .sort((x, y) => y.score - x.score || x.other.itemId - y.other.itemId)
    .slice(0, limit)
    .map(({ other }) => other);
}
