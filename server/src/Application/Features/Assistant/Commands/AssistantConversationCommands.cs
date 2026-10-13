using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Commands
{
    /// <summary>Starts an empty conversation for the user.</summary>
    public record CreateAssistantConversationCommand(string UserId) : IRequest<Guid>;

    public class CreateAssistantConversationCommandHandler : IRequestHandler<CreateAssistantConversationCommand, Guid>
    {
        private readonly IAssistantRepository _repository;

        public CreateAssistantConversationCommandHandler(IAssistantRepository repository)
        {
            _repository = repository;
        }

        public async Task<Guid> Handle(CreateAssistantConversationCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId)) throw new ArgumentException("UserId is required.", nameof(request));

            var conversation = await _repository.CreateConversationAsync(request.UserId);
            return conversation.Id;
        }
    }
}
