using System.Linq;
using FluentAssertions;
using HabitTracker.Infrastructure.Data;
using Infrastructure.Migrations;
using Microsoft.EntityFrameworkCore.Migrations.Operations;
using Xunit;

namespace HabitTracker.Application.Tests.Infrastructure
{
    /// <summary>
    /// The index name lives twice: as a literal in the migration (a migration must not change
    /// when code does) and as the const the repository matches the unique violation by. If the
    /// two ever drift, every concurrent split-off becomes a 500 again and nothing else fails.
    /// </summary>
    public class OneEventPerSeriesDayIndexTests
    {
        private static string Sql(bool up)
        {
            var migration = new AddOneEventPerSeriesDayIndex();
            var operations = up ? migration.UpOperations : migration.DownOperations;
            return string.Join("\n", operations.OfType<SqlOperation>().Select(o => o.Sql));
        }

        [Fact]
        public void TheMigrationCreatesTheIndexTheRepositoryCatchesByName()
        {
            Sql(up: true).Should().Contain($"CREATE UNIQUE INDEX \"{ApplicationDbContext.OneEventPerSeriesDayIndex}\"");
        }

        [Fact]
        public void DownDropsTheSameIndex()
        {
            Sql(up: false).Should().Contain(ApplicationDbContext.OneEventPerSeriesDayIndex);
        }

        [Fact]
        public void TheIndexIsPartialAndPerMinuteInUtc()
        {
            // AT TIME ZONE 'UTC' is what makes the expression immutable, which Postgres requires
            // of an index, and the minute is the precision the server and client match a day at.
            var sql = Sql(up: true);

            sql.Should().Contain("date_trunc('minute', \"ExceptionDate\" AT TIME ZONE 'UTC')");
            sql.Should().Contain("WHERE \"ParentEventId\" IS NOT NULL");
        }
    }
}
