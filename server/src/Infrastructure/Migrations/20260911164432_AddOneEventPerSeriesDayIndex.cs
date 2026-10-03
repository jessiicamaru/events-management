using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <summary>
    /// One event per day of a series: a unique index on the series and the minute of
    /// <c>ExceptionDate</c>, the precision the app matches a split-off day at.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Splitting a day off is a lookup followed by an insert, so two requests for the same day
    /// (two devices, or a ticked task racing a finished session) could both insert. The client
    /// then shows the day twice. With the index the second insert fails, and
    /// <c>EventRepository.TryAddOccurrenceDayAsync</c> hands back the first one instead.
    /// </para>
    /// <para>
    /// An expression index, so it is written as SQL and EF's model does not know it — the
    /// snapshot is unchanged. The name is <c>ApplicationDbContext.OneEventPerSeriesDayIndex</c>,
    /// repeated here as a literal because a migration must not change when code does.
    /// <c>AT TIME ZONE 'UTC'</c> is what makes the expression immutable, which Postgres requires
    /// of an index: <c>date_trunc</c> on a <c>timestamptz</c> depends on the session time zone.
    /// </para>
    /// </remarks>
    public partial class AddOneEventPerSeriesDayIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Duplicates already exist: "edit this occurrence" on main added a new child on
            // every edit of the same day. Keep one per day: the one carrying the most state —
            // known to Google, completed, with focus time, with ticked tasks — and otherwise
            // the oldest, which is the one `GetOccurrenceChildAsync` has been reading and
            // writing all along (it orders by CreatedAt). The losers' task copies go with them
            // (ON DELETE CASCADE), and so do their outbox rows: `GoogleCalendarOutboxes` has no
            // foreign key to `Events`, so a pending Insert left behind would push an event to
            // Google that no longer exists here.
            // Not reversible: Down drops the index but cannot bring these rows back.
            migrationBuilder.Sql("""
                WITH ranked AS (
                    SELECT "Id", row_number() OVER (
                        PARTITION BY "ParentEventId", date_trunc('minute', "ExceptionDate" AT TIME ZONE 'UTC')
                        ORDER BY ("GoogleEventId" IS NOT NULL) DESC,
                                 "IsCompleted" DESC,
                                 ("ActualDuration" IS NOT NULL) DESC,
                                 (SELECT count(*) FROM "EventTasks" t
                                  WHERE t."EventId" = "Events"."Id" AND t."IsCompleted") DESC,
                                 "CreatedAt",
                                 "Id") AS rank
                    FROM "Events"
                    WHERE "ParentEventId" IS NOT NULL AND "ExceptionDate" IS NOT NULL
                ),
                losers AS (
                    SELECT "Id" FROM ranked WHERE rank > 1
                ),
                outbox AS (
                    DELETE FROM "GoogleCalendarOutboxes"
                    WHERE "EventId" IN (SELECT "Id" FROM losers)
                    RETURNING 1
                )
                DELETE FROM "Events" WHERE "Id" IN (SELECT "Id" FROM losers);
                """);

            migrationBuilder.Sql("""
                CREATE UNIQUE INDEX "UX_Events_ParentEventId_ExceptionMinute"
                    ON "Events" ("ParentEventId", date_trunc('minute', "ExceptionDate" AT TIME ZONE 'UTC'))
                    WHERE "ParentEventId" IS NOT NULL;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""DROP INDEX IF EXISTS "UX_Events_ParentEventId_ExceptionMinute";""");
        }
    }
}
