/**
Common enums used accross all modules of the game
*/
module novelcliff.core.enums;

/// Input signal to be received by game controll handler
enum InputSignal
{
	UP_PRESS, UP_RELEASE,
	DOWN_PRESS, DOWN_RELEASE,
	LEFT_PRESS, LEFT_RELEASE,
	RIGHT_PRESS, RIGHT_RELEASE,
	JUMP_PRESS, JUMP_RELEASE,
	USE_PRESS, USE_RELEASE
}

/// Direction that a game object can face
enum Direction
{
    LEFT, RIGHT
}