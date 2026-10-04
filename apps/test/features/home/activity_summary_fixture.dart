/// The exact shape `GET /analytics/summary` returned when checked against a real
/// database: yesterday 3 scheduled / 2 completed / 75 focus minutes, today 1 / 1 / 20.
Map<String, dynamic> serverResponse() => {
      'days': [
        {
          'date': '2026-09-08T00:00:00Z',
          'oneOffScheduled': 0,
          'oneOffCompleted': 0,
          'focusMinutes': 0,
        },
        {
          'date': '2026-09-09T00:00:00Z',
          'oneOffScheduled': 3,
          'oneOffCompleted': 2,
          'focusMinutes': 75,
        },
        {
          'date': '2026-09-10T00:00:00Z',
          'oneOffScheduled': 1,
          'oneOffCompleted': 1,
          'focusMinutes': 20,
        },
      ],
      'totalOneOffScheduled': 4,
      'totalOneOffCompleted': 3,
      'totalFocusMinutes': 95,
      'bestFocusMinutes': 75,
    };
