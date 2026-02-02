## [Unreleased]

## [0.2.0] - 2026-02-02

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

**Configuration:**
- `request_timeout=` setter - users can now customize timeout via `Umami.configure` block
- New `UMAMI_CLOUD_SEND_URL` constant for the Cloud send endpoint URL
- Optional `user_agent:` parameter to `send_event` method for custom User-Agent strings

**Documentation:**
- Configuration Options table in README with all available options and defaults
- Report Types reference table in README

**Test Suite:**
- Comprehensive Minitest test suite with 152 tests
- VCR cassettes for all read API endpoints (33 cassettes)
- CI workflow for Ruby 3.3, 3.4, 4.0
- ~72% line and branch coverage

### Changed

- Updated `website_metrics` documentation with all current metric types
- Updated user role documentation to include `view-only` option
- Updated team role documentation with `team-manager`, `team-member`, `team-view-only` roles
- Updated `send_event` documentation with `tag` and `id` parameters
- Improved filter parameter documentation across all endpoints
- Added optional `id` parameter to `create_user` for UUID control
- Report endpoints use `startDate`/`endDate` (ISO 8601) instead of `startAt`/`endAt` (timestamps)
- Added `window` parameter to `report_funnel` for days between steps
- Added `timezone` parameter (required) to `report_retention`
- Updated `unit` parameter to include `minute` option
- Made `timezone` required for `website_sessions_weekly`
- Made `startAt`/`endAt` required for `website_session_activity`

### Fixed

- **Critical**: Fixed `send_event` to use correct Umami Cloud URL (`https://cloud.umami.is/api/send`)
- **Critical**: Added mandatory `User-Agent` header to `send_event` requests (fixes [#2](https://github.com/rameerez/umami-ruby/issues/2))
- Fixed `send_event` to not send unnecessary `Authorization` header
- Fixed event data endpoint paths from `/api/event-data/...` to `/api/websites/:websiteId/event-data/...`
- Fixed `verify_token` to use POST method instead of GET
- Fixed `website_event_data_stats` return type documentation

### Deprecated

- `event_data_events` - Use `website_event_data_events` instead
- `event_data_fields` - Use `website_event_data_fields` instead
- `event_data_stats` - Use `website_event_data_stats` instead
- `users` - Use `admin_users` instead

## [0.1.3] - 2025-02-19

- Bug fixes and improvements

## [0.1.0] - 2024-07-22

- Initial release
