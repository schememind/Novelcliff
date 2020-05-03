/**
Basic shared types of any game object.
WARNING: Classes of this module should not directly depend on classes from other
         modules of this application, use interfaces instead.
*/
module novelcliff.core.base;

import novelcliff.core.interfaces;
import novelcliff.core.enums;
import std.conv: to;

/**
Common class for any villain.
*/
class Villain : GameObject
{
private:
    int _health;
    size_t[2] healthPixelIndex;

public:
    this(IObjectContainer area, size_t x, size_t y, Direction direction,
         int health, size_t leftHealthPixelIndex, size_t rightHealthPixelIndex)
    {
        super(area, x, y, direction);

        // Health is displayed as a single char, thus it can only be 1 character long
        _health = health > 9 ? 9 : health;
        healthPixelIndex[Direction.LEFT] = leftHealthPixelIndex;
        healthPixelIndex[Direction.RIGHT] = rightHealthPixelIndex;
    }

    @property int health()
    {
        return _health;
    }

    @property void health(int value)
    {
        // Normalize input value. Since health is displayed as a single char,
        // it can only be 1 character long
        if (value > 9)
        {
            value = 9;
        }
        else if (value < 0)
        {
            value = 0;
        }

        // If value is decreased, but the Villain is not yet killed
        if (value < _health && value > 0)
        {
            startBlinking(3, '-');
        }

        _health = value;

        // Render updated health value
        _pixels[Direction.LEFT][healthPixelIndex[Direction.LEFT]]._symbol =
            to!dchar(to!string(_health));
        _pixels[Direction.RIGHT][healthPixelIndex[Direction.RIGHT]]._symbol =
            to!dchar(to!string(_health));
        
        if (_health <= 0)
        {
            killItself;
        }
    }
}

/**
Dynamic object that possesses "living" properties, e.g. health
*/
class LivingObject : GameObject
{
private:
    GameObject _carriedObject;
    int _capacity;
    bool _isPreparedForPick, _isPreparedForDrop;

    // Differency values used for storing differency between original and latest
    // GameObject position in cases of picking other GamoObjects and thus getting
    // their Pixels.
    size_t xDiff, yDiff;

    void pickObject(GameObject carriedObject)
    {
        if (_carriedObject !is null || carriedObject is null)
        {
            return;
        }
        
        // Try to move picked object above the picking object and see if there
        // are any obstacles.
        size_t carriedObjectInitialY = carriedObject.y;
        Pixel collidedPixel;
        for (size_t pickY = carriedObject.y - 1;
                pickY >= y - carriedObject.height[direction];
                pickY--)
        {
            collidedPixel = carriedObject.setPosition(
                carriedObject.x,
                pickY,
                true,
                this
            );
            if (collidedPixel !is null)
            {
                if (collidedPixel.parent == this)
                {
                    collidedPixel = null;
                }
                else
                {
                    // If it is not possible to pick up GameObject due to
                    // collision with other GameObject (except the one that picks
                    // it up), bring carried object back to its initial Y position
                    carriedObject.setPosition(
                        carriedObject.x,
                        carriedObjectInitialY,
                        false
                    );
                    break;
                }
            }
        }

        if (collidedPixel is null)
        {
            // All clear to pick up an object, no obstacles detected:

            // Move main object's position to picked object's position
            yDiff = y - carriedObject.y;
            y = carriedObject.y;
            xDiff = x - carriedObject.x;
            if (xDiff > 0)
            {
                x = carriedObject.x;
            }

            // Lower all current main object's relative Pixel positions
            foreach (ref Pixel pixel; _pixels[Direction.LEFT])
            {
                pixel.relY += carriedObject.height[Direction.LEFT];
                if (xDiff > 0)
                {
                    pixel.relX += xDiff;
                }
            }
            foreach (ref Pixel pixel; _pixels[Direction.RIGHT])
            {
                pixel.relY += carriedObject.height[Direction.RIGHT];
                if (xDiff > 0)
                {
                    pixel.relX += xDiff;
                }
            }

            // Take ownership of picked object Pixels
            foreach (ref Pixel pixel; carriedObject._pixels[Direction.LEFT])
            {
                pixel.parent = this;
            }
            foreach (ref Pixel pixel; carriedObject._pixels[Direction.RIGHT])
            {
                pixel.parent = this;
            }
            _pixels[Direction.LEFT] ~= carriedObject._pixels[Direction.LEFT];
            _pixels[Direction.RIGHT] ~= carriedObject._pixels[Direction.RIGHT];
            carriedObject._pixels[Direction.LEFT] = [];
            carriedObject._pixels[Direction.RIGHT] = [];

            // Set picked object as carrried object of this game object
            _carriedObject = carriedObject;

            recalculateProperties;

            _area.makeTransferableStatic(_carriedObject);
        }
        else
        {
            // Not possible to pick up an object due to obstacles
            _area.turnIntoUpdatable(collidedPixel.parent);
            _area.turnIntoUpdatable(carriedObject);
            collidedPixel.parent.startBlinking(2, '-');
            carriedObject.startBlinking(2, '-');
            // TODO turn both objects back to static
        }
    }

