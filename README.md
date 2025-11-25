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

There is now a functional puzzle for the first room.  We changed it from what we originally planned to make it more of a physics based puzzle.  You pick up a cannonball and load it into a cannon in the room.  Then you can aim the cannon and try to shoot the door so you can escape the room.  If you miss the door the cannonball will bounce off the walls and hit the floor.  You get three chances to hit the door, after which the cannonball will break from hitting the walls.  When this happens a restart button will appear for you to try the level over again.  There are game objectives in the corner to help direct the player on what to do.  If you do knock the door down you can walk through and be taken to the second room, which is currently under development.