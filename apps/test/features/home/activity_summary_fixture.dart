/// The exact shape `GET /analytics/summary` returned when checked against a real
/// database: yesterday 3 scheduled / 2 completed / 75 focus minutes, today 1 / 1 / 20.
Map<String, dynamic> serverResponse() => {
      'days': [
        {
          'date': '2026-09-08T00:00:00Z',
          'scheduled': 0,
          'completed': 0,
          'focusMinutes': 0,
        },
        {
          'date': '2026-09-09T00:00:00Z',
          'scheduled': 3,
          'completed': 2,
          'focusMinutes': 75,
        },
        {
          'date': '2026-09-10T00:00:00Z',
          'scheduled': 1,
          'completed': 1,
          'focusMinutes': 20,
        },
      ],
      'totalScheduled': 4,
      'totalCompleted': 3,
      'totalFocusMinutes': 95,
      'bestFocusMinutes': 75,
    };
