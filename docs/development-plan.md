# Lorem's Cooldown Tracker - Development Plan

## Current State (v0.1.0-alpha)
- [ ] Spell category filtering (damage/healing/utility)
- [ ] Smart cooldown grouping
- [ ] Mouseover spell details

## Immediate Tasks (v0.2.0)
- [ ] Add settings panel
  - [ ] Show/hide time text
  - [ ] Timeline scale (max time shown)
  - [ ] Marker interval customization
  - [ ] Custom time ranges (1m, 2m, 3m, etc.)
- [ ] Improve item tracking
  - [ ] Auto-detect equipped trinkets
  - [ ] Track engineering items
  - [ ] Track potions and consumables
  - [ ] Track shared cooldown groups
- [ ] Add visual customization
  - [ ] Background color/texture
  - [ ] Marker appearance
  - [ ] Icon border style
  - [ ] Custom timeline themes
  - [ ] Icon glow effects for important cooldowns

## Future Features (v0.3.0+)
- [ ] Multiple timeline groups
  - [ ] Separate timelines for different types (spells/items)
  - [ ] Custom groups
  - [ ] Group reordering
  - [ ] Vertical stacking option
  - [ ] Group color coding
- [ ] Enhanced cooldown filtering
  - [ ] Minimum/maximum cooldown duration
  - [ ] Blacklist/whitelist specific spells
  - [ ] Category filtering (damage/utility/etc)
  - [ ] Smart filters based on spec/talents
  - [ ] Context-aware filtering (PvP/PvE)
- [ ] Shared cooldown tracking
  - [ ] Track group member cooldowns
  - [ ] Optional announcements
  - [ ] Raid cooldown coordination
  - [ ] Visual indicators for overlapping cooldowns
- [ ] Profile system
  - [ ] Per-character settings
  - [ ] Import/export profiles
  - [ ] Preset configurations
  - [ ] Role-based profiles
  - [ ] Situation-based profiles (raid/dungeon/pvp)

## Quality of Life Improvements
- [ ] Tooltip enhancements
  - [ ] Show exact cooldown time
  - [ ] Show spell/item details
  - [ ] Keybind information
  - [ ] Spell history tracking
  - [ ] Usage statistics
- [ ] Sound effects
  - [ ] Optional sound on cooldown finish
  - [ ] Customizable sounds
  - [ ] Sound categories by importance
  - [ ] Smart sound throttling
- [ ] Performance optimizations
  - [ ] Reduce update frequency for longer cooldowns
  - [ ] Batch position updates
  - [ ] Smart event throttling
  - [ ] Memory usage optimization
  - [ ] Frame pool for icons

## Bug Fixes & Polish
- [ ] Fix marker positions on frame resize
- [ ] Improve animation smoothness
- [ ] Add error handling for invalid items/spells
- [ ] Clean up event handling
- [ ] Add debug logging system
- [ ] Improve frame strata handling
- [ ] Better combat state handling
- [ ] Smoother timeline scaling

## Documentation
- [ ] User guide
- [ ] API documentation for other addon authors
- [ ] Configuration examples
- [ ] FAQ section
- [ ] Video tutorials
- [ ] Integration guides
- [ ] Troubleshooting guide

## Testing
- [ ] Unit tests for core functionality
- [ ] Integration tests with other addons
- [ ] Performance benchmarks
- [ ] Cross-class testing
- [ ] PvP-specific testing
- [ ] Memory leak testing
- [ ] Frame rate impact testing
- [ ] Load time optimization

## Release Strategy
1. **Beta**
   - Settings panel
   - Enhanced item support
   - Visual customization
   - Bug fixes
   - Performance baseline

2. **Release**
   - Multiple timeline groups
   - Profile system
   - Full documentation
   - Performance optimizations
   - Comprehensive testing suite

## Contributing
Guidelines for contributors:
1. Follow WoW Classic API conventions
2. Maintain backward compatibility
3. Document all new features
4. Include test cases
5. Follow existing code style
6. Write meaningful commit messages
7. Include performance impact analysis
8. Test across different client versions 