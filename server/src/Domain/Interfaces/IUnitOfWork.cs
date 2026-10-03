using System;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Domain.Interfaces
{
    /// <summary>
    /// Groups several repository writes into a single database transaction.
    /// Repositories save on every call, so a handler that writes more than one entity
    /// must wrap the whole operation here — otherwise a failure part-way through leaves
    /// the earlier writes committed (e.g. XP granted but the event never marked complete).
    /// </summary>
    public interface IUnitOfWork
    {
        Task<T> ExecuteInTransactionAsync<T>(
            Func<Task<T>> operation,
            CancellationToken cancellationToken = default);
    }
}
