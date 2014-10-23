#### Please don't email Kevin for support, this codebase was forked from SourceForge and is being developed independently.

# Breakaway 2.1
## General Information
### October 2014

Breakaway 2.1 is an application that allows you to automatically play/pause
iTunes by using the headphone jack and/or the mute button. It is similar to the
built-in functionality offered by an iPod.

---

## Basic Usage

The usage of Breakaway is very straightforward. Simply have Breakaway and iTunes
running at the same time, then preform one of the following actions:

* Press the mute button
* Connect/disconnect headphones from the headphones jack

Depending on the playing status of iTunes, Breakaway will intelligently decide
what to do. For example, consider iTunes playing and the headphones connected.
If the headphones are suddenly disconnected, Breakaway would pause iTunes. If
they are connected again, Breakaway would resume play. Similar scenarios exist
with the mute button.

Breakaway will always try to follow your lead. If you set iTunes to play,
Breakaway will honor that state and always revert back to it whenever possible.
Similarly, if you set iTunes to pause, Breakaway will not attempt to set it to
play.


### Preferences

#### General

**Automatically start at login**: Breakaway will be added to your Login Items (manually accessable via System Preferences->Accounts).

**Show in menu bar**: A menu extra will be available in the top right of your
    screen for quick access and mode display.

**Show in Dock**: Requires a restart for changes to take effect. Shows Breakaway's icon in the Dock.

**Fade-in**: Controls how fast the fade-in happens. Moving the slider all the way to the right turns the feature off.

**Plugins**
    The left table houses all plugins installed and loaded. Selecting an item on the left reveals it's contents on the right table. If the plugin is designed to be created multiple times, you can add/remove instances of the plugin with the `+`/`-` buttons at the bottom of the screen. Plugins' options are found by opening the info drawer (the `i` button). 

If you want to add/delete plugins, click on the button under the left table.  This will open a window to the plugin directory. Simply add/delete plugins like you would any other file: drag it to Trash.
    
**Expand Breakaway**
    Enable anonymous system profiling: As stated under the preference, all information is anonymously sent. Specifically, the information being sent is:
    
* Mac OS X version
* CPU type/subtype
* Mac model
* Number of CPUs
* 32-bit vs. 64-bit
* CPU speed
* RAM size
* Application name
* Application version
* User's preferred language
    
**Advanced System Diagnostics**
Follow the onscreen directions. This window can be used to provide more anonymous data that could not be collected during the former profiling because it requires user interaction.

This information is more useful for debugging and seeing if Breakaway is correctly operating on the machine in question. If you are experiencing issues, use this window to generate a report of Breakaway's main functions and send it to the developer. It takes about 5 seconds to complete.

**Update**
    Automatically check for updates: On startup, Breakaway will check for new
    versions and notify the user if there is one available. (*Update is currently broken.*)

**Automatically download updates**: If there is a download available, Breakaway will automatically download it and prompt the user once it is ready for install. (*Update is currently broken.*)

----                

##  Frequently Asked Questions

1. **Breakaway does not work.**

    * Make sure that Breakaway is enabled (through menu extra).
    * Make sure that you are not using any fancy audio setups (Soundflower, etc.).  If you are, please contact the developer to see if there is a possible solution.

   If Breakaway is acting strange or not operating properly, try the following solutions (one at a time, in order):
    
    1. Start Breakaway (if is not running already)
		  * Quit iTunes
		  * Start iTunes
	1. Quit Breakaway
	      * Quit iTunes
	      * Start Breakaway
	      * Start iTunes
  
    1. Quit Breakaway
          * Move the preference file `[~]/Library/Preferences/com.mutablecode.breakaway.plist` to the Desktop
          * Start Breakaway

1. **How do I install Breakaway?**

    Drag the "Breakaway.app" file anywhere you like.
    
    
1. **How do I uninstall Breakaway?** 
    * Place the `Breakaway` app (`/Applications/Breakaway.app/` usually) in Trash
    * Place the preference file in `[~]/Library/Preferences/com.mutablecode.breakaway.plist` in Trash
    * If the directory `[~]/Library/Application Support/Breakaway/` exists, place it in Trash

1. **Does Breakaway support Growl?**

    Almost!  Pull requests welcomed!

1. **Does Breakaway support any other application besides iTunes?**

    Not currently but there is plugin support if you'd like to add it.

1. **Can I help with programming or localizing?**

   Yes!   Pull requests welcomed!
   
   Please see [https://github.com/steakknife/breakaway](https://github.com/steakknife/breakaway)
   
    (**Original answer:** *Sure, I would love the extra help. Just send me an email and we can discuss it.*)

1. **Do you (Kevin) accept donations?**
    Send money to Kevin, because it's no good here. :)
    (**Original answer:** *Graciously.*)


### Support Contact

[https://github.com/steakknife/breakaway/issues](https://github.com/steakknife/breakaway/issues)

### Authors of this fork

- [Barry Allard](mailto:"Barry Allard" <barry.allard@gmail.com>)
- Your name here

### Original Author (don't contact for support)

[Kevin Nygaard](mailto:"Kevin Nygaard" <admin@mutablecode.com>)



### License

**TL;DR: GPL 3.0 **

Breakaway is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Breakaway is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Breakaway.  If not, see <http://www.gnu.org/licenses/>.
