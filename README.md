# EllesmereUI Rested Style
<img width="1858" height="1198" alt="{F33EF727-D605-4A8A-88DD-07E624AA1ACC}" src="https://github.com/user-attachments/assets/29ffe5e3-0415-43da-9634-99b489359ff6" />
<img width="295" height="446" alt="{2309D940-3E39-4062-B124-F615C7437FE5}" src="https://github.com/user-attachments/assets/c7720620-f6e3-46a9-b092-0f62f2d85210" /> <img width="96" height="122" alt="{B0A8352A-F537-4BAE-8B0A-2D4ECE815EC7}" src="https://github.com/user-attachments/assets/52753a3e-5cca-4557-a3cf-7f37fdaab1af" /> <img width="117" height="130" alt="{FA1964D9-CDD9-43E2-B90C-E06A430C0366}" src="https://github.com/user-attachments/assets/31eb2f05-ce86-4bc0-be18-f60ae2925c0e" /> <img width="117" height="119" alt="{A5C46538-099C-4B5A-AE67-215D9811DD97}" src="https://github.com/user-attachments/assets/8bc3087b-8cac-484c-baca-fb3150e0fbd1" />

Better-looking rested indicators for **EllesmereUI** on **WoW Forever**.

EllesmereUI's *Rested Indicator* (Quality of Life page) marks resting with a small plain-text `ZZZ` on the player frame. This add-on replaces that text with one of four styles, and you can customize each one. It is a standalone add-on: **no EllesmereUI file is modified**, and you can switch back to the original text at any time.

| | |
|---|---|
| Game client | WoW Forever (Interface 16001) |
| Tested with | EllesmereUI 9.6 |
| Requires | EllesmereUI, EllesmereUI Unit Frames |
| Version | 1.0.0 |

---

## Styles

### Blizzard (animated) *(default)*
Blizzard's own animated "Zzz" from the stock player frame. The add-on reads the art and animation timing straight from the game client, so it matches what Blizzard's frame shows. If the client has no animated art, it falls back to the classic static rest icon with a soft pulse.

- Size
- Tint (with opacity; white keeps the original colors)
- Animate on / off
- Animation speed
- Desaturate (combine with Tint to get any color)

### Classic Badge
A round, gold-rimmed badge with "Zz" in it.

- Size, text (`Zz`, `Zzz`, `zZ`, `Z`), text size, font
- Text color, background color (with opacity)
- Ring on / off, ring color or **UI Accent Color**, ring thickness
- Pulse

### Floating Letters
"z z Z" letters that rise and fade out, like a sleeping character.

- Number of letters (1–5), letter size, letter case, font, outline
- Color: **UI Accent Color**, class color, gold or a custom color
- Cycle time, rise height, sideways drift, opacity

### Icon Square
A square in the style of a buff icon, with a pulsing "Z".

- Size, text, text size, font
- Text color, background color (with opacity)
- Border thickness (0 = no border), border color or **UI Accent Color**
- Pulse on / off, pulse amount

### EllesmereUI (ZZZ text)
The original EllesmereUI look, unchanged.

Colors set to *UI Accent Color* follow **Global Settings → UI Accent Color** live, with no reload needed.

---

## Installation

1. Download or clone this repository.
2. Copy the `EllesmereUI_RestedStyle` folder into:
   ```
   World of Warcraft\_classic_beta_\Interface\AddOns\
   ```
3. Make sure **EllesmereUI Rested Style** is enabled in the in-game AddOn list.
4. `/reload`

## Usage

Open **EllesmereUI → Quality of Life → QoL**, turn on **Rested Indicator** and click its **cog**:

| Setting | What it does |
|---|---|
| **Style** | Picks one of the styles above |
| **Preview** | Shows the indicator outside a resting area too, so you can see your changes (not saved) |
| **Anchor** | Inside Top Left / Top / Top Right, Center, Above Left / Center / Right, Outside Left / Right |
| **Anchor To** | Health Bar or the whole Player Frame (including the portrait) |
| **X / Y Offset** | EllesmereUI's own offsets, still used |
| *style settings* | Only the selected style's settings are shown |

### Slash commands

| Command | |
|---|---|
| `/eurest` | Toggle the preview |
| `/eurest reset` | Reset all Rested Style settings to defaults |
| `/eurest debug` | Print diagnostic info (visibility, size, position, art info) to chat |

Settings are saved per account in `EllesmereUI_RestedStyleDB`.

---

## How it works

- EllesmereUI keeps creating and driving its own `ZZZ` FontString (`pf._restIndicator`). Its Show / Hide on `PLAYER_UPDATE_RESTING` and its X/Y offsets keep working as before.
- The add-on hooks that FontString's `Show`, `Hide`, `SetShown` and `SetPoint`, makes it invisible, and shows its own indicator in the same state and position.
- The indicator sits directly on the player frame, above the portrait and border. It is not inside the health bar's clipping frame, so anchors outside the bars are not cut off.
- The options are added by wrapping `EllesmereUI.BuildInlineCog` for the stock **"Rested Indicator Position"** cog. Rows for styles you have not selected are hidden, so the popup only shows what applies.

## Known limitations

- If a future EllesmereUI version renames the *Rested Indicator Position* cog, the extra settings stop appearing in the menu. The last chosen style keeps working, and the stock X/Y cog is shown unchanged.
- The **Blizzard** style uses whatever animated art the game client ships. If a client update changes that art's layout, the animation may look wrong. Use `/eurest debug` and open an issue with the output.
- Fonts that the client does not have fall back to the EllesmereUI unit frame font.

## Files

```
EllesmereUI_RestedStyle/
├── EllesmereUI_RestedStyle.toc
├── RestedStyle.lua           -- runtime: styles, hooks, slash commands
├── RestedStyle_Options.lua   -- options: Rested Indicator cog integration
└── README.md
```

## Credits

Built on top of **EllesmereUI** by Ellesmere. This is an unofficial add-on and is not affiliated with EllesmereUI or Blizzard Entertainment.

