extends Node

enum MoveState { STATIC, TURNING }

enum GameState{ EXPLORING, COMBAT, EDITING }

const STRAFE_LEFT := Vector2i.ZERO
const STRAFE_RIGHT := Vector2i.ONE
const DIR_DOWN := Vector2i.DOWN
const DIR_UP := Vector2i.UP
const DIR_LEFT := Vector2i.LEFT
const DIR_RIGHT := Vector2i.RIGHT
