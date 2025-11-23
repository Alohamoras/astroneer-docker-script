# Disabling Client-Side Encryption for Astroneer

If your server uses the **armadous** or **whalybird** Docker images (which don't support encryption), players connecting from Linux or Steam Deck must disable client-side encryption.

> **Note:** If you're using the **birdhimself** image, you can skip this guide as it supports encryption.

## Why Is This Needed?

Wine (the compatibility layer used to run Windows games on Linux) doesn't fully support the encryption library (bcrypt.dll) that Astroneer uses. Therefore:

- Servers running on Wine must disable encryption
- Clients connecting from Linux/Steam Deck must also disable encryption to match

## For Windows Players

Windows players can connect normally without any changes. This guide is only for Linux/Steam Deck players.

---

## Linux Players (Native Steam)

### Method 1: Edit Configuration File

1. Navigate to the Astroneer config directory:
   ```bash
   cd ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/
   ```

2. Create or edit `Engine.ini`:
   ```bash
   nano Engine.ini
   ```

3. Add these lines:
   ```ini
   [SystemSettings]
   Net.AllowEncryption=False
   ```

4. Save the file (`Ctrl+X`, then `Y`, then `Enter`)

5. Launch Astroneer through Steam

### Method 2: Quick Script

Run this one-liner to automatically configure it:

```bash
mkdir -p ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/ && echo -e "[SystemSettings]\nNet.AllowEncryption=False" >> ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/Engine.ini
```

---

## Steam Deck Players

### Step-by-Step Instructions

1. **Switch to Desktop Mode**
   - Hold the power button
   - Select "Switch to Desktop"

2. **Open Konsole (Terminal)**
   - Click the Application Launcher (bottom left)
   - Search for "Konsole"

3. **Navigate to Config Directory**
   ```bash
   cd ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/
   ```

4. **Create/Edit Configuration**
   ```bash
   nano Engine.ini
   ```

5. **Add Configuration**
   Type or paste:
   ```ini
   [SystemSettings]
   Net.AllowEncryption=False
   ```

6. **Save and Exit**
   - Press `Ctrl+X`
   - Press `Y` to confirm
   - Press `Enter` to save

7. **Return to Gaming Mode**
   - Click the Application Launcher
   - Select "Return to Gaming Mode"

8. **Launch Astroneer**

### Quick Script for Steam Deck

Alternatively, paste this into Konsole:

```bash
mkdir -p ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/ && echo -e "[SystemSettings]\nNet.AllowEncryption=False" >> ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/Engine.ini && echo "Encryption disabled! Launch Astroneer from Gaming Mode."
```

---

## Verification

After applying the changes:

1. Launch Astroneer
2. Go to **Join Game** → **Server Browser**
3. You should now see your server and be able to connect

If you still can't connect:
- Verify the server is running: Ask the server host to check
- Verify the configuration file was saved correctly
- Try restarting Steam completely

---

## Troubleshooting

### "Cannot find config directory"

The directory only exists after you've run Astroneer at least once. Solution:

1. Launch Astroneer once from Steam
2. Let it reach the main menu
3. Close the game
4. Try the configuration steps again

### "Permission denied" when editing

Run the commands with proper permissions:

```bash
sudo nano ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/Engine.ini
```

(You shouldn't normally need sudo, but this can help in some cases)

### Changes don't persist

Steam may reset the config if file permissions are wrong. Fix it:

```bash
chmod 644 ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/Engine.ini
```

### Server still not showing up

1. **Verify server is running:**
   ```bash
   # On server machine
   docker ps
   ```

2. **Check if encryption is actually disabled on server:**
   ```bash
   # On server machine
   cd ~/astroneer-server
   ./logs.sh
   # Look for encryption-related messages
   ```

3. **Add server manually:**
   - In Astroneer, go to **Join Game** → **Add Server**
   - Enter server IP address
   - Enter port (default: 7777)

### Different Proton version

If you're using a different Proton version, the path might be different. Find it with:

```bash
find ~/.steam -name "Engine.ini" -path "*/Astro/Saved/Config/*"
```

Then navigate to that directory and follow the same steps.

---

## Re-enabling Encryption

If you want to connect to an encrypted server later:

1. Edit the same `Engine.ini` file
2. Change:
   ```ini
   [SystemSettings]
   Net.AllowEncryption=True
   ```

Or simply delete the `Engine.ini` file to reset to defaults:
```bash
rm ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/Engine.ini
```

---

## Security Considerations

**Disabling encryption means:**
- Game traffic between you and the server is not encrypted
- Someone on your network could theoretically see game data
- For private servers with trusted players, this is generally acceptable
- Avoid using public/untrusted networks while playing

**For better security:**
- Ask your server host to use the **birdhimself** Docker image which supports encryption
- Use a VPN if connecting over public networks
- Keep your client and server passwords strong

---

## Summary

**For Linux/Steam Deck players connecting to Wine-based servers:**

1. Locate the config directory: `~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/`
2. Edit or create `Engine.ini`
3. Add `[SystemSettings]` and `Net.AllowEncryption=False`
4. Save and launch Astroneer

**One-command solution:**
```bash
mkdir -p ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/ && echo -e "[SystemSettings]\nNet.AllowEncryption=False" >> ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/Engine.ini
```

Happy space exploring! 🚀
