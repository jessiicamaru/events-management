/// The plan-vs-actual payload, copied from a real response of the running server.
///
/// Beside `activity_summary_fixture.dart` rather than inside a test file: a test file that
/// others import becomes a fixture library, and then running one test registers another
/// test's `main()`.
Map<String, dynamic> planVsActualResponse() => {
      'byHabit': [
        {
          'id': 'b7959df8-82fa-4a88-a042-03f4b84ee790',
          'name': 'Running',
          'sessions': 1,
          'plannedMinutes': 60,
          'actualMinutes': 65,
        },
        {
          'id': '32118aec-8323-44cd-85ce-a07a29249f6b',
          'name': 'Reading',
          'sessions': 3,
          'plannedMinutes': 90,
          'actualMinutes': 54,
        },
      ],
      'byCategory': [
        {
          'id': '73a7dea1-855c-4429-b154-f755ceaa7fcd',
          'name': 'Study',
          'sessions': 3,
          'plannedMinutes': 90,
          'actualMinutes': 54,
        },
      ],
      'totalSessions': 4,
      'totalPlannedMinutes': 150,
      'totalActualMinutes': 119,
    };

/// What the server returns for a user whose finished sessions are all on plain calendar
/// events: real totals, and nothing the habit grouping can show. Measured on the dev
/// database — 15 sessions, 790 minutes, no habit on any of them.
Map<String, dynamic> sessionsWithNoHabitResponse() => {
      'byHabit': <Map<String, dynamic>>[],
      'byCategory': <Map<String, dynamic>>[],
      'totalSessions': 15,
      'totalPlannedMinutes': 900,
      'totalActualMinutes': 790,
    };
