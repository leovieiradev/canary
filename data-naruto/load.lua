-- Get directory paths from configuration
NARUTO_DATA_DIRECTORY = configManager.getString(configKeys.DATA_DIRECTORY)
NARUTO_CORE_DIRECTORY = configManager.getString(configKeys.CORE_DIRECTORY)
-- Load clan-specific systems
dofile(NARUTO_DATA_DIRECTORY .. "/scripts/uchiha/lib/animation_jutsus.lua")
dofile(NARUTO_DATA_DIRECTORY .. "/scripts/uchiha/lib/extra_functions.lua")
dofile(NARUTO_DATA_DIRECTORY .. "/scripts/uchiha/lib/spell_animation.lua")

logger.info("Loading systems Shin Online")