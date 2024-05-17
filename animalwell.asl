state("Animal Well") {
    // IGT counted in frames (60fps)
    int file1Timer : 0x02D43958, 0x5D8;

    // Integer representation of a binary string signifying main item progress
    // Item bit positions correspond to their placements in the inventory menu PLUS ONE
    // (At least that's what was consistent with what I tested:
    // firecracker = 1(2), flute = 2(4), disc = 5(32), wand = 6(64))
    int file1MainItems : 0x02D43958, 0x5F4;

    // Any% end trigger, becomes true when the final time pops on screen after detonation
    // Currently desynced by a frame or so, but should be whatever since final time is displayed anyway
    bool endTrigger : 0xCA9E84, 0x10, 0x28, 0xF68, 0x894;

    // True if game is being played in any file, false if game is in main menu.
    bool isInGame : 0x29A0A04;
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

    settings.Add("ending_group", true, "Split on Endings");

    settings.Add("any_end", true, "Normal (Any%) Ending", "ending_group");
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
    return (settings["item1"] && (current.file1MainItems & 0x2) != 0 && (old.file1MainItems & 0x2) == 0
            || settings["item2"] && (current.file1MainItems & 0x4) != 0 && (old.file1MainItems & 0x4) == 0
            || settings["item3"] && (current.file1MainItems & 0x8) != 0 && (old.file1MainItems & 0x8) == 0
            || settings["item4"] && (current.file1MainItems & 0x10) != 0 && (old.file1MainItems & 0x10) == 0
            || settings["item5"] && (current.file1MainItems & 0x20) != 0 && (old.file1MainItems & 0x20) == 0 && !vars.discTaken
            || settings["item6"] && (current.file1MainItems & 0x40) != 0 && (old.file1MainItems & 0x40) == 0
            || settings["item7"] && (current.file1MainItems & 0x80) != 0 && (old.file1MainItems & 0x80) == 0
            || settings["item8"] && (current.file1MainItems & 0x100) != 0 && (old.file1MainItems & 0x100) == 0
            || settings["item9"] && (current.file1MainItems & 0x200) != 0 && (old.file1MainItems & 0x200) == 0
            || settings["item10"] && (current.file1MainItems & 0x400) != 0 && (old.file1MainItems & 0x400) == 0
            || settings["item11"] && (current.file1MainItems & 0x800) != 0 && (old.file1MainItems & 0x800) == 0
            || settings["item12"] && (current.file1MainItems & 0x1000) != 0 && (old.file1MainItems & 0x1000) == 0
            
            || settings["any_end"] && current.endTrigger && !old.endTrigger);
}

onSplit {
    // If this was the disc split, set discTaken to true.
    vars.discTaken = (current.file1MainItems & 0x20) != 0 && (old.file1MainItems & 0x20) == 0 && !vars.discTaken;
}

isLoading { return true; }

gameTime {
    return TimeSpan.FromSeconds(current.file1Timer / 60.0);
}