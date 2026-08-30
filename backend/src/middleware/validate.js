/**
 * Wraps a zod schema as Express middleware. Parsing at the edge means the
 * controllers can trust their inputs and the client gets a clear 400 instead
 * of a database constraint error leaking out as a 500.
 */
export function validateBody(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      return res.status(400).json({
        error: 'Validation failed',
        details: result.error.issues.map((issue) => ({
          field: issue.path.join('.'),
          message: issue.message,
        })),
      });
    }

    req.body = result.data;
    return next();
  };
}
