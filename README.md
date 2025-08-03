📌 Features
✔ Custom Jail Location – Send players to a high-security prison (configurable coordinates).
✔ Anti-Escape System – Prevents fleeing with teleport-back and vehicle blocking.
✔ Time-Based Sentences – Lock players for minutes/hours with automatic release.
✔ Persistence – Saves jail data, so players remain imprisoned after reconnecting.
✔ Admin Commands – Easy-to-use /ajail and /unjail commands.
✔ Full Action Restriction – Blocks weapons, attacks, and vehicle usage.
✔ Custom Notifications – Clear in-game messages for admins & prisoners.

🚀 Installation
Download the latest release and extract it into your resources folder.

Add this to your server.cfg:

lua
ensure ajail
Configure admins in server.lua (Steam/Discord IDs).

Restart your server – done!

🔧 Configuration
📍 Locations
Edit in client.lua:

lua
local jailLocation = vector3(4391.08, -4623.84, 134.42)  -- Prison coordinates  
local releaseLocation = vector3(-1792.08, 4069.86, 145.70) -- Release point  
👑 Admins Setup
Add your IDs in server.lua:

lua
local admins = {
    steam = {"110000139dc0b25"},    -- Steam Hex IDs
    discord = {"515202972867624961"} -- Discord IDs
}
📜 Commands
Command	Usage	Description
/ajail	/ajail <ID> <Minutes> <Reason>	Jails a player with a specified reason.
/unjail	/unjail <ID>	Releases a player early (admin-only).
🔐 Security
No Escape – Players get teleported back if they leave the jail zone.

Vehicle Protection – Any entered vehicle gets deleted.

Weapon Lock – All weapons are removed upon imprisonment.

UI Restrictions – Blocks F1 & ESC menu in jail.

📂 Data Persistence
Jailed players are saved in jailed_players.json, ensuring they stay imprisoned even after server restarts.
