# Search Mobile App (Lantern)

Mobile application for searching pricing intelligence before negotiating.

## Status

**Phase:** Planning  
**Tech Stack:** To be decided (React Native vs Native)

## Purpose

Enable users to search and discover pricing data before negotiating:
1. Search by procedure name or code
2. Filter by location and facility type
3. View regional pricing aggregates
4. Export/print for negotiation

## Key Features (Planned)

- Procedure search (by name or CPT code)
- Browse by category
- Location filtering (metro area)
- Facility type filtering
- Regional price ranges and statistics
- Confidence indicators
- Price consistency analysis
- Export/print functionality
- Offline caching of recent searches
- Anonymous usage (no tracking)

## User Experience

**Search flow:**
1. Enter procedure name or browse categories
2. Select procedure from results
3. Optionally filter by location and facility type
4. View pricing ranges with confidence levels
5. See breakdowns by facility type if applicable
6. Export or print for negotiation

**Privacy:**
- No search query logging
- No user tracking
- No account required
- Anonymous usage

## Technical Requirements

- Fast search (response < 500ms)
- Offline support for cached data
- Works without account/login
- Graceful degradation if network unavailable
- Clear confidence and data quality indicators

## Development Status

- [ ] Technology stack decision
- [ ] Architecture design
- [ ] UI/UX wireframes
- [ ] API integration design
- [ ] Search UX optimization
- [ ] Offline caching strategy
- [ ] Development environment setup

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to get involved.
