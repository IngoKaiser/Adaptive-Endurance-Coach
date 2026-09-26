# Activity Data Flow

## Canonical topology

Strava is the single upstream **activity aggregator**. Intervals.icu is the coach-facing **planning and analysis system of record**.

```text
Garmin Forerunner / Garmin Connect --\
                                     \
Wahoo outdoor rides -----------------> Strava ---> Intervals.icu <----> Claude Code
                                     /
MyWhoosh completed rides ------------/

Intervals.icu -- planned structured cycling workouts --> MyWhoosh --> Wahoo KICKR
```

This separation is intentional:

- **Completed activities** flow through one canonical path: `source -> Strava -> Intervals.icu`.
- **Planned workouts** are created/changed in Intervals.icu by Claude.
- **Indoor execution** happens in MyWhoosh.
- Do not add Garmin, Wahoo, Strava or MyWhoosh account passwords to this repository.
- Do not enable parallel Garmin/Wahoo/MyWhoosh activity downloads directly into Intervals.icu unless there is a specific reason and duplicate handling has been verified.

## One-time propagation check

Before relying on the topology, verify it end to end for each activity type:

1. Record a short run with the Garmin watch.
2. Confirm it appears in Strava, then in Intervals.icu with correct sport type, duration and useful HR/load data.
3. Record a short outdoor ride with the normal Wahoo workflow.
4. Confirm it appears in Strava, then in Intervals.icu with correct sport type, duration and useful power/HR/load data.
5. Complete one MyWhoosh ride.
6. Confirm it appears in Strava, then in Intervals.icu exactly once.
7. Create one planned structured cycling workout in Intervals.icu and confirm it becomes selectable in MyWhoosh.

If one activity type is missing, fix only that ingestion path. Do not create a second permanent ingestion route as a first response.

## Planning freshness gate

Before changing the training calendar, Claude must:

1. read completed Intervals.icu activities through the current day for at least the previous 7 days;
2. inspect the previous 21-28 days for load and intensity context;
3. treat running, outdoor cycling and indoor cycling as one shared endurance-load budget;
4. inspect source/external metadata when the MCP exposes it and prefer activities arriving through the Strava ingestion path;
5. never infer a rest day merely because no planned workout existed;
6. if the user mentions a newer Strava activity that is missing from Intervals.icu, treat the data as stale and do not make aggressive load-increasing changes until the sync gap is resolved.

The coach does **not** need direct Strava credentials. Intervals.icu's Strava connection is responsible for importing completed activities.

## Duplicate policy

Keep one canonical copy of each completed activity in Intervals.icu. Because Strava is the aggregator, direct activity imports from Garmin, Wahoo or MyWhoosh should normally be disabled in Intervals.icu to avoid double-counting the same workout.

## Wellness-data boundary

This topology optimizes for completed activity consolidation. Strava is not treated as a complete transport for Garmin wellness data such as daily resting HR, HRV, sleep or recovery metrics.

For the initial setup:

- current FTP and activity-derived HR data may come from Intervals.icu;
- resting HR, max HR or running threshold HR may be copied manually from Garmin when useful;
- unknown wellness values remain unknown rather than guessed;
- a future direct wellness integration is optional and separate from the completed-activity ingestion path.