    void dropObject()
    {
        // Variables to store indexes of first carried object's Pixels
        size_t leftFirstCarriedPixelIndex = 0;
        size_t rightFirstCarriedPixelIndex = 0;

        // Give ownership of picked object Pixels back to picked object
        foreach (size_t index, ref Pixel pixel; _pixels[Direction.LEFT])
        {
            if (pixel.originalParent == _carriedObject)
            {
                pixel.parent = _carriedObject;
                if (leftFirstCarriedPixelIndex == 0)
                {
                    leftFirstCarriedPixelIndex = index;
                }
            }
        }
        foreach (size_t index, ref Pixel pixel; _pixels[Direction.RIGHT])
        {
            if (pixel.originalParent == _carriedObject)
            {
                pixel.parent = _carriedObject;
                if (rightFirstCarriedPixelIndex == 0)
                {
                    rightFirstCarriedPixelIndex = index;
                }
            }
        }
        _carriedObject._pixels[Direction.LEFT] ~= _pixels[Direction.LEFT][leftFirstCarriedPixelIndex..$];
        _carriedObject._pixels[Direction.RIGHT] ~= _pixels[Direction.RIGHT][rightFirstCarriedPixelIndex..$];
        _pixels[Direction.LEFT] = _pixels[Direction.LEFT][0..leftFirstCarriedPixelIndex];
        _pixels[Direction.RIGHT] = _pixels[Direction.RIGHT][0..rightFirstCarriedPixelIndex];

        // Place carried object (that was previously left at its place without
        // Pixels) at the current position
        _carriedObject.x = x;
        _carriedObject.y = y;
        _carriedObject._direction = _direction; 

        // Reset back X and Y postion to original values
        x += xDiff;
        y += yDiff;
        foreach (ref Pixel pixel; _pixels[Direction.LEFT])
        {
            pixel.relY -= yDiff;
            if (xDiff > 0)
            {
                pixel.relX -= xDiff;
            }
        }
        foreach (ref Pixel pixel; _pixels[Direction.RIGHT])
        {
            pixel.relY -= yDiff;
            if (xDiff > 0)
            {
                pixel.relX -= xDiff;
            }
        }

        // Prepare carried object to be thrown in the next game loop iteration
        _carriedObject.startThrowingItself(2);

        _area.removeFromTransferableStatic(_carriedObject);
        
        // Reset carried object to null
        _carriedObject = null;

        recalculateProperties;
    }

public:
    this(IObjectContainer area, size_t x, size_t y, Direction direction,
         int capacity)
    {
        super(area, x, y, direction);
        _capacity = capacity;
    }

    override void update()
    {
        super.update;

        // Handle object picking
        if (_isPreparedForPick && _yCollidedPixel !is null)
        {
            // TODO not sure if this casting is efficient
            pickObject(_yCollidedPixel.parent);
        }

        // Handle object dropping
        if (_isPreparedForDrop && _carriedObject !is null)
        {
            dropObject;
        }

        // Reset preparedForPick status every frame to prevent cases when
        // this status is set during a free fall and after multiple update
        // cycles, when game object is landed on another object, this object
        // gets picked automatically.
        _isPreparedForPick = false;
        _isPreparedForDrop = false;
    }

