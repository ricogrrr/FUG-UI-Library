# FUG UI Library

A lightweight, modular Roblox UI library designed for executor environments. Load it via `loadstring` + `HttpGet`, build your UI, and go.

## Quick Start

```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ricogrrr/FUG-UI-Library/main/main.lua"))()

local window = library:CreateWindow({
	Accent = Color3.fromRGB(255, 120, 30),
	Key = Enum.KeyCode.Z
})

local page = window:CreatePage({Icon = "rbxassetid://8547236654"})
local section = page:CreateSection({Name = "My Section", Size = 200, Side = "Left"})

section:CreateToggle({Name = "My Toggle", State = false, Callback = function(State) print(State) end})
```

Press the toggle key (default `Z`) to show/hide the UI.

## Files

| File | Description |
|------|-------------|
| `main.lua` | The library itself. Returns a `library` table. |
| `example.lua` | Full demo UI showing every component. |
| `template.lua` | Minimal starter file with a window, one page, and a few controls. |

## API Reference

### `library:CreateWindow(Properties)`

Creates the main UI window. Returns a `window` object.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Accent` | `Color3` | `Color3.fromRGB(255, 120, 30)` | Accent color used across the UI. |
| `Key` | `Enum.KeyCode` | `Enum.KeyCode.Z` | Key to toggle UI visibility. |

```lua
local window = library:CreateWindow({
	Accent = Color3.fromRGB(136, 180, 57),
	Key = Enum.KeyCode.RightControl
})
```

---

### `window:CreatePage(Properties)`

Creates a new tab/page in the sidebar. Returns a `page` object.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Icon` | `string` | — | `rbxassetid://` image ID for the tab icon. Required. |

```lua
local page = window:CreatePage({Icon = "rbxassetid://8547236654"})
```

---

### `page:CreateSection(Properties)`

Creates a section (panel) on the page. Returns a `section` object.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | `"New Section"` | Title text shown at the top. |
| `Size` | `number` | `150` | Height of the section in pixels. |
| `Side` | `string` | `"Left"` | Which column: `"Left"` or `"Right"`. |

```lua
local section = page:CreateSection({
	Name = "Player ESP",
	Size = 330,
	Side = "Left"
})
```

---

### `section:CreateToggle(Properties)`

Creates a toggle switch. Returns a `content` object.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | `"New Toggle"` | Label text. |
| `State` | `boolean` | `false` | Initial on/off state. |
| `Callback` | `function(state: boolean)` | `function() end` | Called when toggled. |

```lua
section:CreateToggle({
	Name = "Enable ESP",
	State = true,
	Callback = function(State)
		print("ESP:", State)
	end
})
```

---

### `section:CreateSlider(Properties)`

Creates a numeric slider. Returns a `content` object.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | `nil` | Label text. |
| `State` | `number` | `false` | Initial value. |
| `Min` | `number` | `0` | Minimum value. |
| `Max` | `number` | `100` | Maximum value. |
| `Decimals` | `number` | `1` | Decimal precision (e.g. `0.1` for 1 decimal, `0.01` for 2). |
| `Suffix` | `string` | `""` | Text appended to the value (e.g. `"%"`, `"px"`). |
| `Callback` | `function(state: number)` | `function() end` | Called when value changes. |

```lua
section:CreateSlider({
	Name = "FOV",
	State = 180,
	Max = 360,
	Min = 0,
	Decimals = 1,
	Suffix = "px",
	Callback = function(State)
		print("FOV:", State)
	end
})
```

---

### `section:CreateDropdown(Properties)`

Creates a single-selection dropdown. Returns a `content` object.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | `"New Dropdown"` | Label text. |
| `State` | `number` | `1` | Index of the initially selected option (1-based). |
| `Options` | `table` | `{1, 2, 3}` | Array of option strings. |
| `Callback` | `function(state: number, value: string)` | `function() end` | Called when selection changes. Receives the index and the option string. |

```lua
section:CreateDropdown({
	Name = "Hitbox",
	State = 1,
	Options = {"Head", "Chest", "Pelvis", "Nearest"},
	Callback = function(State, Value)
		print("Selected:", Value)
	end
})
```

---

### `section:CreateMultibox(Properties)`

Creates a multi-selection dropdown (checkboxes). Returns a `content` object.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | `"New Dropdown"` | Label text. |
| `State` | `table` | `{1}` | Array of initially selected indices (1-based). |
| `Options` | `table` | `{1, 2, 3}` | Array of option strings. |
| `Min` | `number` | `0` | Minimum number of selections allowed. |
| `Max` | `number` | `1000` | Maximum number of selections allowed. |
| `Callback` | `function(state: table)` | `function() end` | Called when selection changes. Receives the array of selected indices. |

```lua
section:CreateMultibox({
	Name = "Hitscan",
	State = {1, 2},
	Options = {"Head", "Chest", "Arms", "Legs"},
	Callback = function(State)
		print("Selected indices:", table.concat(State, ", "))
	end
})
```

---

### `section:CreateKeybind(Properties)`

Creates a keybind selector. Returns a `content` object.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | `"New Toggle"` | Label text. |
| `State` | `table` / `nil` | `nil` | Initial keybind, e.g. `{"KeyCode", "Z"}`. |
| `Mode` | `string` | `"Hold"` | `"Hold"` or `"Toggle"`. |
| `Callback` | `function(state: boolean)` | `function() end` | Called when keybind is activated/deactivated. |

```lua
section:CreateKeybind({
	Name = "Aimbot Key",
	Mode = "Hold",
	Callback = function(State)
		print("Aimbot active:", State)
	end
})
```

---

### `section:CreateColorpicker(Properties)`

Creates a color picker. Returns a `content` object.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | `"New Toggle"` | Label text. |
| `State` | `Color3` | `Color3.fromRGB(255, 255, 255)` | Initial color. |
| `Callback` | `function(state: Color3)` | `function() end` | Called when color changes. |

```lua
section:CreateColorpicker({
	Name = "ESP Color",
	State = Color3.fromRGB(255, 0, 0),
	Callback = function(Color)
		print("Color:", Color)
	end
})
```

## Tips

- **Property casing**: All properties accept both `PascalCase` and `camelCase` (e.g. `Name` or `name`).
- **Tab icons**: Use `rbxassetid://` with a valid image asset ID (not a decal ID). If you have a decal, copy its `Texture` property in Studio to get the image ID.
- **Sections**: Each page has a left and right column. Set `Side` to `"Left"` or `"Right"`.
- **Section Size**: The `Size` property controls the height of the section panel in pixels. Make sure it's tall enough to fit all your controls.
- **Toggle key**: Set the window's `Key` property to any `Enum.KeyCode` to change the UI toggle key.
