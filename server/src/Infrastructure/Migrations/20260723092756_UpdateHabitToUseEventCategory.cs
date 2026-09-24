using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateHabitToUseEventCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Category",
                table: "Habits");

            migrationBuilder.AddColumn<Guid>(
                name: "CategoryId",
                table: "Habits",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Habits_CategoryId",
                table: "Habits",
                column: "CategoryId");

            migrationBuilder.AddForeignKey(
                name: "FK_Habits_EventCategories_CategoryId",
                table: "Habits",
                column: "CategoryId",
                principalTable: "EventCategories",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Habits_EventCategories_CategoryId",
                table: "Habits");

            migrationBuilder.DropIndex(
                name: "IX_Habits_CategoryId",
                table: "Habits");

            migrationBuilder.DropColumn(
                name: "CategoryId",
                table: "Habits");

            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "Habits",
                type: "text",
                nullable: false,
                defaultValue: "");
        }
    }
}
