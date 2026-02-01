## [Unreleased]

## [0.2.2] - 2026-02-01

### Added

- `request_timeout=` setter in Configuration class - users can now customize timeout via `Umami.configure` block.

### Fixed

- Added missing `type` parameter documentation to `reports()` method. The API accepts `type` to filter by report type ('attribution', 'breakdown', 'funnel', 'goal', 'journey', 'retention', 'revenue', 'utm').
- Fixed `website_event_data_stats` return type documentation from `Hash` to `Array<Hash>` to match actual API response.

### Documentation

- Added Configuration Options table to README with all available options and defaults.
- Added example for configuring custom `request_timeout` in README and Configuration class docs.

## [0.2.1] - 2026-02-01

### Fixed

- **Critical**: Fixed `send_event` to use correct Umami Cloud URL (`https://cloud.umami.is/api/send`) instead of the general API URL. The send endpoint uses a different base URL for Cloud deployments.
- **Critical**: Added mandatory `User-Agent` header to `send_event` requests. The Umami API rejects requests without a valid User-Agent. Fixes [#2](https://github.com/rameerez/umami-ruby/issues/2) - thanks [@kinduff](https://github.com/kinduff) for reporting!
- `send_event` no longer sends unnecessary `Authorization` header since the `/api/send` endpoint doesn't require authentication.

### Added

- New `UMAMI_CLOUD_SEND_URL` constant in `Configuration` for the Cloud send endpoint URL.
- Optional `user_agent:` parameter to `send_event` method for custom User-Agent strings (defaults to `"umami-ruby/VERSION"`).
- Pagination support for `my_teams` method (now accepts `page` and `pageSize` parameters).

### Changed

- Improved documentation for `website_events` and `website_events_list` to clarify their different purposes:
  - `website_events`: For time-series grouped event data with unit/timezone parameters
  - `website_events_list`: For paginated list of individual events with search/filter support

## [0.2.0] - 2026-02-01

### Added

**New Endpoint Categories:**
- **Me endpoints**: `me`, `my_teams`, `my_websites` - Get current user info and resources
- **Admin endpoints**: `admin_users`, `admin_websites`, `admin_teams` - Admin-only endpoints for self-hosted
- **Sessions endpoints** (8 new methods):
  - `website_sessions` - Get sessions within a time range
  - `website_sessions_stats` - Get summarized session statistics
  - `website_sessions_weekly` - Get session counts by hour of weekday
  - `website_session` - Get individual session details
  - `website_session_activity` - Get session activity
  - `website_session_properties` - Get session properties
  - `website_session_data_properties` - Get session data property counts
  - `website_session_data_values` - Get session data value counts
- **Realtime endpoint**: `realtime` - Get live stats for last 30 minutes
- **Links endpoints**: `links`, `link`, `update_link`, `delete_link`
- **Pixels endpoints**: `pixels`, `pixel`, `update_pixel`, `delete_pixel`
- **Reports endpoints** (13 new methods):
  - CRUD: `reports`, `create_report`, `report`, `update_report`, `delete_report`
  - Specialized: `report_attribution`, `report_breakdown`, `report_funnel`, `report_goals`, `report_journey`, `report_retention`, `report_revenue`, `report_utm`
- **Website stats endpoints**:
  - `website_events_series` - Get events series with time bucketing
  - `website_metrics_expanded` - Get detailed metrics with engagement data
- **Events endpoints**:
  - `website_events_list` - Get paginated event details
  - `website_event_data` - Get data for individual event
  - `website_event_data_events` - Get event data names and counts
  - `website_event_data_fields` - Get event data fields
  - `website_event_data_properties` - Get event properties
  - `website_event_data_values` - Get event data values
  - `website_event_data_stats` - Get aggregated event stats

### Changed

- Updated `website_metrics` documentation with all current metric types: `path`, `entry`, `exit`, `title`, `query`, `referrer`, `channel`, `domain`, `country`, `region`, `city`, `browser`, `os`, `device`, `language`, `screen`, `event`, `hostname`, `tag`
- Updated user role documentation to include `view-only` option
- Updated team role documentation: roles for adding/updating team users are `team-manager`, `team-member`, `team-view-only` (team-owner is auto-assigned to creator)
- Updated `send_event` documentation with `tag` and `id` parameters
- Improved filter parameter documentation across all endpoints including `hostname`, `segment`, and `cohort`
- Added optional `id` parameter to `create_user` for UUID control
- **Report endpoints**: Updated to use `startDate`/`endDate` (ISO 8601 format) instead of `startAt`/`endAt` (timestamps)
- Added `window` parameter to `report_funnel` for days between steps
- Added `timezone` parameter (required) to `report_retention`
- Added `filters` parameter documentation to all report methods
- Updated `unit` parameter to include `minute` option (minute, hour, day, month, year)
- Made `timezone` required for `website_sessions_weekly`
- Made `startAt`/`endAt` required for `website_session_activity`
- Added complete filter parameters to all session endpoints (path, referrer, title, query, hostname, tag)

### Deprecated

- `event_data_events` - Use `website_event_data_events` instead
- `event_data_fields` - Use `website_event_data_fields` instead
- `event_data_stats` - Use `website_event_data_stats` instead
- `users` - Use `admin_users` instead

### Fixed

- Fixed event data endpoint paths from `/api/event-data/...` to `/api/websites/:websiteId/event-data/...`
- Fixed `verify_token` to use POST method instead of GET

## [0.1.3] - 2025-02-19

- Bug fixes and improvements

## [0.1.0] - 2024-07-22

- Initial release
