# Coaching Rules

## Source of truth

- Intervals.icu is the coach-facing source of truth for the training calendar, completed activities, sport settings, fitness load and structured workouts.
- Claude reads/writes Intervals.icu only; Strava is the canonical upstream activity aggregator. Do not add Garmin, Strava, Wahoo, MyWhoosh or other platform credentials to the project.
- MyWhoosh is only the indoor workout execution platform.
- Running and outdoor cycling are first-class training load, not side activities to ignore.
- Before schedule-specific advice, inspect completed Intervals.icu activities through today for at least the last 7 days and use 21-28 days for load context.
- Never infer a rest day solely from the absence of a planned workout.
- If recent activity history is unexpectedly empty or stale, flag a possible upstream -> Intervals.icu sync gap before increasing load.
- Load `training/profile.local.yaml` when present. Otherwise use `training/profile.example.yaml` only as a schema/template and do not infer missing personal values.

## Multisport load rules

- Count hard running sessions, hard outdoor rides and hard indoor rides toward the same weekly high-intensity budget.
- Default maximum: two hard endurance sessions per week unless the athlete explicitly requests a different structure and recent load supports it.
- Avoid consecutive hard days by default, even when the sports differ.
- A hard run can replace the intended physiological stimulus of a hard bike day; do not automatically preserve both.
- Easy running or easy cycling can be used as aerobic volume when it matches the intended stimulus and recovery state.
- Do not use cycling FTP zones for running.

## Cycling progression

- Prefer increasing interval duration/volume before increasing intensity.
- Use progressive loading with regular recovery weeks as a default framework, not a rigid law.
- Use %FTP for structured bike power targets so workouts remain valid after an FTP update.
- Include adequate warm-up and cool-down.
- Never change FTP or sport zones in Intervals.icu without explicit user approval.

## Running progression

- Protect against sudden increases in running volume or intensity, especially if cycling volume is already high.
- Use recent running history before scheduling intervals or long runs.
- Prefer a conservative progression when the available running baseline is incomplete.
- Treat pain or injury concerns as a reason to stop progression and seek appropriate professional assessment rather than to optimize around symptoms.

## Recovery and wellness

Use available information such as completed load, HR/HRV trends, sleep, RPE, soreness and illness as context. Do not diagnose medical conditions from wearable data. Do not invent resting HR, max HR, threshold HR, VO2max, HRV or recovery values.

## Calendar write behavior

A clear instruction to plan, schedule, move, replace or adapt future training authorizes the corresponding Intervals.icu calendar writes. Analysis-only questions do not.

Safety boundaries:

- Never delete completed activities.
- Never edit historical activity data or athlete settings without an explicit request for that exact change.
- Keep `INTERVALS_ICU_DELETE_MODE=safe`.
- Avoid destructive bulk changes. For changes beyond roughly two future weeks, summarize the proposal before replacing a large existing plan.

## MyWhoosh compatibility

Cycling sessions intended for MyWhoosh must be real structured cycling workouts/events in Intervals.icu with conventional power-based steps, not only free-text notes. Do not claim a sync succeeded unless it can actually be verified.

## Activity ingestion

- Prefer one canonical ingestion path per activity so training load is not double-counted.
- Completed activities should normally follow one canonical path: Garmin/Wahoo/MyWhoosh -> Strava -> Intervals.icu.
- Run the one-time propagation checks in `docs/data-flow.md` for running, outdoor cycling and MyWhoosh indoor cycling.
- Do not add a direct Garmin/Wahoo/MyWhoosh completed-activity import into Intervals.icu unless there is a specific reason and duplicate handling has been verified.
- If parallel sync routes create duplicates, disable or filter one route before using load metrics for adaptation.
