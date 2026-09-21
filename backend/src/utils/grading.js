/**
 * Grade points for the University of Ghana undergraduate scale. The letters
 * themselves come from the generated grades.letter_grade column in
 * db/schema.sql, so this must list every letter that column can produce. The
 * whole table is also in docs/grading-scale-ug.json, which the tests check
 * this file, schema.sql, the migration and the app's engine against — change
 * them together.
 *
 * No database or config imports on purpose, so it can be unit-tested alone.
 */
export const GRADE_POINTS = {
  A: 4.0,
  'B+': 3.5,
  B: 3.0,
  'C+': 2.5,
  C: 2.0,
  'D+': 1.5,
  D: 1.0,
  E: 0.5,
  F: 0.0,
};

/** F (below 45) is the only failing grade. */
export const FAILING_LETTER = 'F';

/**
 * Cumulative GPA = sum(grade point x credit hours) / sum(credit hours) — a
 * 3-credit course moves the average more than a 2-credit one. Returns null
 * when there is nothing to average.
 *
 * `rows` need `letter_grade` and `credit_hours`. An unknown letter is an
 * error, not something to skip: silently dropping a grade would report a
 * wrong GPA, and it can only happen if schema.sql and GRADE_POINTS have
 * drifted apart.
 */
export function calculateGpa(rows) {
  let points = 0;
  let credits = 0;

  for (const row of rows) {
    const gradePoint = GRADE_POINTS[row.letter_grade];
    if (gradePoint === undefined) {
      throw new Error(`No grade point defined for letter grade "${row.letter_grade}"`);
    }
    points += gradePoint * row.credit_hours;
    credits += row.credit_hours;
  }

  if (credits === 0) return null;
  return Number((points / credits).toFixed(2));
}
