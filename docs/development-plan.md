# Lorem's Cooldown Tracker - Development Plan

## Current State (v0.1.0-alpha)
- [x] Basic timeline display (0-5 minutes)
- [x] Spell cooldown tracking
- [x] Item cooldown tracking (PvP trinkets)
- [x] Timeline markers with minute indicators
- [x] Smooth animations for icon movement
- [x] Finish animation (grow and fade)
- [x] Basic slash commands (/lct)
- [x] Frame dragging and locking
- [x] Time text formatting (minutes, seconds)

## Immediate Tasks (v0.2.0)
- [ ] Add settings panel
  - [x] Icon size adjustment
  - [ ] Show/hide time text
  - [ ] Timeline scale (max time shown)
  - [x] Frame opacity
- [ ] Improve item tracking
  - [ ] Auto-detect equipped trinkets
  - [ ] Track engineering items
  - [ ] Track potions and consumables
- [ ] Add visual customization
  - [ ] Background color/texture
  - [ ] Marker appearance
  - [ ] Icon border style

## Future Features (v0.3.0+)
- [ ] Multiple timeline groups
  - [ ] Separate timelines for different types (spells/items)
  - [ ] Custom groups
  - [ ] Group reordering
- [ ] Enhanced cooldown filtering
  - [ ] Minimum/maximum cooldown duration
  - [ ] Blacklist/whitelist specific spells
  - [ ] Category filtering (damage/utility/etc)
- [ ] Shared cooldown tracking
  - [ ] Track group member cooldowns
  - [ ] Optional announcements
- [ ] Profile system
  - [ ] Per-character settings
  - [ ] Import/export profiles
  - [ ] Preset configurations

## Quality of Life Improvements
- [ ] Tooltip enhancements
  - [ ] Show exact cooldown time
  - [ ] Show spell/item details
  - [ ] Keybind information
- [ ] Sound effects
  - [ ] Optional sound on cooldown finish
  - [ ] Customizable sounds
- [ ] Performance optimizations
  - [ ] Reduce update frequency for longer cooldowns
  - [ ] Batch position updates

## Bug Fixes & Polish
- [ ] Fix marker positions on frame resize
- [ ] Improve animation smoothness
- [ ] Add error handling for invalid items/spells
- [ ] Clean up event handling
- [ ] Add debug logging system

## Documentation
- [ ] User guide
- [ ] API documentation for other addon authors
- [ ] Configuration examples
- [ ] FAQ section

## Testing
- [ ] Unit tests for core functionality
- [ ] Integration tests with other addons
- [ ] Performance benchmarks
- [ ] Cross-class testing
- [ ] PvP-specific testing

## Release Strategy
1. **Alpha (Current)**
   - Core functionality
   - Basic UI elements
   - Essential features

2. **Beta**
   - Settings panel
   - Enhanced item support
   - Visual customization
   - Bug fixes

3. **Release**
   - Multiple timeline groups
   - Profile system
   - Full documentation
   - Performance optimizations

## Contributing
Guidelines for contributors:
1. Follow WoW Classic API conventions
2. Maintain backward compatibility
3. Document all new features
4. Include test cases
5. Follow existing code style 