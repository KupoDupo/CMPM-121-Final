# Devlog Entry - [11/13]

## Introducing the team
**Tools Lead:** Nathan Gonzalez  
**Engine Lead:** Loisel Kleijnen  
**Design Lead:** Izzy Schrack  
**Testing Lead:** Romeo Moreno  

## Tools and materials
**Engine:** We will be using the LÖVE engine because it works well with Lua, the language we want to use, and is a popular tool for 2D game development. Professor Smith also mentioned that it is a popular engine and easier alternative to Unity.  
<https://love2d.org/>  

**Language:** We plan on using the Lua coding language for our project since it's well respected in the game development community and would be a good skill for us to pick up. It also works well with the LÖVE engine.  
<https://www.lua.org/>  

**Tools:** Our primary coding environment will be Visual Studio Code & Codespace with the Lua extension. We are all familiar with this environment, as we used VS Code and Codespace for past experiences and assignments. If we need to use more external tools later into our project, VS code and Codespace offers these tools as extensions.

**Generative AI:** We are okay using copilot on our project, including the autocomplete features and the coding agent. Even though we will be using Generative AI, we will still be overviewing all code created to make sure we understand what was created.    

## Outlook
Lua is a new language to all of us so we're hoping to pick up on that quickly and be able to become relatively familiar with a new tool we can use to design games. The LÖVE engine that works with Lua is also new to us so the same applies. Lua and LÖVE are both highly used in the indie game dev community so we want to get some practical experience with them. Since none of us have any experience with these tools the whole idea of creating a game with them is a little bit of a risk since we have strict deadlines (and grades) associated with them. Our idea for the game is pretty basic/mainstream but it's something we wanted to try implementing.  

## Game Overview - Spooky Puzzle Escape Room
Our game will be a top-down escape room style puzzle where you are trapped in a haunted house. You must sneak around the house and solve puzzles to find your way out.

# Devlog Entry - [11/21]

## How we satisfied the software requirements

