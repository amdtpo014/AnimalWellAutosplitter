// ANIMAL WELL AUTOSPLITTER, created by talia
// Special thanks to Cursed and Marlin for early testing, and to the save decoding datamining thread

state("Animal Well") {
    // IGT counted in frames (60fps)
    uint file1Timer : 0x02BFD308, 0x5D8;
    uint file2Timer : 0x02BFD308, 0x275E8;
    uint file3Timer : 0x02BFD308, 0x4E5F8;

    // Integer representation of a binary string signifying main item progress
    // Item bit positions correspond to their placements in the inventory menu PLUS ONE
    // (At least that's what was consistent with what I tested:
    // firecracker = 1(2), flute = 2(4), disc = 5(32), wand = 6(64))
    uint file1MainItems : 0x02BFD308, 0x5F4;
    uint file2MainItems : 0x02BFD308, 0x27604;
    uint file3MainItems : 0x02BFD308, 0x4E614;

    // Integer representations the 4 bytes signifying progress of all 4 flames
    // Each byte information is as follows:
    // Sealed flame = 0, crack progress = 1 to 3 (meaning broken), collected = 4, used = 5
    // Thanks to https://github.com/Kein/awsgtools for having already documented this
    uint file1FlameProgress : 0x02BFD308, 0x636;
    uint file2FlameProgress : 0x02BFD308, 0x27646;
    uint file3FlameProgress : 0x02BFD308, 0x4E656;

    // Any% end trigger, becomes true when the final time pops on screen after detonation
    // Currently desynced by a frame or so, but should be whatever since final time is displayed anyway
    // (BROKEN AT THE MOMENT)
    // bool endTrigger : 0xCA9E84, 0x10, 0x28, 0xF68, 0x894;

    // True if game is being played in any file, false if game is in main menu
    bool isInGame : 0x29A5984;

    // Marker for current active file, 0 indexed
    byte activeFile : 0x02BFD308, 0x40C;
}

init {
    // Variable to keep track of file used in the current run, so that timer/splits won't mess up
    // on accidentally going to other files.
    vars.runFile = 0;

    // Variables to keep track of important values for the current run's file
    current.timer = 0;
    current.mainItems = 0;
    current.flameProgress = 0;
}

startup {
    // Since the disc is taken out of your inventory if you die during the cat/dog chase,
    // this makes sure it only splits on the first pickup of it.
    vars.discTaken = false;

    // Settings
    settings.Add("item_group", true, "Split on Items");

    settings.Add("item1", false, "Firecracker", "item_group");
    settings.Add("item2", false, "Flute", "item_group");
    settings.Add("item3", false, "Lantern", "item_group");
    settings.Add("item4", false, "Top", "item_group");
    settings.Add("item5", false, "Disc", "item_group");
    settings.Add("item6", false, "Bubble Wand", "item_group");
    settings.Add("item7", false, "Yo-yo", "item_group");
    settings.Add("item8", false, "Slink", "item_group");
    settings.Add("item9", false, "Remote", "item_group");
    settings.Add("item10", false, "Bouncy ball", "item_group");
    settings.Add("item11", false, "Wheel", "item_group");
    settings.Add("item12", false, "UV Light", "item_group");

    settings.Add("flame_group", true, "Split on Flames");

    settings.Add("flame1", false, "B. Flame (Seahorse)", "flame_group");
    settings.Add("flame2", false, "P. Flame (Cat/dog Ghost)", "flame_group");
    settings.Add("flame3", false, "G. Flame (Chameleon)", "flame_group");
    settings.Add("flame4", false, "V. Flame (Ostrich)", "flame_group");

    // settings.Add("ending_group", true, "Split on Endings");

    // settings.Add("any_end", true, "Normal (Any%) Ending", "ending_group");
}

update {
    if (vars.runFile == 0) {
        // File 1
        current.timer = current.file1Timer;
        current.mainItems = current.file1MainItems;
        current.flameProgress = current.file1FlameProgress;
    } else if (vars.runFile == 1) {
        // File 2
        current.timer = current.file2Timer;
        current.mainItems = current.file2MainItems;
        current.flameProgress = current.file2FlameProgress;
    } else if (vars.runFile == 2) {
        // File 3
        current.timer = current.file3Timer;
        current.mainItems = current.file3MainItems;
        current.flameProgress = current.file3FlameProgress;
    } else {
        // Should never hit this
        current.timer = 0;
        current.mainItems = 0;
        current.flameProgress = 0;
    }
}

start {
    return (current.isInGame && current.file1Timer > old.file1Timer && old.file1Timer == 0
        || current.file2Timer > old.file2Timer && old.file2Timer == 0
        || current.file3Timer > old.file3Timer && old.file3Timer == 0);
}

onStart {
    vars.runFile = current.activeFile;
}

reset {
    return (current.timer < old.timer && current.timer == 0);
}

onReset {
    vars.discTaken = false;
}

split {
    // Each item comparison is a bit mask that checks if the specific bit corresponding to the relevant item
    // is currently 1 and was previously 0. Should re-implement this as a loop in the future.
    bool itemCheck = false;
    for (int i = 1; i <= 12; i++) { // 1-indexed loop, the horrors
        // Special condition for using discTaken on disc check
        bool discExtraCondition = i == 5 ? !vars.discTaken : true;
        itemCheck |= settings["item"+i] 
            && (current.mainItems & (1 << i)) != 0 
            && (old.mainItems & (1 << i)) == 0
            && discExtraCondition;
    }

    // Each flame comparison looks at a different byte in the uint, checking if it was collected
    // (equal to 4)
    bool flameCheck = false;
    for (int i = 0; i < 4; i++) {
        flameCheck |= settings["flame"+(i+1)]
            && ((current.flameProgress >> i*8) & 0xff) == 4
            && ((old.flameProgress >> i*8) & 0xff) != 4;
    }

    return itemCheck || flameCheck;
    // || settings["any_end"] && current.endTrigger && !old.endTrigger);
}

onSplit {
    // If this was the disc split, set discTaken to true.
    vars.discTaken = (current.mainItems & 0x20) != 0 && (old.mainItems & 0x20) == 0 && !vars.discTaken;
}

isLoading { return true; }

gameTime {
    return TimeSpan.FromSeconds(current.timer / 60.0);
}