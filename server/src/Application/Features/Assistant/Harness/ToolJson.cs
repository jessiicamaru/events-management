using System.Globalization;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace HabitTracker.Application.Features.Assistant.Harness
{
    /// <summary>How tools read their arguments and write their results.</summary>
    public static class ToolJson
    {
        /// <summary>camelCase, nulls left out, and Vietnamese kept readable rather than \u-escaped.</summary>
        public static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web)
        {
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
            Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
        };

        /// <summary>An instant as the model sees it: local time with its offset, to the minute.</summary>
        public static string Local(DateTime utc, TimeSpan offset) =>
            new DateTimeOffset(DateTime.SpecifyKind(utc, DateTimeKind.Utc)).ToOffset(offset)
                .ToString("yyyy-MM-dd'T'HH:mmzzz", CultureInfo.InvariantCulture);

        /// <summary>
        /// Reads a required ISO 8601 instant. A value without an offset is taken as local time,
        /// which is what a person means by "06:00".
        /// </summary>
        public static bool TryGetInstant(JsonElement arguments, string name, TimeSpan offset, out DateTime utc, out string? error)
        {
            utc = default;
            error = null;

            if (!arguments.TryGetProperty(name, out var value) || value.ValueKind != JsonValueKind.String)
            {
                error = $"'{name}' is required: an ISO 8601 date-time such as 2026-10-05T06:00+07:00.";
                return false;
            }

            var text = value.GetString()!;
            if (DateTimeOffset.TryParse(text, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed)
                && HasExplicitOffset(text))
            {
                utc = parsed.UtcDateTime;
                return true;
            }

            if (DateTime.TryParse(text, CultureInfo.InvariantCulture, DateTimeStyles.None, out var local))
            {
                utc = DateTime.SpecifyKind(local - offset, DateTimeKind.Utc);
                return true;
            }

            error = $"'{name}' is not a date-time: '{text}'. Use ISO 8601, e.g. 2026-10-05T06:00+07:00.";
            return false;
        }

        public static bool TryGetInt(JsonElement arguments, string name, int min, int max, int fallback, out int result, out string? error)
        {
            result = fallback;
            error = null;

            if (!arguments.TryGetProperty(name, out var value) || value.ValueKind == JsonValueKind.Null) return true;

            if (value.ValueKind != JsonValueKind.Number || !value.TryGetInt32(out result) || result < min || result > max)
            {
                error = $"'{name}' must be a whole number from {min} to {max}.";
                return false;
            }

            return true;
        }

        private static bool HasExplicitOffset(string text)
        {
            var timePart = text.Contains('T') ? text[(text.IndexOf('T') + 1)..] : string.Empty;
            return text.EndsWith('Z') || text.EndsWith('z') || timePart.Contains('+') || timePart.Contains('-');
        }
    }
}
