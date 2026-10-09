# Habit Tracker — Flutter client

The mobile client of the Habit Tracker. Setup, the backend and the full picture are in the
[repository README](../README.md); conventions and architecture are in [`CLAUDE.md`](../CLAUDE.md).

## Run

```bash
flutter pub get
flutter run            # the backend must be running on :5000 (see the root README)
```

On an Android emulator the app calls `http://10.0.2.2:5000`; elsewhere `http://localhost:5000`
(both in `lib/core/utils/app_constants.dart`). A cold restart is needed after adding a native
plugin.

## Check

```bash
flutter analyze                                             # static analysis — must be clean
flutter test                                                # unit and widget tests
flutter test integration_test/calendar_e2e_test.dart        # E2E: needs a device and a backend
dart run build_runner build --delete-conflicting-outputs    # after changing an annotated provider or model
```

CI runs `flutter analyze`, `flutter test`, and fails if generated `*.g.dart` / `*.freezed.dart` files
are out of date.

## Layout

```
lib/
  core/        cross-cutting: network (Dio, SignalR), routing (go_router), localization,
               notifications, theme, shared providers and widgets
  features/    one folder per feature, each split into domain/ and presentation/
    auth/  calendar/  focus_session/  habits/  home/  home_widget/
    pomodoro/  profile/  settings/  squads/
test/          mirrors lib/
integration_test/
```

- **State:** Riverpod 3 — hand-written providers and `riverpod_annotation`-generated ones.
- **UI:** `shadcn_ui` with `lucide_icons`.
- **Strings:** add every user-facing string to `lib/core/localization/locale_provider.dart`, in English
  and Vietnamese.
- **Imports:** package imports only (`always_use_package_imports`).
- **Widget tests** must override `apiServiceProvider` and use `commonTestOverrides` from
  `test/test_utils.dart`, or they make real HTTP calls.
