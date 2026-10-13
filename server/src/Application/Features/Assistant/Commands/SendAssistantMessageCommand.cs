using HabitTracker.Application.Features.Assistant.Harness;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Commands
{
    /// <summary>One user message to the assistant, answered in the same request.</summary>
    public record SendAssistantMessageCommand(string UserId, Guid ConversationId, string Text)
        : IRequest<AssistantTurnResult>;

    public class SendAssistantMessageCommandHandler : IRequestHandler<SendAssistantMessageCommand, AssistantTurnResult>
    {
        /// <summary>Long enough for a real request, short enough that nobody pastes a document in.</summary>
        public const int MaxTextLength = 2000;

        private readonly AssistantHarness _harness;

        public SendAssistantMessageCommandHandler(AssistantHarness harness)
        {
            _harness = harness;
        }

        public Task<AssistantTurnResult> Handle(SendAssistantMessageCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Text) || request.Text.Length > MaxTextLength)
            {
                throw new ArgumentException($"Text is required and at most {MaxTextLength} characters.", nameof(request));
            }

            return _harness.RunTurnAsync(request.UserId, request.ConversationId, request.Text.Trim(), cancellationToken);
        }
    }
}