    /**
    Depending on whether object is currently "carrying" another one, prepare
    object to start picking or dropping in the next iteration of the game loop.
    */
    void prepareToPickOrDrop()
    {
        _isPreparedForPick = (_carriedObject is null);
        _isPreparedForDrop = !(_carriedObject is null);
    }

    /**
    Return GameObject that is currently being "carried" by this GameObject
    */
    @property GameObject carriedObject()
    {
        return _carriedObject;
    }
}

/**
Game object that has position, dimensions, direction and consists of symbols (characters)
*/
class GameObject
{
private:
    // Current position at any given moment
    size_t x, y;

    // It is possible for an object to have different set of pixels
    // (and different dimensions) in different positions:
    // width[0] for width when in LEFT direction,
    // width[1] for width when in RIGHT direction.
    size_t[2] width, height;

    Direction _direction;
    
    // Two dynamic arrays of Pixels as a single array:
    // _pixels[0] for all LEFT direction Pixels,
    // _pixels[1] for all RIGHT direction Pixels.
    Pixel[][2] _pixels;

    // Area which GameObject belongs to
    IObjectContainer _area;

    // Handlers
    WalkHandler _walkHandler;
    JumpHandler _jumpHandler;
    ThrowHandler _throwHandler;
    BlinkHandler _blinkHandler;
    ScheduleHandler _scheduleHandler;
    bool _isOnGround;

    // Pixels of other GameObjects that current GameObject is colliding with
    Pixel _xCollidedPixel, _yCollidedPixel;

    // For objects affected by the laws of physics gravity should be 1, for other
    // objects (like words) it can be 0, so that such objects do not fall down
    size_t _gravity, _initialGravity;
    
public:
    this(IObjectContainer area, size_t x, size_t y, Direction direction,
         size_t gravity=1)
    {
        this._area = area;
        this.x = x;
        this.y = y;
        this.direction = direction;
        this._gravity = gravity;
        this._initialGravity = gravity;
        _walkHandler = new WalkHandler(this);
        _jumpHandler = new JumpHandler(this);
        _throwHandler = new ThrowHandler(this);
        _blinkHandler = new BlinkHandler(this);
        _scheduleHandler = new ScheduleHandler(this);
    }

    /**
    Add Pixel to the GameObject. Pixel would later be used for rendering
    when GameObject is facing the specified direction. 
    */
    void addPixel(dchar symbol, size_t relX, size_t relY, Direction direction)
    {
        _pixels[direction] ~= new Pixel(symbol, this, relX, relY);
    }

    /**
    Recalculate width and height (to be called after Pixel position manipulation)
    */
    void recalculateProperties()
    {
        width[Direction.LEFT] = 0;
        width[Direction.RIGHT] = 0;
        height[Direction.LEFT] = 0;
        height[Direction.RIGHT] = 0;

        foreach (ref Pixel leftPixel; _pixels[Direction.LEFT])
        {
            if (leftPixel.relX > width[Direction.LEFT])
            {
                width[Direction.LEFT] = leftPixel.relX;
            }
            if (leftPixel.relY > height[Direction.LEFT])
            {
                height[Direction.LEFT] = leftPixel.relY;
            }
        }
        foreach (ref Pixel rightPixel; _pixels[Direction.RIGHT])
        {
            if (rightPixel.relX > width[Direction.RIGHT])
            {
                width[Direction.RIGHT] = rightPixel.relX;
            }
            if (rightPixel.relY > height[Direction.RIGHT])
            {
                height[Direction.RIGHT] = rightPixel.relY;
            }
        }

        width[Direction.LEFT]++;
        height[Direction.LEFT]++;
        width[Direction.RIGHT]++;
        height[Direction.RIGHT]++;
    }

