# Knapsack Arsenal

A word-building turn-based battle game made with Godot. Arrange letter tiles on a grid, form words, and use them to attack enemies.

## Requirements

- Godot Engine 4.7 or newer

## Run the Game

1. Open this folder in Godot using `project.godot`.
2. Let Godot import the project assets.
3. Run the project. The main menu is the configured startup scene.

## How to Play

1. Drag letters from the pouch into the 8-by-5 board.
2. Form valid words of at least three letters horizontally or vertically.
3. Press **Attack** to use new valid words and damage the enemy. A word can only be used once per battle.
4. Press **Pass Turn** if you cannot make a new word. The enemy attacks and marks board slots as targets.
5. Avoid targeted slots before the enemy's next attack. Destroyed slots are temporarily unavailable.

Press **Esc** to open or close the pause menu. The settings menu contains sound and language options. After battle, use the recap screen to review words, replay, or return to the main menu.

## Project Layout

- `scenes/` - Godot scenes and UI
- `scripts/` - gameplay and interface logic
- `assets/` - sprites, UI art, and other visual assets
- `audio/` - music and sound effects
- `dictionary/` - word data used for validation and recap definitions

Asset license and attribution files are kept with their respective asset packs under `assets/`.
