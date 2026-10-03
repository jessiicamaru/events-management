using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace HabitTracker.Infrastructure.Data
{
    /// <inheritdoc cref="IUnitOfWork" />
    public class UnitOfWork : IUnitOfWork
    {
        private readonly ApplicationDbContext _context;

        public UnitOfWork(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<T> ExecuteInTransactionAsync<T>(
            Func<Task<T>> operation,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(operation);

            // A transaction may already be open (e.g. nested handlers). Joining it is correct:
            // the outermost caller stays responsible for committing.
            if (_context.Database.CurrentTransaction is not null)
            {
                return await operation();
            }

            await using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);

            try
            {
                var result = await operation();
                await transaction.CommitAsync(cancellationToken);
                return result;
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }
    }
}
