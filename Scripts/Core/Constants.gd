extends RefCounted

enum Layer {
    DEFAULT = 0,
    PLAYER = 1,
    ENEMY = 2,
    ENVIRONMENT = 3,
    HITBOX = 4,
    HURTBOX = 5,
    ITEM = 6,
    PROJECTILE = 7,
}

enum Mask {
    PLAYER = 1 << 1,
    ENEMY = 1 << 2,
    ENVIRONMENT = 1 << 3,
    HITBOX = 1 << 4,
    HURTBOX = 1 << 5,
    ITEM = 1 << 6,
    PROJECTILE = 1 << 7,
}

enum DamageType {
    PHYSICAL,
    MAGICAL,
    TRUE,
    FIRE,
    ICE,
    LIGHTNING,
    POISON,
}

enum Element {
    NEUTRAL = 0,
    FIRE = 1,
    ICE = 2,
    LIGHTNING = 3,
    DARK = 4,
    LIGHT = 5,
}

enum Faction {
    PLAYER = 0,
    ENEMY = 1,
    NEUTRAL = 2,
}

const GRAVITY: float = 980.0
const TERMINAL_VELOCITY: float = 1200.0
const TILE_SIZE: int = 16