### Steps 1-3
We used the [LÖVE](https://love2d.org/) engine along with the [3DreamEngine]() as our third-party 3D rendering (it also has some physics capabalities).  We also found [bump-3dpd](https://github.com/oniietzschan/bump-3dpd) which is a 3D collision-detection library.  We were going to see if the 3DreamEngine worked fine with physics and then delete bump-3dpd if so.

### Steps 5
The player is currently represented by a red sphere, which you view from a topdown camera.  The player sphere will move towards wherever you click.

### Step 7
This repo uses LuaRock's (the lua package manager) luacheck to check files and lint them. 

**Setup Instructions:**

First, install LuaRocks:
#### Windows
Download from [Luarocks](https://luarocks.org/)  
OR  
Use Chocolatey: `choco install luarocks`
#### macOS
Use Homebrew: `brew install luarocks`
#### Linux
Ubuntu/Debian: `sudo apt-get install luarocks`  
Fedora: `sudo dnf install luarocks`  
Arch: `sudo pacman -S luarocks`

Then, install project dependencies:
```bash
luarocks install --only-deps CMPM-121-Final-1.0-1.rockspec
```

This will install luacheck locally for your project. After this you should be all good to go! 

### Step 8: Deployment & Release Process

This repo uses GitHub Actions to automate building and deploying the game. The GitHub Pages site automatically fetches and displays the latest releases.

#### Release Workflow

1. **Commit your changes** to the `main` branch
2. **Create a version tag** using semantic versioning:
   ```bash
   git tag v1.0.0
   # or with a message (preferred):
   git tag -a v1.0.0 -m "Initial release"
   ```
3. **Push the tag** to trigger automation:
   ```bash
   git push origin v1.0.0
   ```
4. **GitHub Actions runs automatically**:
   - `build-release.yml` creates a `.love` file from your code
   - Creates a GitHub Release with the `.love` file attached
   - `deploy.yml` builds a web version and updates GitHub Pages

#### Version Naming Convention

Follow semantic versioning: `v<Major>.<Minor>.<Patch>`

**Examples:**
- `v1.0.0` - Initial release
- `v1.0.1` - Bug fix on v1
- `v1.1.0` - New features added on v1
- `v2.0.0` - Major breaking changes from v1

#### Verifying Your Release

- Check the **Actions** tab to monitor build progress
- Once complete, visit the **Releases** page to see your `.love` file
- The **GitHub Pages site** will automatically display the new release
- Players can download and play from: `https://kupodupo.github.io/CMPM-121-Final`

#### Checking Your Tags

View all existing tags:
```bash
git tag -l
```

Delete a tag locally (if needed):
```bash
git tag -d v1.0.0
```

### What About Steps 4 and 6?
Our intention for our first physics puzzle was that you would pick up an item (a cannonball, which currently looks like a white sphere) and then drop it on a button / pressure plate which would open a door to the next room.  Currently though the cannonball refuses to stay in place and follows the player sphere as it moves.  We eventually decided that we would need to work on this bug past the due date, which is why steps 4 and 6 are currently incomplete.

## Reflection
Completing F1 has made us realize that Lua/LÖVE would be a little more difficult to grasp than I originally thought.  The most difficult part was figuring out how to get the 3D objects to appear normally on the map, and even now it is still a bit janky for the prototype.  I think part of our issue was not starting earlier, which left us scrambling to figure things out.  I think we're on the right track now, we just need to give ourselves more time to work on future requirements.

# Devlog Entry - [11/25]

## F1 - Steps 4 and 6 complete
There is now a functional puzzle for the first room.  We changed it from what we originally planned to make it more of a physics based puzzle.  You pick up a cannonball and load it into a cannon in the room.  Then you can aim the cannon and try to shoot the door so you can escape the room.  If you miss the door the cannonball will bounce off the walls and hit the floor.  You get three chances to hit the door, after which the cannonball will break from hitting the walls.  When this happens a restart button will appear for you to try the level over again.  There are game objectives in the corner to help direct the player on what to do.  If you do knock the door down you can walk through and be taken to the second room, which is currently under development.

# Devlog Entry - [12/01]

## How we satisfied the software requirements

1. The game still uses the LÖVE engine to create a 3D environment using the 3DreamEngine and for collision detection, which is what we used in F1.
2. The player can enter three different rooms/scenes in the game.  Room 1 is the cannon puzzle room, Room 2 is a bridge crossing room, and Room 3 currently contains one of the keys that will be used.  We plan on adding an actual puzzle to the third room later on.
3. You can click on objects to move towards them and pick them up.  For example, in Room 1 you can click on the cannonball to pick it up and load it into the cannon from your inventory.  In Room 2 you can pick up boxes to help you cross the bridge gap.
4. Objects you pickup can be stored in the inventory and moved to different scenes.  For example, in Room 2 you can pick up a key after solving a puzzle and take the key to Room 3 to help you unlock the exit door.
5. The game contains a physics-based puzzle in Room 1 where you must aim and shoot a cannonball at a door to knock it down.  The cannonball will bounce off walls and the floor, and you have three attempts to hit the door before the cannonball breaks.  There is also a puzzle in Room 2 where you must place boxes on platforms to cross a bridge gap and get it to Room 3.  It also spawns a key you need for Room 3.
6. In Room 1, the player must skillfully aim and shoot a cannonball at a door.  If they miss too often the ball will break and they will have to restart the level.  In Room 2, they can fall into a pit if they don't solve the puzzle correctly and will have to restart the level.
7. Once you exit Room 3 an ending screen appears telling you that you have solved all the puzzles and escaped the haunted house.

## Reflection
We made sure to give ourselves enough time to work on F2 this time around, which really helped us iron out a lot of the bugs we were having with the physics and inventory systems.  We also added more features to the game such as an inventory UI, objective text, and room descriptions to help guide the player.  Overall we are happy with how the game is coming along and are excited to add more content and polish to it in the future.  We still have a lot of work to do, but we are confident that we can complete it in time for the final submission.

# Devlog Entry - [12/04]

## Selected Requirements
1. International Languages Requirement: Support three different natural languages including English, a language with a logographic script (e.g. 中文), and a language with a right-to-left script (e.g. العربية).  
We decided to support these three languages in our game (English, Chinese characters, and Arabic). We chose this system since we had minor textual elements in our game so we could meaningfully, but mostly easily switch up our game to support this feature. We also thought it'd be good practice since this is a nice feature to support in future games accessiblity wise.  

## How we satisfied the software requirments 
1. International Language Requirement:  
We created a localization file (localization.lua) where the strings in our game are stored with their three different language versions (English, Chinese, Arabic). We translated these using google Translate and AI so we're not 100% sure how grammatically correct or accurate these translations are but it was our best bet available. Outside files then call the localization object this file creates to load in strings in the language users select like: "_G.localization:get("cannon_loaded")". _G is Lua's global table, anything stored here is accessible from anywhere in your program. So in main when we write the two lines: local Localization = require("localization") we create our localization for the three languages (from localization.lua) and then we make this global namespace so all files can access it with line: _G.localization = Localization. The following syntax: ":get("key") gets the translated version of the key - in this case of the cannon_loaded string. When adding future strings to the game developers will have add the string key to the lua file and then add the 3 translated versions in the format the rest of the file follows.  
We didn't want to use a translation API from online since that felt like taking this an extra step further than it needed to be taken but I do feel like it might've ended up being less work. It would've also been more easily built upon for if we took this game further. Using some kind of API that just needs to be called on strings to automatically translate them rather than needing to have each translation set up in our files does seem like it would be much easier to repeat over and over, especially since we're not language experts ourselves. But oh well, maybe something for next time!
2. Save/Load System Requirement:
We created a save/load system that saves the player's progress in the game including their current room, inventory items, and puzzle states. We used Lua's built-in file I/O functions to read and write a save file in JSON format. When the player chooses to save the game, we serialize the relevant game state data into a JSON string and write it to a file. When loading, we read the file, parse the JSON string back into Lua tables, and restore the game state accordingly. This allows players to save their progress and continue from where they left off later. The game autosaves every 10 seconds, but you can manually save by pressing the "S" key. To load a saved game, you can press "Esc" to go to the main menu and press "Continue".
3. Continous Inventory Requirement:
We implemented a continuous inventory system that allows players to pick up, store, and use items across different rooms in the game. The inventory is represented as a box with multiple item icons inside, which are each labeled. Players can pick up items by clicking on them in the game world, which adds them to their inventory. The inventory UI displays the items the player has collected, and players can select and drag items to objects in the world use them in puzzles or interact with the environment. The inventory persists across room transitions, allowing players to carry items from one room to another and use them as needed to solve puzzles and progress through the game. The continous inventory matters because there is a key in each room that you must pick up and use to exit the final room. If you don't have all the keys you must go back and grab them to escape and win.
4. External DSL:

## Reflection

# Credits
- [Blocky Characters by Kenney](https://kenney.nl/assets/blocky-characters) - Used for Player model
- [Pirate Kit by Kenney](https://kenney.nl/assets/pirate-kit) - Used for Cannon, Cannonball, Crate models
- [Key Model by printable_models](https://free3d.com/3d-model/key-v1--203749.html) - Used for Key models
