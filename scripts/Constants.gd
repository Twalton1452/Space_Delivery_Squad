class_name Constants

## Class for constants that might be reused across scripts
## Avoids circular dependencies and centralizes information

# Tick Rates
const TICK_DROP = 10

# Interactable Constants
const INTERACTABLE = "Interactable"
const ACCEPTABLE_INTERACTABLE_DISTANCE_IN_M = 5
const INTERACTABLE_LAYER = 1 << 2
const NON_INTERACTABLE_LAYER = 0

# Player Constants
const PLAYER_LAYER = 1 << 1

# Connecter Constants
const CONNECTER_GROUP = "Connecters"
const CONNECTER_LAYER = 1 << 0 | 1 << 4

# Power Constants
const POWER_SOURCE = "PowerSource"
const POWER_SOURCE_GROUP = "PowerSources"
const POWER_CONSUMER_GROUP = "PowerConsumers"
