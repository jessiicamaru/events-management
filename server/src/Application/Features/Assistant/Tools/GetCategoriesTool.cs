using System.Text.Json;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Application.Features.EventCategories.Queries;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Tools
{
    /// <summary>The user's own event categories.</summary>
    public class GetCategoriesTool : IAssistantTool
    {
        private readonly ISender _sender;

        public GetCategoriesTool(ISender sender)
        {
            _sender = sender;
        }

        public string Name => "get_categories";

        public string Description => "List the user's event categories: id, name and colour.";

        public string ParametersSchemaJson => """
            { "type": "object", "properties": {}, "additionalProperties": false }
            """;

        public async Task<ToolResult> ExecuteAsync(ToolContext context, JsonElement arguments, CancellationToken cancellationToken)
        {
            // Own categories only: no squad id, so the query's squad-membership rule never comes into play.
            var categories = await _sender.Send(new GetEventCategoriesQuery { UserId = context.UserId }, cancellationToken)
                ?? Enumerable.Empty<Domain.Entities.EventCategory>();

            return ToolResult.Ok(new
            {
                categories = categories.Select(c => new { id = c.Id, name = c.Name, colour = c.ColorPreset }),
            });
        }
    }
}
