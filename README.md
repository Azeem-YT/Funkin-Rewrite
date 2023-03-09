# Funkin' Rewriten

**This is a Modded Version of Friday Night Funkin'**

Find the original version here: https://github.com/FunkinCrew/Funkin
Play original game on Newgrounds here: https://www.newgrounds.com/portal/view/770371

This game was made with love to Newgrounds and its community. Extra love to Tom Fulp.

## Compiling from source
Follow these steps if you wanna compile the game from source:

- Install [Haxe](https://haxe.org/download/version/4.2.4/)
- Install [HaxeFlixel 4.2.4](https://haxeflixel.com/documentation/install-haxeflixel/) after downloading Haxe
- Install [Git](https://git-scm.com/downloads)

**Installing HaxeFlixel**
Open Command Prompt.
To Install HaxeFlixel, Type this into your Command Prompt
```
haxelib install lime
haxelib install openfl
haxelib install flixel
```

**Installing The Libraries**
You will now have to Install additional libraries by running these commands in the command prompt.
```
haxelib install flixel-tools
haxelib install flixel-ui
haxelib install hscript
haxelib install flixel-addons
haxelib run lime setup
haxelib run lime setup flixel
haxelib run flixel-tools setup
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit.git
haxelib install hxCodec
haxelib install HxShaders
```

# Compiling The Game
- If you see any messages relating to deprecated packages, ignore them. They're just warnings that don't affect compiling

## HTML5
All you need to do is run the command `lime test html5` wherever the project.xml file is and run the HTML5 version.
It might have some error giving the state of the game right now.

## LINUX
You only need to open a terminal in the project directory and run `lime test linux -debug`.
After you've done that, run the executable file in export/release/linux/bin.

## MAC
'lime test mac -debug' should work, if not, check the internet, it surely has a guide on how to compile Haxe stuff for Mac.

## WINDOWS
You need to install Visual Studio Community 2019. While installing VSC, don't click on any of the options to install workloads. Instead, go to the individual components tab and choose the following:
* MSVC v142 - VS 2019 C++ x64/x86 build tools
* Windows SDK (10.0.17763.0)

This will install about 4-5 GB of crap, but is necessary to build for Windows.

## Thing I plan to add

- Easy Modding
- Modcharts/Lua Scripts
- Hscript Modding
- And More!

## Things I've already added

- Graphics loading (Mods)
- Sound loading (Mods)
- Accuracy System


# Credits
## ---------------Engine------------------
- Azeem - The only one working on this lol
## -------------Funkin Crew---------------
- [ninjamuffin99](https://twitter.com/ninja_muffin99) - Programmer
- [PhantomArcade3K](https://twitter.com/phantomarcade3k) and [Evilsk8r](https://twitter.com/evilsk8r) - Art
 -[Kawaisprite](https://twitter.com/kawaisprite) - Musician
