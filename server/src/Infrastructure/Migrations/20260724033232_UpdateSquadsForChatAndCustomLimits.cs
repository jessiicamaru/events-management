using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateSquadsForChatAndCustomLimits : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "IsBuddyMode",
                table: "Squads",
                newName: "RequireApproval");

            migrationBuilder.AddColumn<int>(
                name: "MaxMembers",
                table: "Squads",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "IsApproved",
                table: "SquadMembers",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsMuted",
                table: "SquadMembers",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Nickname",
                table: "SquadMembers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "XpContributionEnabled",
                table: "SquadMembers",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "SquadChatMessages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SquadId = table.Column<Guid>(type: "uuid", nullable: false),
                    SenderUserId = table.Column<string>(type: "text", nullable: true),
                    Message = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    SentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsSystemMessage = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SquadChatMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SquadChatMessages_AspNetUsers_SenderUserId",
                        column: x => x.SenderUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SquadChatMessages_Squads_SquadId",
                        column: x => x.SquadId,
                        principalTable: "Squads",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SquadChatMessages_SenderUserId",
                table: "SquadChatMessages",
                column: "SenderUserId");

            migrationBuilder.CreateIndex(
                name: "IX_SquadChatMessages_SquadId",
                table: "SquadChatMessages",
                column: "SquadId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SquadChatMessages");

            migrationBuilder.DropColumn(
                name: "MaxMembers",
                table: "Squads");

            migrationBuilder.DropColumn(
                name: "IsApproved",
                table: "SquadMembers");

            migrationBuilder.DropColumn(
                name: "IsMuted",
                table: "SquadMembers");

            migrationBuilder.DropColumn(
                name: "Nickname",
                table: "SquadMembers");

            migrationBuilder.DropColumn(
                name: "XpContributionEnabled",
                table: "SquadMembers");

            migrationBuilder.RenameColumn(
                name: "RequireApproval",
                table: "Squads",
                newName: "IsBuddyMode");
        }
    }
}
