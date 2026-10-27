-- Core initialization and global table
-- /console scriptErrors 1
local addonName, HeroMetrics = ...
_G.HeroMetrics = HeroMetrics

HeroMetricsDB = HeroMetricsDB or {}

HeroMetrics.timeGoal, HeroMetrics.timeOver = 0, 0
HeroMetrics.trackingTimeGoal = false
HeroMetrics.elapsedTime = 0
HeroMetrics.sessionStart = nil
HeroMetrics.timeGoalTicker = nil

HeroMetrics.lastXP = 0
HeroMetrics.startTime = GetTime()
HeroMetrics.lastXPChange = 0
HeroMetrics.previousXPChange = 0
HeroMetrics.iterationsNeeded = 0
HeroMetrics.lastKnownXP = 0
HeroMetrics.soundInterval = 25
HeroMetrics.soundPlayed = false
HeroMetrics.sideSpacing = 10

HeroMetrics.addonStartTime = GetTime()
HeroMetrics.lastNotificationTime = 0
HeroMetrics.lastPlaytimeUpdate = 0

HeroMetrics.lastLevelTime = HeroMetrics.lastLevelTime or 0
HeroMetrics.iterationsPassedCurrent = 0
HeroMetrics.iterationsPassedLast = 0

HeroMetrics.trackingXP = false
HeroMetrics.customXPStart = 0

HeroMetrics.customXPStartTime = 0
HeroMetrics.customXPTimer = nil

HeroMetrics.initialItemLevels = {}
HeroMetrics.previousItemLevels = {}
HeroMetrics.sessionStarted = false
HeroMetrics.previousItemLevels = HeroMetrics.previousItemLevels or {}
HeroMetrics.initialItemLevels = HeroMetrics.initialItemLevels or {}
HeroMetrics.upgradedItems = HeroMetrics.upgradedItems or {}

HeroMetrics.goldNotified = false

HeroMetrics.lowHealthThreshold = 0.5  -- 50%
HeroMetrics.criticalHealthThreshold = 0.3  -- 30%
HeroMetrics.deadThreshold = 0.01 -- 1%