    Pixel setPosition(size_t newX, size_t newY, bool isCheckCollision,
                        GameObject ignoredObject = null)
    {
        if (newX == size_t.max
            || newX + width[_direction] >= _area.game.renderer.pixelGrid.length
            || newY == size_t.max
            || newY + height[_direction] >= _area.game.renderer.pixelGrid[0].length + 1)
        {
            // Checking renderer borders:
            // size_t.max because 0 - 1 != -1 for an unsigned type
            return null;
        }

        Pixel anotherPixel = null;

        // Loop through pixels,
        // set their preliminary new position and check for collision
        foreach (ref Pixel pixel; _pixels[direction])
        {
            anotherPixel = pixel.setPosition(
                newX + pixel.relativeX,
                newY + pixel.relativeY,
                isCheckCollision,
                ignoredObject
            );
            if (isCheckCollision && anotherPixel !is null)
            {
                // Collision check is required and collision has been detected:
                // no need to check the rest of the Pixels
                break;
            }
        }

        if (isCheckCollision && anotherPixel !is null)
        {
            // Collision detected:
            // revert all Pixels that have already had their position updated
            foreach (ref Pixel pixel; _pixels[direction])
            {
                if (pixel.isModified)
                {
                    pixel.x = pixel.previousX;
                    pixel.y = pixel.previousY;
                    pixel.isModified = false;
                }
                else
                {
                    // If Pixel is not modified, that means that previous loop
                    // did not go past it
                    break;
                }
            }
        }
        else
        {
            // All Pixels checked, collision is either not required
            // or not detected, all Pixels have been moved to new position.
            x = newX;
            y = newY;
        }

        return anotherPixel;
    }

    /**
    Copy Pixels of one Direction to another Direction either with mirroring or not
    */
    void copyPixelsBetweenDirections(Direction fromDirection, Direction toDirection,
                                     bool isMirror)
    {
        foreach (ref Pixel pixel; _pixels[fromDirection])
        {
            if (isMirror)
            {
                // TODO calculate opposite relative position + char substitution
            }
            else
            {
                addPixel(pixel.symbol, pixel.relX, pixel.relY, toDirection);
            }
        }
    }

    /// Update position and state
    void update()
    {
        // Reset collision, it would be set again a few lines below
        _xCollidedPixel = null;
        _yCollidedPixel = null;

        // Handle horizontal movement
        if (isMovingHorizontally)
        {
            _xCollidedPixel = setPosition(
                x + _walkHandler.calculateCoefficient,
                y,
                true
            );
        }

        // Apply gravity
        _yCollidedPixel = setPosition(
            x,
            y
                + _gravity    // gravity
                - _jumpHandler.calculateCoefficient
                - _throwHandler.calculateCoefficient,
            true
        );

        // Detect whether GameObject is on a "ground"
        _isOnGround = _yCollidedPixel !is null
                        && !cast(Villain)_yCollidedPixel.parent
                        && !_yCollidedPixel.parent.isThrownWeapon
        ;

        // Update jumping cycle
        _jumpHandler.update;

        // Update blinking cycle
        _blinkHandler.update;

        // Collision effect
        if (_xCollidedPixel !is null)
        {
            _area.handleCollision(this, _xCollidedPixel.parent);
        }
        if (_yCollidedPixel !is null)
        {
            _area.handleCollision(this, _yCollidedPixel.parent);
        }

        // Update self-throwing cycle
        _throwHandler.update;

        // Update scheduled ticks and execute any scheduled action (if any)
        _scheduleHandler.update;
    }

    /// Start jumping process
    void startJump(uint height)
    {
        _jumpHandler.startJump(height);
    }

    /// Start self-throwing process
    void startThrowingItself(uint height)
    {
        _throwHandler.startThrowingItself(height);
    }

    /// Start blinking with the given symbol N times
    void startBlinking(uint cycles, dchar blinkSymbol)
    {
        _blinkHandler.startBlinking(cycles, blinkSymbol);
    }

    /// Strip GameObject off its pixels
    void remove()
    {
        foreach (ref Pixel pixel; _pixels[Direction.LEFT])
        {
            pixel._isVisible = false;
            pixel.isCollisionResponsive = false;
        }
        foreach (ref Pixel pixel; _pixels[Direction.RIGHT])
        {
            pixel._isVisible = false;
            pixel.isCollisionResponsive = false;
        }
    }

