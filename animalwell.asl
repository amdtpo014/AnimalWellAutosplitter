// ANIMAL WELL AUTOSPLITTER, created by talia
// Special thanks to Cursed and Marlin for early testing, and to the save decoding datamining thread

state("Animal Well") {
    // IGT counted in frames (60fps)
    uint file1Timer : 0x02BFD308, 0x5D8;

    // Integer representation of a binary string signifying main item progress
    // Item bit positions correspond to their placements in the inventory menu PLUS ONE
    // (At least that's what was consistent with what I tested:
    // firecracker = 1(2), flute = 2(4), disc = 5(32), wand = 6(64))
    uint file1MainItems : 0x02BFD308, 0x5F4;

    // Integer representations the 4 bytes signifying progress of all 4 flames
    // Each byte information is as follows:
    // Sealed flame = 0, crack progress = 1 to 3 (meaning broken), collected = 4, used = 5
    // Thanks to https://github.com/Kein/awsgtools for having already documented this
    uint file1FlameProgress : 0x02BFD308, 0x636;

    // Any% end trigger, becomes true when the final time pops on screen after detonation
    // Currently desynced by a frame or so, but should be whatever since final time is displayed anyway
    // (BROKEN AT THE MOMENT)
    // bool endTrigger : 0xCA9E84, 0x10, 0x28, 0xF68, 0x894;

    // True if game is being played in any file, false if game is in main menu
    bool isInGame : 0x29A5984;
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

start {
    return (current.file1Timer > old.file1Timer && old.file1Timer == 0 && current.isInGame);
}

reset {
    return (current.file1Timer < old.file1Timer && current.file1Timer == 0);
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
            && (current.file1MainItems & (1 << i)) != 0 
            && (old.file1MainItems & (1 << i)) == 0
            && discExtraCondition;
    }

    // Each flame comparison looks at a different byte in the uint, checking if it was collected
    // (equal to 4)
    bool flameCheck = false;
    for (int i = 0; i < 4; i++) {
        flameCheck |= settings["flame"+(i+1)]
            && ((current.file1FlameProgress >> i*8) & 0xff) == 4
            && ((old.file1FlameProgress >> i*8) & 0xff) != 4;
    }

    return itemCheck || flameCheck;
    // || settings["any_end"] && current.endTrigger && !old.endTrigger);
}

onSplit {
    // If this was the disc split, set discTaken to true.
    vars.discTaken = (current.file1MainItems & 0x20) != 0 && (old.file1MainItems & 0x20) == 0 && !vars.discTaken;
}

isLoading { return true; }

gameTime {
    return TimeSpan.FromSeconds(current.file1Timer / 60.0);
}