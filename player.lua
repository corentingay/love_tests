
-- Animation
-- actual index into the animation table
-- ending_animation;
-- required condition: all must be met to go into it
-- accepting condition: only one can be met

-- In order to go into the animation, the player must satisfy all
-- required conditions and at least one accepting condition

-- Lookup metatable for `classes`

require "input"

movingLeft = function() return isDown("Left") end
movingRight = function() return isDown("Right") end
canJump = function(player) return (isDown("Jump") and player.y_velocity == 0) end

IdleRightState = {
    nb_frames = 3;
	spritesheet_row = 1; -- index into the spritesheet
	path = "hero.png";
	animation = nil;
	conditions = {
		[function(player) return canJump(player) end] = 4,
		[function() return (movingLeft() and not movingRight()) end] = 2,
		[function() return (movingRight() and not movingLeft()) end] = 3,
	};
	effect = function(player) end;
}

IdleLeftState = {
    nb_frames = 3;
	spritesheet_row = 1; -- index into the spritesheet
	path = "hero_flipped.png";
	animation = nil;
	conditions = {
		[function(player) return canJump(player) end] = 4,
		[function() return (movingLeft() and not movingRight()) end] = 2,
		[function() return (movingRight() and not movingLeft()) end] = 3,
	};
	effect = function(player) end;
}

LeftState = {
    nb_frames = 4;
	spritesheet_row = 2; -- index into the spritesheet
	path = "hero_flipped.png";
	animation = nil;
	conditions = {
		[function() return (not movingLeft() and not movingRight()) end] = 5,
		[function() return (movingLeft() and not movingRight()) end] = 2,
		[function() return (movingRight() and not movingLeft()) end] = 3,
	};
	effect = moveLeft;
}

RightState = {
    nb_frames = 4;
	spritesheet_row = 2; -- index into the spritesheet
	path = "hero.png";
	animation = nil;
	conditions = {
		[function() return (not movingLeft() and not movingRight()) end] = 1,
		[function() return (movingRight() and not movingLeft()) end] = 3,
		[function() return (movingLeft() and not movingRight()) end] = 2,
		-- In that case, maybe we want a special case, like the character turning
		-- around.
	};
	effect = moveRight;
}


JumpState = {
    nb_frames = 1;
	spritesheet_row = 2; -- index into the spritesheet
	path = "hero.png";
	animation = nil;
	conditions = {
		-- We return to idle mode to move left and right
		 --[function() return true end] = 1,
		 [function(player) return canJump(player) end] = 4,
		 [function() return (movingLeft() and not movingRight()) end] = 2,
		 [function() return (movingRight() and not movingLeft()) end] = 3,
	};
	effect = jump;
}

SpriteSheet = {
	animation_state_table = nil;
	path = nil;
}



-- TODO: somehow make animation `inherit` from another ?
-- Example: When attacked, we might want the same state and conditions but with
-- different animations depending if the player is hit mid-air or on the ground.

-- TODO How do we launch projectiles ? Who owns it ?
--		the projectile damages are determined when launching them
-- TODO How do we do timed animation ?
--	IE: If you combo into the next hit at a specific frame, bonus damage
--		Draw a specific example with real sprites (megaman X probably)
--		We switch to a given state temporarily that has special properties
--			IE other following animations
--		Create an editor to simplify the process of editing animations

-- In C++, make all that compile time
-- We have the core of the game that is not recompiled, but changing stuff is
-- IE: I want to change what sprite a given character uses -> it recompiles
--		that part of the code, how do we do that with templates ??
--		How to have a common interface while templates are `different types`
--		Only work with references, then what is holding them ??
--		Do we recompile levels ? -> We have to.
--		What happends when we kill an enemy, who handles the memory ?
--		If we still want to do that, we have to do: - lots of typedefs
--													- lots of macros
-- For example, if 2 mods are not compatible we can detect it at compile time.

-- Global animation set containg all animations
GlobalAnimationTable = {};
GlobalAnimationTable[1] = IdleRightState;
GlobalAnimationTable[5] = IdleLeftState;
GlobalAnimationTable[2] = LeftState;
GlobalAnimationTable[3] = RightState;
GlobalAnimationTable[4] = JumpState;

function init_animation_table(table)
    local start_x = 16;
    local start_y = 16;
    local nb_frames = 4;
	for index, state in pairs(table) do
		state.animation = newSpritesheet(love.graphics.newImage(state.path),
			start_x, start_y, 16, 16, 1/2, state.nb_frames, state.spritesheet_row);
	end
end

-- We could represent all animations `paths` as a directed graph:
-- (walking_state) => jumping
--				   => attacking
--				   => falling
--				   => taking damage

-- A given animation is for a given action (walking left. falling, etc...)
-- Each action is bound to condition and a callback function
-- The condition can be a keybind press or another condition (ex: falling)
-- We only have one condition at a time
-- We have an index in the spritesheet for the given action
-- We have a counter that functions as an index to the current step of the
-- animation.
-- We have a last index for the selected idle animation.
-- 	-> The idle animation can differ based on the previous animation.
-- ANIMATIONS --
-- Terminology:
--	frame_index ->  in the table of the animation for the current frame
--	spritesheet_row -> index to get the table of frames for the current state
--		IE: falling, jumping, going left,...
--
--	In C, we would compute the frame like this:
--		struct frame;
--		frame ** ptr = animation_table
--		frame f = ptr[spritesheet_row][frame_index]

-- TODO We specify the nth line that we take for the animation
function newSpritesheet(image, start_x, start_y, width, height,
                        duration, nb_frames, row)
	local _animation = {}
	_animation.spritesheet = image;
	_animation.quads = {}; --TODO: fix that shit

	print("Image", image)
	print("Creating spritesheet", _animation.spritesheet)

	local y = (row - 1) * height + start_y;

    local frames = 0;
	for x = start_x, image:getWidth() - width - start_x, width do
			print("Test", x, y, width, height);
			table.insert(_animation.quads,
				love.graphics.newQuad(x, y, width, height,
				image:getDimensions()))
            frames = frames + 1;
            if (frames > nb_frames) then
                break;
            end
    end

	_animation.duration = duration or 1
	_animation.currentTime = 0

	print("Table size ", table.getn(_animation.quads))
	print("Returning spritesheet", _animation.spritesheet)
	return _animation
end


