using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Events.Commands
{
    public record MaterializeOccurrenceRequest(DateTime OccurrenceStart);

    /// <summary>
    /// Splits one day off a repeating series, so it can hold its own tasks and completion.
    /// See <see cref="OccurrenceMaterializer"/>.
    /// </summary>
    /// <returns>The id of the event now standing for that day, or null if there is none.</returns>
    public record MaterializeOccurrenceCommand(Guid SeriesId, DateTime OccurrenceStart, string UserId)
        : IRequest<Guid?>;

    public class MaterializeOccurrenceCommandHandler : IRequestHandler<MaterializeOccurrenceCommand, Guid?>
    {
        private readonly IEventRepository _eventRepository;
        private readonly OccurrenceMaterializer _materializer;

        public MaterializeOccurrenceCommandHandler(
            IEventRepository eventRepository,
            OccurrenceMaterializer materializer)
        {
            _eventRepository = eventRepository;
            _materializer = materializer;
        }

        public async Task<Guid?> Handle(MaterializeOccurrenceCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId))
            {
                throw new ArgumentException("UserId is required.", nameof(request));
            }

            var series = await _eventRepository.GetByIdAsync(request.SeriesId);
            if (series == null || series.UserId != request.UserId) return null;

            var child = await _materializer.FindOrCreateAsync(series, request.OccurrenceStart, cancellationToken);
            return child?.Id;
        }
    }
}
