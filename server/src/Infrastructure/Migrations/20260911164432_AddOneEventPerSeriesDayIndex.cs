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
            // every edit of the same day. Keep one per day, preferring the one carrying state
            // — known to Google, completed, with focus time — and otherwise the newest, which
            // is the user's last edit. Their task copies go with them (ON DELETE CASCADE).
            // Not reversible: Down drops the index but cannot bring these rows back.
            migrationBuilder.Sql("""
                DELETE FROM "Events" e
                USING (
                    SELECT "Id", row_number() OVER (
                        PARTITION BY "ParentEventId", date_trunc('minute', "ExceptionDate" AT TIME ZONE 'UTC')
                        ORDER BY ("GoogleEventId" IS NOT NULL) DESC,
                                 "IsCompleted" DESC,
                                 ("ActualDuration" IS NOT NULL) DESC,
                                 "CreatedAt" DESC,
                                 "Id") AS rank
                    FROM "Events"
                    WHERE "ParentEventId" IS NOT NULL AND "ExceptionDate" IS NOT NULL
                ) ranked
                WHERE e."Id" = ranked."Id" AND ranked.rank > 1;
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