    /// Remove itself with freezing, blinking and removing
    void killItself(uint blinkCycles=3)
    {
        foreach (ref Pixel pixel; _pixels[Direction.LEFT])
        {
            pixel.isCollisionResponsive = false;
        }
        foreach (ref Pixel pixel; _pixels[Direction.RIGHT])
        {
            pixel.isCollisionResponsive = false;
        }
        _walkHandler.isMovingHorizontally = false;
        _jumpHandler.jumpCycle = 0;
        _throwHandler.throwCycle = 0;
        _throwHandler.throwPhase = 0;
        _scheduleHandler.voidAction = null;
        _gravity = 0;
        startBlinking(blinkCycles, '-');
        schedule(blinkCycles * 2, delegate() { remove; });
    }

    /// Schedule provided void method execution after provided ticks
    void schedule(uint ticks, void delegate() voidAction)
    {
        _scheduleHandler.scheduleActionAfterTicks(ticks, voidAction);
    }

    /// Returns status of object's horizontal movement
    @property bool isMovingHorizontally()
    {
        return _walkHandler.isMovingHorizontally;
    }

    /// Set status of object's horizontal movement
    @property void isMovingHorizontally(bool isMovingHorizontally)
    {
        _walkHandler.isMovingHorizontally = isMovingHorizontally;
    }

    @property size_t getX()
    {
        return x;
    }

    @property size_t getY()
    {
        return y;
    }

    @property size_t getWidth(Direction direction)
    {
        return width[direction];
    }

    @property size_t getHeight(Direction direction)
    {
        return height[direction];
    }

    /// Get array of Pixels based on current direction of the GameObject
    @property Pixel[] pixels()
    {
        return _pixels[direction];
    }

    /// Get direction of the GameObject
    @property Direction direction()
    {
        return _direction;
    }

    /// Set direction of the GameObject
    @property void direction(Direction direction)
    {
        _direction = direction;
        setPosition(x, y, false);
    }

    /// Return Area which GameObject belongs to
    @property IObjectContainer area()
    {
        return _area;
    }

    /// Set Area which GameObject belongs to
    @property void area(IObjectContainer value)
    {
        _area = value;
    }

    /// Returns true if game object is currently in the state of throwing
    @property bool isThrownWeapon()
    {
        return _throwHandler.isWeapon;
    }

    /// Returns true if GameObject is currently blinking
    @property bool isBlinking()
    {
        return _blinkHandler.blinkCycle > 0;
    }
}

/**
Part of GameObject representing one particular symbol (character)
*/
class Pixel
{
private:
    dchar _symbol;
    size_t x, y;
    size_t previousX, previousY;
    size_t relX, relY;
    bool _isVisible;
    bool isCollisionResponsive;
    bool isModified;

    // Used to reference current owner of the Pixel. Can change during the game. 
    GameObject parent;

    // Used to "remember" the original GameObject when ownership of the Pixel
    // is passed to another GameObject (e.g. picking up an object by another object).
    // Should not change during the game!
    const GameObject originalParent;

    @property size_t relativeX()
    {
        return relX;
    }

    @property void relativeX(size_t relX)
    {
        this.relX = relX;
        x = parent.x + relX;
    }

    @property size_t relativeY()
    {
        return relY;
    }

    @property void relativeY(size_t relY)
    {
        this.relY = relY;
        y = parent.y + relY;
    }

public:
    this(dchar symbol, GameObject parent, size_t pRelX, size_t pRelY)
    {
        this._symbol = symbol;
        this.parent = parent;
        this.originalParent = parent;
        this.relativeX = pRelX;
        this.relativeY = pRelY;
        previousX = x;
        previousY = y;
        _isVisible = true;
        isCollisionResponsive = true;
        isModified = false;
    }

