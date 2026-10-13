using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Queries
{
    public sealed record AiSettingsDto(bool AssistantEnabled, bool AlwaysConfirm, DateTime? ConsentedAt, bool ServerConfigured)
    {
        public static AiSettingsDto From(UserAiSettings? settings, bool serverConfigured = true) => new(
            settings?.AssistantEnabled ?? false,
            settings?.AlwaysConfirm ?? false,
            settings?.ConsentedAt,
            serverConfigured);
    }

    /// <summary>
    /// A message as the app shows it. Tool steps are listed by name only; their raw results
    /// are for the model.
    /// </summary>
    public sealed record AssistantMessageDto(Guid Id, string Role, string? Content, string? ToolName, DateTime CreatedAt);

    public sealed record AssistantConversationDto(Guid Id, DateTime CreatedAt, DateTime UpdatedAt);

    public record GetAiSettingsQuery(string UserId) : IRequest<AiSettingsDto>;

    public class GetAiSettingsQueryHandler : IRequestHandler<GetAiSettingsQuery, AiSettingsDto>
    {
        private readonly IAssistantRepository _repository;
        private readonly AssistantOptions _options;

        public GetAiSettingsQueryHandler(IAssistantRepository repository, AssistantOptions options)
        {
            _repository = repository;
            _options = options;
        }

        public async Task<AiSettingsDto> Handle(GetAiSettingsQuery request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId)) throw new ArgumentException("UserId is required.", nameof(request));

            return AiSettingsDto.From(await _repository.GetSettingsAsync(request.UserId), _options.IsConfigured);
        }
    }

    public record GetAssistantConversationsQuery(string UserId) : IRequest<IReadOnlyList<AssistantConversationDto>>;

    public class GetAssistantConversationsQueryHandler
        : IRequestHandler<GetAssistantConversationsQuery, IReadOnlyList<AssistantConversationDto>>
    {
        public const int Limit = 20;

        private readonly IAssistantRepository _repository;

        public GetAssistantConversationsQueryHandler(IAssistantRepository repository)
        {
            _repository = repository;
        }

        public async Task<IReadOnlyList<AssistantConversationDto>> Handle(
            GetAssistantConversationsQuery request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId)) throw new ArgumentException("UserId is required.", nameof(request));

            var conversations = await _repository.GetConversationsAsync(request.UserId, Limit);
            return conversations.Select(c => new AssistantConversationDto(c.Id, c.CreatedAt, c.UpdatedAt)).ToList();
        }
    }

    /// <summary>A conversation's messages; null when it is not the caller's.</summary>
    public record GetAssistantMessagesQuery(string UserId, Guid ConversationId)
        : IRequest<IReadOnlyList<AssistantMessageDto>?>;

    public class GetAssistantMessagesQueryHandler
        : IRequestHandler<GetAssistantMessagesQuery, IReadOnlyList<AssistantMessageDto>?>
    {
        private readonly IAssistantRepository _repository;

        public GetAssistantMessagesQueryHandler(IAssistantRepository repository)
        {
            _repository = repository;
        }

        public async Task<IReadOnlyList<AssistantMessageDto>?> Handle(
            GetAssistantMessagesQuery request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId)) throw new ArgumentException("UserId is required.", nameof(request));

            if (await _repository.GetConversationAsync(request.ConversationId, request.UserId) == null) return null;

            var messages = await _repository.GetMessagesAsync(request.ConversationId);
            return messages
                // An assistant message that only called tools has nothing to show; its tool steps do.
                .Where(m => m.Role != AssistantRoles.Assistant || !string.IsNullOrWhiteSpace(m.Content))
                .Select(m => new AssistantMessageDto(
                    m.Id,
                    m.Role,
                    m.Role == AssistantRoles.Tool ? null : m.Content,
                    m.ToolName,
                    m.CreatedAt))
                .ToList();
        }
    }
}
