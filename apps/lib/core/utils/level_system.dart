class LevelSystem {
  // Returns the XP difference needed to go from [level] to [level + 1]
  // Pure Fibonacci sequence scaled by 100:
  // Level 1 -> 2: 100 XP
  // Level 2 -> 3: 200 XP
  // Level 3 -> 4: 300 XP
  // Level 4 -> 5: 500 XP
  // Level 5 -> 6: 800 XP
  // Level 6 -> 7: 1300 XP
  // Level 7 -> 8: 2100 XP
  // Level 8 -> 9: 3400 XP...
  static int getXpDiffForLevel(int level) {
    if (level <= 1) return 100;
    if (level == 2) return 200;
    int prev2 = 100;
    int prev1 = 200;
    for (int i = 3; i <= level; i++) {
      int current = prev1 + prev2;
      prev2 = prev1;
      prev1 = current;
    }
    return prev1;
  }

  // Returns the current level based on total cumulative XP
  static int getLevel(int totalXp) {
    if (totalXp < 0) return 1;
    int level = 1;
    int cumulativeXp = 0;
    while (true) {
      int diff = getXpDiffForLevel(level);
      if (totalXp < cumulativeXp + diff) {
        return level;
      }
      cumulativeXp += diff;
      level++;
    }
  }

  // Returns the total XP required to reach the start of this level
  static int getXpForLevelStart(int level) {
    if (level <= 1) return 0;
    int cumulativeXp = 0;
    for (int i = 1; i < level; i++) {
      cumulativeXp += getXpDiffForLevel(i);
    }
    return cumulativeXp;
  }

  // Returns the total XP required to reach the next level
  static int getXpForNextLevel(int level) {
    return getXpForLevelStart(level + 1);
  }

  // Returns the XP required specifically within this level to level up
  static int getXpNeededWithinLevel(int level) {
    return getXpDiffForLevel(level);
  }

  // Returns the XP accumulated within the current level
  static int getXpProgressWithinLevel(int totalXp) {
    final level = getLevel(totalXp);
    final start = getXpForLevelStart(level);
    return totalXp - start;
  }

  // Returns progress as a double between 0.0 and 1.0
  static double getProgressPercentage(int totalXp) {
    final level = getLevel(totalXp);
    final start = getXpForLevelStart(level);
    final diff = getXpDiffForLevel(level);
    if (diff <= 0) return 0.0;
    final currentProgress = totalXp - start;
    return (currentProgress / diff).clamp(0.0, 1.0);
  }
}