    /**
    Set position of the Pixel to provided new coordinates and return Pixel of
    another object that already occupies new position (if any).
    New position is not set if Pixel of another object exists at new poistion
    and it is collision responsive.
    One GameObject can be passed as ignoredObject (null by default) in order to
    ignore collision with that GameObject.
    */
    Pixel setPosition(size_t newX, size_t newY, bool isCheckCollision,
                        GameObject ignoredObject = null)
    {
        Pixel anotherPixel = parent._area.game.renderer.pixelGrid[newX][newY];

        if (isCheckCollision)
        {
            if (anotherPixel is null
                    || anotherPixel.parent == parent
                    || (ignoredObject !is null && anotherPixel.parent == ignoredObject)
                    || !anotherPixel.isCollisionResponsive)
            {
                // Collision checked but not detected:
                // Set new position and "remember" the previous one
                // for a possible rollback if any other Pixel of the same object
                // collides with anoher object's Pixel.
                previousX = x;
                previousY = y;
                x = newX;
                y = newY;
                isModified = true;
                return null;
            }
            // Collision checked and detected: do not set new position
            isModified = false;
        }
        else
        {
            // Collision check not required: set new position
            x = newX;
            y = newY;
            isModified = false;
        }


        return anotherPixel;
    }

    /// Return absolute x position (relative to Renderer's 0,0 coordinate)
    @property size_t absoluteX()
    {
        return x;
    }

    /// Return absolute y position (relative to Renderer's 0,0 coordinate)
    @property size_t absoluteY()
    {
        return y;
    }

    /// Return symbol (character) that visually represents the Pixel
    @property dchar symbol()
    {
        if (parent._blinkHandler.blinkCycle > 0
                && parent._blinkHandler.blinkPhase)
        {
            return parent._blinkHandler.blinkSymbol;
        }
        else
        {
            return _symbol;
        }
    }

    /**
    Return visibility state of the Pixel.
    TODO: For some reason marking this method as property breaks the functionality.
    */
    bool isVisible()
    {
        return _isVisible;
    }
}


//============//
//  Handlers  //
//============//


private class WalkHandler
{
private:
    bool isMovingHorizontally;
    GameObject parent;

public:
    this(GameObject gameObject)
    {
        isMovingHorizontally = false;
        parent = gameObject;
    }

    size_t calculateCoefficient()
    {
        if (isMovingHorizontally)
        {
            return parent._direction == Direction.LEFT ? -1 : 1;
        }
        return 0;
    }
}

private class JumpHandler
{
private:
    uint jumpCycle;
    GameObject parent;

public:
    this(GameObject gameObject)
    {
        jumpCycle = 0;
        parent = gameObject;
    }

    size_t calculateCoefficient()
    {
        return jumpCycle > 0 ? 2 : 0;
    }

    void startJump(uint height)
    {
        if (height < 1 || !parent._isOnGround || jumpCycle > 0)
        {
            return;
        }

        jumpCycle = height;
    }

    void update()
    {
        if (jumpCycle > 0)
        {
            if (parent._yCollidedPixel !is null
                    && parent._yCollidedPixel.y < parent.y)
            {
                // Stop jumping progress if "ceiling" is hit with a head
                jumpCycle = 0;
            }
            else
            {
                // Otherwise continue to the next jumping cycle
                jumpCycle--;
            }
        }
    }
}

private class ThrowHandler
{
private:
    static throwingCoef = 3;

    uint throwCycle, initialCycles, throwPhase;
    bool isPreviouslyStatic;

    // When throwCycle reaches 0 thrown body still keeps falling down
    // and should still be considered dangerous
    bool isWeapon;

    GameObject parent;

public:
    this(GameObject gameObject)
    {
        throwCycle = 0;
        throwPhase = 0;
        parent = gameObject;
    }

    size_t calculateCoefficient()
    {
        return throwCycle > 0
                    ? throwPhase == 1
                        ? throwCycle % throwingCoef == 0
                            ? 2
                            : 1
                        : throwCycle % throwingCoef == 0
                            ? 0
                            : 1
                    : 0;
    }

