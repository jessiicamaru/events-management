using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;

namespace HabitTracker.Application.Tests.TestDoubles
{
    /// <summary>
    /// Runs the operation directly, with no transaction. Handler unit tests use mocked
    /// repositories, so there is no database to enlist — this keeps the tests focused on the
    /// handler's logic. Transaction behaviour itself belongs to an integration test.
    /// </summary>
    public class PassThroughUnitOfWork : IUnitOfWork
    {
        public Task<T> ExecuteInTransactionAsync<T>(
            Func<Task<T>> operation,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(operation);

            return operation();
        }
    }
}
