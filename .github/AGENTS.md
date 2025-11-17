# 🐬 Dolphin AI - Agent Guidelines

> Guidelines for AI agents working on **Dolphin AI**, a Godot 4.5 jam game project

## 📋 Project Overview

**Dolphin AI** is a fast-paced Godot 4.5 game where players control a dolphin navigating through obstacles while competing with AI opponents. The game features dynamic water physics, collision-based gameplay, and real-time HUD updates.

### Key Features
- 🐬 Player-controlled dolphin with responsive controls
- 🤖 AI-controlled dolphin opponent
- 🌊 Water rendering with custom shaders
- ⛵ Obstacles: boats, sharks, and dynamic borders
- 🎮 Start menu and game management system
- 📊 HUD with real-time game stats

---

## 🏗️ Project Structure

```
dolphin_ai/
├── scenes/              # Godot scene files (.tscn)
│   ├── main.tscn           # Main game scene
│   ├── DolphinPlayer.tscn   # Player-controlled dolphin
│   ├── DolphinAI.tscn       # AI dolphin
│   ├── Boat.tscn            # Boat obstacle
│   ├── Shark.tscn           # Shark obstacle
│   ├── Border.tscn          # Game boundary
│   ├── HUD.tscn             # UI layer
│   ├── WaterParticles.tscn  # Water effects
│   └── StartMenu.tscn       # Menu screen
├── scripts/             # GDScript files (.gd)
│   ├── dolphin_player.gd    # Player input & movement
│   ├── dolphin_ai.gd        # AI logic
│   ├── game_manager.gd      # Game state & flow
│   ├── hud.gd               # UI updates
│   ├── camera.gd            # Camera control
│   ├── boat.gd              # Boat behavior
│   ├── shark.gd             # Shark behavior
│   ├── obstacle_generator.gd # Spawn obstacles
│   ├── water_particles.gd   # Particle effects
│   ├── background.gd        # Background management
│   └── start_menu.gd        # Menu logic
├── shaders/             # Custom GLSL shaders
│   └── water.gdshader       # Water shader
├── sprites/             # PNG sprite assets
├── materials/           # Material resources (.tres)
├── sounds/              # Audio files
└── project.godot        # Engine config
```

---

## 💻 Code Standards

### GDScript Style

- **Indentation**: Always use **4 spaces** (never tabs)
- **Class Name**: Always place `class_name` before `extends`
- **Naming Convention**: `snake_case` for variables/functions, `PascalCase` for classes
- **Line Length**: Keep under 100 characters when practical
- **Comments**: Use `#` for single-line, `"""..."""` for docstrings

```gdscript
class_name PlayerDolphin
extends CharacterBody2D

## Player movement speed
var move_speed: float = 300.0

## Initialize player with starting position
func _ready() -> void:
    position = Vector2(100, 100)
```

### File Organization

- One class per file (prefer matching filename to class name)
- Keep related functionality grouped logically
- Use `@onready` for node initialization
- Separate concerns: input → movement → collision

### Shader Standards

- `.gdshader` files for custom shaders
- Use consistent variable naming in shaders
- Comment complex shader logic
- Test shaders across target platforms (GL Compatibility)

---

## 🎮 Core Systems

### Player Control (`dolphin_player.gd`)
- Handles keyboard/gamepad input
- Manages player dolphin position and velocity
- Emits signals for HUD updates
- Collision detection with obstacles

### AI Control (`dolphin_ai.gd`)
- Autonomous dolphin movement
- Simple pathfinding/obstacle avoidance
- Can be extended with behavior trees or state machines

### Game Manager (`game_manager.gd`)
- Scene transitions (menu → gameplay)
- Win/lose conditions
- Score tracking
- Pause functionality

### Obstacle System (`obstacle_generator.gd`)
- Spawns boats, sharks at intervals
- Manages obstacle pooling
- Controls difficulty scaling

### HUD System (`hud.gd`)
- Score display
- Health/status indicators
- Real-time updates from game events

### Water & Particles (`water_particles.gd`, `water.gdshader`)
- Dynamic water effects
- Particle system for splashes
- Water shader for visual feedback

---

## 🔧 Development Workflow

### Making Changes

1. **Create a feature branch** for new features:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Follow the code standards** above

3. **Test in the Godot editor** before pushing:
   - Run from `main.tscn`
   - Check both player and AI movement
   - Verify collision detection
   - Test UI updates

4. **Commit with clear messages**:
   ```bash
   git commit -m "feat: add shark AI behavior"
   git commit -m "fix: collision detection on dolphins"
   ```

### Adding New Features

- **New obstacle**: Create `.tscn` in `scenes/`, add `.gd` in `scripts/`, register in `obstacle_generator.gd`
- **New mechanic**: Consider impact on game flow, update `game_manager.gd` if needed
- **New shader**: Test on GL Compatibility renderer
- **New UI**: Update `HUD.tscn` and `hud.gd` together

---

## 🚀 Performance Tips

- Use object pooling for frequently spawned obstacles
- Batch physics updates when possible
- Optimize shader complexity for mobile targets (GL Compatibility)
- Profile with Godot's built-in profiler for large changes

---

## 🐛 Debugging

### Useful Debug Tools
- **Print debug**: `print("variable: ", variable)`
- **Godot Debugger**: Built-in breakpoints and inspection
- **Remote Inspector**: Debug running game instances
- **Profiler**: Monitor performance bottlenecks

### Common Issues
- **Dolphin not moving**: Check signal connections in `game_manager.gd`
- **Collisions not detected**: Verify `CollisionShape2D` nodes are set up
- **Water shader invisible**: Check material assignment in scenes
- **AI not moving**: Verify AI script is attached and `_process()` is called

---

## 📝 Git Workflow

- Main branch should always be **stable**
- Feature branches get code review before merge
- Use descriptive commit messages
- Keep commits focused on single features

---

## ✅ Pre-Commit Checklist

- [ ] Code follows style standards (4-space indentation, snake_case)
- [ ] No unused variables or imports
- [ ] Functions have docstrings if complex
- [ ] Tested in Godot editor
- [ ] No merge conflicts
- [ ] Commit message is clear and descriptive

---

## 📚 Useful Resources

- [Godot 4.5 Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/style_guide.html)
- [Godot Shaders](https://www.shaders.godotshaders.com/)
- [Godot Performance Tips](https://docs.godotengine.org/en/stable/tutorials/performance/index.html)

---

**Happy coding! 🚀**