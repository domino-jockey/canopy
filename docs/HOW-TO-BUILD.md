# How to build, run and test Canopy

A plain-language guide to turning this folder of code into the app you use, and to the `make` commands that do it for you.

## The commands

Open Terminal, go to the project folder, then type one of these:

```sh
cd ~/Projects/breakreminder
make install
```

| Command        | What it does                                                                                      | When to use it                                    |
|----------------|---------------------------------------------------------------------------------------------------|---------------------------------------------------|
| `make`         | Lists all the commands.                                                                           | When you forget.                                  |
| `make install` | Builds the finished app, copies it to `/Applications`, tells macOS to re-read its icon, and opens it (quits the old one first). | After any change you want to use day to day.      |
| `make test`    | Builds the app and runs the 93 automatic tests. Prints a one-line summary, or the failures.       | After a change, to check nothing broke.           |
| `make run`     | Builds a *test copy* and opens it in place of your installed Canopy.                              | Trying something out without installing it.       |
| `make build`   | Builds the test copy without opening it.                                                          | Just to check the code compiles.                  |
| `make stop`    | Quits Canopy.                                                                                     | When you need it closed.                          |
| `make xcode`   | Opens the project in Xcode.                                                                       | If you want to look around in Xcode.              |
| `make icon`    | Redraws the app icon and menu bar leaf from `design/make-icon.swift`.                             | After changing the icon script.                   |
| `make clean`   | Deletes everything that was built (~500 MB). The next build starts from zero and takes longer.    | Freeing disk space, or when a build acts strangely. |
| `make project` | Recreates the Xcode project file. The other commands already do this.                             | Rarely needed by hand.                            |

`make run` and `make install` both quit whichever Canopy is running, since only one can run at a time. After `make run`, open `/Applications/Canopy.app` (or run `make install`) to go back to your normal copy.

## How a Mac app gets built (the short version)

- **Swift** is the programming language. The code is the `.swift` files in `Canopy/`. A computer can't run those directly; they have to be **compiled** (translated) into a program first.
- **Xcode** is Apple's app for writing and building Mac apps. It includes **`xcodebuild`**, the same builder without the windows, which is what `make` uses. You don't need to open Xcode itself.
- **The Xcode project file** (`Canopy.xcodeproj`) tells the builder which files make up the app and how to build it. It's messy and hard to read, so we don't write it by hand: **XcodeGen** creates it from the short, readable `project.yml`. That's why the project file isn't saved in git, and why every `make` command recreates it first.
- **A `.app` is really a folder.** `Canopy.app` holds the compiled program, the icon, sounds and settings like the app's name. Finder just shows it as one icon. (Right-click › Show Package Contents to look inside.)
- **Debug vs Release:** the same code built two ways. **Debug** (`make build` / `make run`) builds faster and is easier to investigate; it lands in `build/Build/Products/Debug/`. **Release** (`make install`) is optimised for everyday use; it's built in `build/release/` and copied to `/Applications`.
- **The `build/` folder** is where everything built goes, plus downloaded add-ons (like the keyboard shortcuts package). It isn't saved in git and can always be deleted (`make clean`); it just makes the next build slower.
- **Signing:** macOS wants every app signed to show who made it. Canopy is signed "to run locally", which works on this Mac without a paid Apple developer account. (To give the app to someone else, it would need a proper signature.)
- **Tests** are small programs in `CanopyTests/` that check the logic automatically, e.g. "after 20 minutes of work, a break starts". `make test` runs them all in a few seconds. Because the scheduler takes the time as an input, the tests can fake hours passing instantly.
- **Your settings and stats** aren't stored in the app. They live in macOS's settings storage under the app's ID (`com.jammyjellyfish.BreakReminder`), so rebuilding, reinstalling or `make clean` never loses them.

## Everyday workflows

**Made a change (or Claude did), want to use it:**
```sh
make test       # check nothing broke
make install    # use it
```

**Something looks wrong after a build:**
```sh
make clean
make install
```

**Added a new `.swift` file:** nothing special. Every command recreates the project, so new files are picked up.

## If something goes wrong

| What you see                                              | What it means / what to do                                                                                   |
|-----------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| `xcodegen: command not found`                             | XcodeGen isn't installed: `brew install xcodegen`.                                                            |
| `xcodebuild: error: … requires Xcode`                     | Xcode isn't set as the active developer tool: `sudo xcode-select -s /Applications/Xcode.app`.                 |
| The first build takes minutes                             | Normal after `make clean`: it downloads the shortcuts package and compiles everything. Later builds are fast. |
| `make test` shows `✘` lines or `TEST FAILED`              | A test failed; the `✘` lines name it. The full output is in `build/test.log`.                                 |
| `error:` lines with a file name and line number           | The code doesn't compile. The message points to the line.                                                     |
| The app doesn't open after install (error -600)           | It was opened too fast after quitting. Run `open /Applications/Canopy.app` again.                             |
| You don't see your change                                 | You may be looking at the other copy. `make install` puts the latest in `/Applications` and restarts it.      |
| The icon in Finder or the Dock didn't update              | macOS caches icons. `make install` already refreshes it; if it's still old, run `killall Dock Finder`.        |

## Where things are

- `Makefile`: the commands above (you can read it; each command has a one-line description after `##`).
- `project.yml`: the recipe XcodeGen turns into the Xcode project.
- `Canopy/`: the app's code, sounds and icon. `CanopyTests/`: the tests.
- `docs/ARCHITECTURE.md`: how the code is organised. `docs/DECISIONS.md`: why things are built the way they are.
