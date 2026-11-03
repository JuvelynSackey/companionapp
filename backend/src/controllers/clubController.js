import { query } from '../config/db.js';

/** GET /api/clubs - every club, flagged with whether the caller has joined. */
export async function listClubs(req, res, next) {
  try {
    const { rows } = await query(
      `SELECT c.club_id, c.name, c.description,
              COUNT(m.user_id) AS member_count,
              COALESCE(BOOL_OR(m.user_id = $1), false) AS is_member
         FROM clubs c
         LEFT JOIN club_memberships m ON m.club_id = c.club_id
        GROUP BY c.club_id
        ORDER BY c.name`,
      // A guest (optionalAuth, no token) matches no membership rows.
      [req.user?.userId ?? null]
    );

    return res.json({
      clubs: rows.map((row) => ({
        clubId: row.club_id,
        name: row.name,
        description: row.description,
        memberCount: Number(row.member_count),
        isMember: row.is_member,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

/** POST /api/clubs/:id/join */
export async function joinClub(req, res, next) {
  try {
    const { rowCount } = await query(
      `INSERT INTO club_memberships (user_id, club_id)
       VALUES ($1, $2)
       ON CONFLICT (user_id, club_id) DO NOTHING`,
      [req.user.userId, req.params.id]
    );

    return res.status(201).json({ joined: true, alreadyMember: rowCount === 0 });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(404).json({ error: 'Club not found' });
    }
    return next(err);
  }
}

/** DELETE /api/clubs/:id/join */
export async function leaveClub(req, res, next) {
  try {
    const { rowCount } = await query(
      'DELETE FROM club_memberships WHERE user_id = $1 AND club_id = $2',
      [req.user.userId, req.params.id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ error: 'You are not a member of that club' });
    }

    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}
