using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddEventRecurrence : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ExceptionDate",
                table: "Events",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ParentEventId",
                table: "Events",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RecurrenceExceptionDates",
                table: "Events",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RecurrenceRule",
                table: "Events",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Events_ParentEventId",
                table: "Events",
                column: "ParentEventId");

            migrationBuilder.AddForeignKey(
                name: "FK_Events_Events_ParentEventId",
                table: "Events",
                column: "ParentEventId",
                principalTable: "Events",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Events_Events_ParentEventId",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Events_ParentEventId",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "ExceptionDate",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "ParentEventId",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "RecurrenceExceptionDates",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "RecurrenceRule",
                table: "Events");
        }
    }
}
