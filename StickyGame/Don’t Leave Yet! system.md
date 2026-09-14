# Don’t Leave Yet\! system

### Goal

Encourage players to remain in the experience by presenting a daily bonus when they open the Roblox system menu.

### User Flow

1. The player opens the Roblox menu using **Escape**, the **Roblox button**, or the equivalent platform control.
2. The **Don’t Leave Yet!** modal immediately appears behind the native Roblox menu, with the gameplay background blurred.
3. While the Roblox menu is open, the offer is visible but not interactive.
4. If the player selects **Leave**, they exit normally.
5. If the player selects **Resume** or closes the menu, the modal remains open and becomes interactive.
6. Pressing **Claim Bonus** grants:
    - **+10 Speed for 30 minutes**
    - **+4 Levels instantly**
7. The bonus can be claimed once per UTC calendar day.

### Technical Requirements

- Show the modal when `GuiService.MenuOpened` fires.
- Enable interaction after `GuiService.MenuClosed` fires.
- Never block or replace Roblox’s native Leave option.
- Validate and grant rewards on the server.
- Persist the last claim date and Speed Boost expiration timestamp.
- Apply the four levels through the regular progression system.
- Do not show the offer if the daily bonus has already been claimed.

### Analytics

- `dont_leave_offer_shown`
- `dont_leave_menu_resumed`
- `dont_leave_bonus_claimed`
- `dont_leave_offer_closed`
- `session_duration_after_claim`
