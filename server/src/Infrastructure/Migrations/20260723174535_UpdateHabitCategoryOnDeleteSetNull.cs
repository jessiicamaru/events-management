using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateHabitCategoryOnDeleteSetNull : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Habits_EventCategories_CategoryId",
                table: "Habits");

            migrationBuilder.AddForeignKey(
                name: "FK_Habits_EventCategories_CategoryId",
                table: "Habits",
                column: "CategoryId",
                principalTable: "EventCategories",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Habits_EventCategories_CategoryId",
                table: "Habits");

            migrationBuilder.AddForeignKey(
                name: "FK_Habits_EventCategories_CategoryId",
                table: "Habits",
                column: "CategoryId",
                principalTable: "EventCategories",
                principalColumn: "Id");
        }
    }
}
