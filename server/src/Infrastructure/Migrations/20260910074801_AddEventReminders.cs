using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddEventReminders : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // An empty array default is required, not cosmetic: Postgres rejects
            // ADD COLUMN ... NOT NULL without one on a table that already has rows, and
            // "no reminders" is the correct value for every pre-existing event.
            migrationBuilder.AddColumn<List<int>>(
                name: "ReminderMinutesBefore",
                table: "Events",
                type: "integer[]",
                nullable: false,
                defaultValueSql: "'{}'::integer[]");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReminderMinutesBefore",
                table: "Events");
        }
    }
}