    void update()
    {
        if (throwCycle > 0)
        {
            if (parent._xCollidedPixel !is null
                    || parent._yCollidedPixel !is null)
            {
                parent._walkHandler.isMovingHorizontally = false;
                throwCycle = 0;
                throwPhase = 2;
            }
            else
            {
                throwCycle--;
            }
        }
        else
        {
            if (throwPhase == 1)
            {
                throwPhase = 2;
                throwCycle = initialCycles;
            }
            else if (throwPhase > 1)
            {
                if (parent._isOnGround)
                {
                    stopThrowingProgress;
                }
                else
                {
                    parent._walkHandler.isMovingHorizontally = false;
                }
            }
        }
    }

    void startThrowingItself(uint height)
    {
        isPreviouslyStatic = parent._area.turnIntoUpdatable(parent);
        throwCycle = height * throwingCoef;
        initialCycles = height * throwingCoef;
        throwPhase = 1;
        parent._gravity = 1;
        parent._walkHandler.isMovingHorizontally = true;
        isWeapon = true;
    }

    void stopThrowingProgress()
    {
        // Stop self-throwing
        parent._walkHandler.isMovingHorizontally = false;
        throwCycle = 0;
        throwPhase = 0;
        isWeapon = false;
        if (parent._initialGravity == 0)
        {
            parent._gravity = 0;
            parent._area.turnIntoStatic(parent);
            isPreviouslyStatic = false;
        }
    }
}

private class BlinkHandler
{
private:
    GameObject parent;
    uint blinkCycle;
    bool blinkPhase;
    dchar blinkSymbol;
    bool isBlinkRunning;

public:
    this(GameObject gameObject)
    {
        parent = gameObject;
        blinkPhase = false;
        isBlinkRunning = false;
    }

    void startBlinking(uint cycles, dchar blinkSymbol)
    {
        blinkCycle = cycles;
        this.blinkSymbol = blinkSymbol;
        isBlinkRunning = true;
    }

    void update()
    {
        if (blinkCycle > 0)
        {
            if (blinkPhase)
            {
                blinkCycle--;
            }
            blinkPhase = !blinkPhase;
        }
        else
        {
            if (isBlinkRunning && parent._initialGravity == 0)
            {
                parent._area.turnIntoStatic(parent);
                isBlinkRunning = false;
            }
        }
    }
}

private class ScheduleHandler
{
private:
    GameObject parent;
    int ticks;
    void delegate() voidAction;

public:
    this(GameObject gameObject)
    {
        parent = gameObject;
        ticks = -1;
    }

    void scheduleActionAfterTicks(uint ticks, void delegate() action)
    {
        this.ticks = ticks;
        this.voidAction = action;
    }

    void update()
    {
        if (ticks > -1)
        {
            ticks--;
        }
        if (ticks == 0)
        {
            if (voidAction !is null)
            {
                voidAction();
            }
        }
    }
}


//=========//
//  Items  //
//=========//

/**
Collectable coin
*/
class Coin : GameObject
{
private:
    static dchar[] animationSymbols = [ '|', '/', '-', '\\' ];
    size_t frameId;

public:
    this(IObjectContainer area, size_t x, size_t y, size_t startFrame=0)
    {
        super(area, x, y, Direction.RIGHT);
        frameId = startFrame;
        addPixel(animationSymbols[0], 0, 0, Direction.RIGHT);
        addPixel(animationSymbols[0], 0, 0, Direction.LEFT);
        recalculateProperties;
    }

    override void update()
    {
        super.update;

        _pixels[_direction][0]._symbol = animationSymbols[frameId];

        frameId++;
        if (frameId >= animationSymbols.length)
        {
            frameId = 0;
        }
    }
}

