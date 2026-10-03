using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAwardedXpToEvent : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AwardedXp",
                table: "Events",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            // Backfill events completed before this column existed. What they actually granted was
            // 10 + (streak - 1) * 2, and the streak at that moment is not recoverable, so use the
            // base 10. Under-refunding is the safe direction: the bug being fixed here was
            // over-refunding, which drove TotalXP down over time.
            migrationBuilder.Sql(@"UPDATE ""Events"" SET ""AwardedXp"" = 10 WHERE ""IsCompleted"" = true;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AwardedXp",
                table: "Events");
        }
    }
}
