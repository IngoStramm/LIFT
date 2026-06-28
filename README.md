# LIFT

**LIFT** means **Lightweight Interface Frame Tweaker**.

LIFT is a small World of Warcraft Classic TBC Anniversary addon that makes selected default Blizzard interface windows draggable and remembers their positions.

It is intentionally narrow in scope: it does not move unit frames, action bars, minimap, chat frames, raid frames, or persistent HUD elements.

## Compatibility

- World of Warcraft Classic TBC Anniversary
- Interface version: `20505`

## Installation

Download `LIFT.zip` from the latest GitHub Release and extract it into:

```text
World of Warcraft/_anniversary_/Interface/AddOns/
```

After extraction, the addon folder should be:

```text
World of Warcraft/_anniversary_/Interface/AddOns/LIFT/
```

Restart the game or reload the UI.

Do not use GitHub's green **Code > Download ZIP** button for installation. That downloads the source repository snapshot, not the packaged addon.

## Supported commands

- `/lift`
- `/lift help`
- `/lift status`
- `/lift reset`
- `/dragui`
- `/dragui help`
- `/dragui status`
- `/dragui reset`

## Initial supported windows

LIFT attempts to support these Blizzard windows when they exist in the client:

- Character Frame
- Spellbook
- Talent Frame
- Quest Log
- Quest Window
- NPC Dialogue
- Social/Friends
- Guild
- LFG
- Help/GM ticket
- TradeSkill/Crafting
- Merchant
- Auction House
- Trainer
- Bank
- Inspect
- Mail
- Item Text
- Petition/Charter
- Tabard Designer
- Taxi/Flight Master
- Stable Master

Missing frames are ignored without errors.

## Notes

- Positions are saved in `LIFTDB`.
- Supported windows are draggable whenever they appear.
- If a frame is protected, unavailable, or unsafe to move, LIFT skips it defensively.