/**
Player's house that a player needs to reach in order to finish a game
*/
class House : GameObject
{
public:
    this(IObjectContainer area, size_t x, size_t y)
    {
        super(area, x, y, Direction.RIGHT);
        addPixel('_', 2, 0, Direction.RIGHT);
        addPixel('_', 3, 0, Direction.RIGHT);
        addPixel('_', 4, 0, Direction.RIGHT);
        addPixel('_', 5, 0, Direction.RIGHT);
        addPixel('_', 6, 0, Direction.RIGHT);
        addPixel('_', 7, 0, Direction.RIGHT);
        addPixel('=', 8, 0, Direction.RIGHT);
        addPixel('=', 9, 0, Direction.RIGHT);
        addPixel('/', 1, 1, Direction.RIGHT);
        addPixel('\\', 8, 1, Direction.RIGHT);
        addPixel('|', 9, 1, Direction.RIGHT);
        addPixel('/', 0, 2, Direction.RIGHT);
        addPixel('\\', 9, 2, Direction.RIGHT);
        addPixel('\"', 0, 3, Direction.RIGHT);
        addPixel('-', 1, 3, Direction.RIGHT);
        addPixel('-', 2, 3, Direction.RIGHT);
        addPixel('-', 3, 3, Direction.RIGHT);
        addPixel('-', 4, 3, Direction.RIGHT);
        addPixel('-', 5, 3, Direction.RIGHT);
        addPixel('-', 6, 3, Direction.RIGHT);
        addPixel('-', 7, 3, Direction.RIGHT);
        addPixel('-', 8, 3, Direction.RIGHT);
        addPixel('\"', 9, 3, Direction.RIGHT);
        addPixel('|', 0, 4, Direction.RIGHT);
        addPixel('[', 2, 4, Direction.RIGHT);
        addPixel(']', 3, 4, Direction.RIGHT);
        addPixel('[', 5, 4, Direction.RIGHT);
        addPixel(']', 6, 4, Direction.RIGHT);
        addPixel('|', 9, 4, Direction.RIGHT);
        addPixel('|', 0, 5, Direction.RIGHT);
        addPixel('_', 1, 5, Direction.RIGHT);
        addPixel('_', 2, 5, Direction.RIGHT);
        addPixel('_', 3, 5, Direction.RIGHT);
        addPixel('_', 4, 5, Direction.RIGHT);
        addPixel('_', 5, 5, Direction.RIGHT);
        addPixel('_', 6, 5, Direction.RIGHT);
        addPixel('_', 7, 5, Direction.RIGHT);
        addPixel('_', 8, 5, Direction.RIGHT);
        addPixel('|', 9, 5, Direction.RIGHT);
        recalculateProperties;
    }
}

class Sword : Villain
{
private:
    size_t _minX, _maxX;

public:
    this(IObjectContainer area, size_t x, size_t y, Direction direction,
         size_t minX, size_t maxX)
    {
        super(area, x, y, direction, 1, 7, 0);
        addPixel(to!dchar(to!string(_health)), 0, 0, Direction.RIGHT);
        addPixel('~', 1, 0, Direction.RIGHT);
        addPixel('{', 2, 0, Direction.RIGHT);
        addPixel('=', 3, 0, Direction.RIGHT);
        addPixel('=', 4, 0, Direction.RIGHT);
        addPixel('=', 5, 0, Direction.RIGHT);
        addPixel('=', 6, 0, Direction.RIGHT);
        addPixel('>', 7, 0, Direction.RIGHT);
        addPixel('<', 0, 0, Direction.LEFT);
        addPixel('=', 1, 0, Direction.LEFT);
        addPixel('=', 2, 0, Direction.LEFT);
        addPixel('=', 3, 0, Direction.LEFT);
        addPixel('=', 4, 0, Direction.LEFT);
        addPixel('}', 5, 0, Direction.LEFT);
        addPixel('~', 6, 0, Direction.LEFT);
        addPixel(to!dchar(to!string(_health)), 7, 0, Direction.LEFT);
        recalculateProperties;
        _minX = minX;
        _maxX = maxX;
        isMovingHorizontally = true;
    }

    override void update()
    {
        super.update;
        startJump(4);
        if (x <= _minX || _xCollidedPixel !is null || x == 0)
        {
            direction = Direction.RIGHT;
        }
        else if (x >= _maxX || _xCollidedPixel !is null
                || x + width[_direction] >= _area.game.renderer.pixelGrid.length - 1)
        {
            direction = Direction.LEFT;
        }
    }
}