using HabitTracker.Application.Features.Assistant.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Commands
{
    /// <summary>Turns the assistant on or off for the user, and sets whether it always asks first.</summary>
    public record UpdateAiSettingsCommand(string UserId, bool AssistantEnabled, bool AlwaysConfirm)
        : IRequest<AiSettingsDto>;

    public class UpdateAiSettingsCommandHandler : IRequestHandler<UpdateAiSettingsCommand, AiSettingsDto>
    {
        private readonly IAssistantRepository _repository;
        private readonly TimeProvider _clock;

        public UpdateAiSettingsCommandHandler(IAssistantRepository repository, TimeProvider clock)
        {
            _repository = repository;
            _clock = clock;
        }

        public async Task<AiSettingsDto> Handle(UpdateAiSettingsCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId)) throw new ArgumentException("UserId is required.", nameof(request));

            var now = _clock.GetUtcNow().UtcDateTime;
            var settings = await _repository.GetSettingsAsync(request.UserId)
                ?? new UserAiSettings { UserId = request.UserId };

            settings.AssistantEnabled = request.AssistantEnabled;
            settings.AlwaysConfirm = request.AlwaysConfirm;
            settings.UpdatedAt = now;
            // The first time it is turned on is the consent; turning it off and on again keeps that date.
            if (request.AssistantEnabled && settings.ConsentedAt == null) settings.ConsentedAt = now;

            await _repository.SaveSettingsAsync(settings);
            return AiSettingsDto.From(settings);
        }
    }
}
