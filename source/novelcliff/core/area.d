/**
Container of GameObjects for a particular part of the game file + game logic
*/
module novelcliff.core.area;

import novelcliff.core.base;
import novelcliff.core.interfaces;
import novelcliff.core.enums;

/**
Container of GameObjects for a particular part of the game file + game logic
*/
class Area : IObjectContainer
{
private:
    // Reference to the game containing a list of Areas, including this one
    IAreaListContainer _game;

    // Reference to a single player object created in Game class,
    // so it means that each Area shares the same player!
    LivingObject _player;

    // List of dynamic objects, except the player.
    // These objects require update in each iteration of the game loop.
    GameObject[] _updatableObjects;

    // List of static objects (e.g. words)
    // These objects are not updated in each iteration of the game loop, thus
    // not using processor power.
    GameObject[] _staticObjects;

    // List of static objects, that are transferred to other Areas together with
    // the player. This is used primarily for carried words, that a player can
    // carry to another Area and throw it there.
    GameObject[] _transferableStaticObjects;

    /// List of updatable animated coins
    Coin[] _coins;

    /// List of updatable villains
    Villain[] _villains;

    // Y coordinate of the bottom row of the Area
    size_t _bottomY;

    // Indicates whether this Area is the first/last one in the list of game Areas.
    bool _isFirst, _isLast;

    // Probabilities
    float _coinProbability, _swordProbability, _spiderProbability;

    /**
    Find suitable Slots based on given size and condition functions executed on
    every side of the slot.
    Condition function parameters: x, y at which condition should be checked,
    as well as the boolean value indicating whether condition is mandatory for
    ALL coordinates of the particular side (true) or ANY (at least one) (false).
    */
    Slot[] findSuitableSlots(
        size_t yFrom, size_t yTo, size_t requiredWidth, size_t requiredHeight,
        bool delegate(size_t, size_t) topCondition,
        bool isTopConditionMandatoryForAll,
        bool delegate(size_t, size_t) rightCondition,
        bool isRightConditionMandatoryForAll,
        bool delegate(size_t, size_t) bottomCondition,
        bool isBottomConditionMandatoryForAll,
        bool delegate(size_t, size_t) leftCondition,
        bool isLeftConditionMandatoryForAll)
    {
        Slot[] result = [];

        // Fill renderer's pixel grid with existing objects, so that we can
        // analyze free pixels
        _game.renderer.clear;
        renderAllObjects;

        for (size_t y = yFrom; y < yTo - 1; y++)
        {
            for (size_t x = 1; x < _game.renderer.pixelGrid.length - 1; x++)
            {
                if (_game.renderer.pixelGrid[x][y] is null)
                {
                    // Empty pixel found: check whether rectangle with the given
                    // requiredWidth and requiredHeight can fit at this position
                    // as top-left X and Y.
                    bool isSuitable = true;
                    bool isTopConditionMet = false;
                    bool isBottomConditionMet = false;
                    bool isLeftConditionMet = false;
                    bool isRightConditionMet = false;

                    currentSlotAnalysis:
                    for (size_t innerY = y; innerY < y + requiredHeight; innerY++)
                    {
                        if (innerY > yTo)
                        {
                            isSuitable = false;
                            break currentSlotAnalysis;
                        }
                        for (size_t innerX = x; innerX < x + requiredWidth; innerX++)
                        {
                            if (innerX >= _game.renderer.pixelGrid.length
                                || _game.renderer.pixelAt(x, y) !is null)
                            {
                                isSuitable = false;
                                break currentSlotAnalysis;
                            }

                            // Check condition above the UPPER side of the Slot
                            if (innerY == y
                                && !isTopConditionMet)
                            {
                                if (topCondition(innerX, innerY))
                                {
                                    // If at least one position check is required
                                    // to fulfil the condition, the entire condition
                                    // counts matched.
                                    isTopConditionMet = !isTopConditionMandatoryForAll;
                                }
                                else
                                {
                                    if (isTopConditionMandatoryForAll)
                                    {
                                        // The entire condition fails since it
                                        // was mandatory for all positions
                                        // along the current side of the Slot.
                                        isSuitable = false;
                                        break currentSlotAnalysis;
                                    }
                                    else
                                    {
                                        if (innerX == x + requiredWidth - 1)
                                        {
                                            // Checked all positions along the
                                            // current horizontal side of the Slot -
                                            // non of them matches the condition.
                                            isSuitable = false;
                                            break currentSlotAnalysis;
                                        }
                                    }
                                }
                            }

                            // Check condition below the BOTTOM side of the Slot
                            if (innerY == y + requiredHeight - 1
                                && !isBottomConditionMet)
                            {
                                if (bottomCondition(innerX, innerY))
                                {
                                    // If at least one position check is required
                                    // to fulfil the condition, the entire condition
                                    // counts matched.
                                    isBottomConditionMet = !isBottomConditionMandatoryForAll;
                                }
                                else
                                {
                                    if (isBottomConditionMandatoryForAll)
                                    {
                                        // The entire condition fails since it
                                        // was mandatory for all positions
                                        // along the current side of the Slot.
                                        isSuitable = false;
                                        break currentSlotAnalysis;
                                    }
                                    else
                                    {
                                        if (innerX == x + requiredWidth - 1)
                                        {
                                            // Checked all positions along the
                                            // current horizontal side of the Slot -
                                            // non of them matches the condition.
                                            isSuitable = false;
                                            break currentSlotAnalysis;
                                        }
                                    }
                                }
                            }

                            // Check condition to the LEFT of the Slot
                            if (innerX == x
                                && !isLeftConditionMet)
                            {
                                if (leftCondition(innerX, innerY))
                                {
                                    // If at least one position check is required
                                    // to fulfil the condition, the entire condition
                                    // counts matched.
                                    isLeftConditionMet = !isLeftConditionMandatoryForAll;
                                }
                                else
                                {
                                    if (isLeftConditionMandatoryForAll)
                                    {
                                        // The entire condition fails since it
                                        // was mandatory for all positions
                                        // along the current side of the Slot.
                                        isSuitable = false;
                                        break currentSlotAnalysis;
                                    }
                                    else
                                    {
                                        if (innerY == y + requiredHeight - 1)
                                        {
                                            // Checked all positions along the
                                            // current vertical side of the Slot -
                                            // non of them matches the condition.
                                            isSuitable = false;
                                            break currentSlotAnalysis;
                                        }
                                    }
                                }
                            }

                            // Check condition to the RIGHT of the Slot
                            if (innerX == x + requiredWidth - 1
                                && !isRightConditionMet)
                            {
                                if (rightCondition(innerX, innerY))
                                {
                                    // If at least one position check is required
                                    // to fulfil the condition, the entire condition
                                    // counts matched.
                                    isRightConditionMet = !isRightConditionMandatoryForAll;
                                }
                                else
                                {
                                    if (isRightConditionMandatoryForAll)
                                    {
                                        // The entire condition fails since it
                                        // was mandatory for all positions
                                        // along the current side of the Slot.
                                        isSuitable = false;
                                        break currentSlotAnalysis;
                                    }
                                    else
                                    {
                                        if (innerY == y + requiredHeight - 1)
                                        {
                                            // Checked all positions along the
                                            // current vertical side of the Slot -
                                            // non of them matches the condition.
                                            isSuitable = false;
                                            break currentSlotAnalysis;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if (isSuitable)
                    {
                        result ~= new Slot(x, y, requiredWidth, requiredHeight);
                    }
                }
            }
        }

        return result;
    }

    /**
    Calculate size of the step (in Pixels), that is minimal distance between objects
    */
    size_t calculateStepSize(Slot[] slots, size_t yFrom, size_t yTo,
                         size_t objectWidth, float probability)
    {
        if (probability > 1.0)
        {
            probability = 1.0;
        }
        else if (probability < 0.0)
        {
            probability = 0.0;
        }

        // Step (number of free Pixels to leave between object)
        size_t step = objectWidth;

        // Calculate number of objects to place in the Area
        size_t qty = cast(size_t)((yTo - yFrom) * probability);
        qty = qty <= 0 ? 1 : qty;
        if (qty > slots.length)
        {
            qty = slots.length;
            step = objectWidth;
        }
        else
        {
            step = slots.length / qty;
        }

        return step;
    }

    void removeCoin(Coin removableCoin)
    {
        // TODO there must be more efficient ways of doing this
        bool found = false;
        size_t id = 0;

        // Search for provided object in the list from which it would be removed
        foreach (size_t currentId, ref Coin coin; _coins)
        {
            if (removableCoin == coin)
            {
                found = true;
                id = currentId;
                break;
            }
        }

        // If provided object is found, remove it from the source list and put
        // it in the destination list
        if (found)
        {
            _coins = _coins[0..id] ~ _coins[id + 1..$];
        }
    }

    void removeUpdatableObject(GameObject removableUpdatableObject)
    {
        // TODO there must be more efficient ways of doing this
        bool found = false;
        size_t id = 0;

        // Search for provided object in the list from which it would be removed
        foreach (size_t currentId, ref GameObject updatableObject; _updatableObjects)
        {
            if (removableUpdatableObject == updatableObject)
            {
                found = true;
                id = currentId;
                break;
            }
        }

        // If provided object is found, remove it from the source list and put
        // it in the destination list
        if (found)
        {
            _updatableObjects = _updatableObjects[0..id] ~ _updatableObjects[id + 1..$];
        }
    }
    
public:
    this(IAreaListContainer game, LivingObject player,
         float coinProbability, float swordProbability, float spiderProbability,
         size_t bottomY)
    {
        _game = game;
        _player = player;
        _coinProbability = coinProbability;
        _swordProbability = swordProbability;
        _spiderProbability = spiderProbability;
        _bottomY = bottomY;
    }

    this(IAreaListContainer game,
         float coinProbability, float swordProbability, float spiderProbability,
         size_t bottomY)
    {
        this(game, null, coinProbability, swordProbability, spiderProbability, bottomY);
    }

    /**
    Create and add static game object to the appropriate list
    */
    override GameObject createStaticObject(size_t x, size_t y, Direction direction)
    {
        GameObject gameObject = new GameObject(this, x, y, direction, 0);
        _staticObjects ~= gameObject;
        return gameObject;
    }

    /**
    Analyze empty space and randomly fill it with coins and villains in the
    specified vertical range
    */
    override void createCoinsAndVillains(size_t yFrom, size_t yTo)
    {
        import std.random: Random, uniform;

        if (yFrom >= yTo)
        {
            return;
        }

        Slot[] freeSlots;
        size_t step = 1;
        auto rnd = Random();

        // Create and place Coins
        freeSlots = findSuitableSlots(
            yFrom, yTo, 1, 1,
            delegate(size_t checkX, size_t checkY)  // Along the TOP side
            {
                return true;
            }, true,  // all
            delegate(size_t checkX, size_t checkY)  // Along the RIGHT side
            {
                return true;
            }, true, // all
            delegate(size_t checkX, size_t checkY)  // Along the BOTTOM side
            {
                return _game.renderer.pixelAt(checkX, checkY + 1) !is null;
            }, false, // at least 1
            delegate(size_t checkX, size_t checkY)  // Along the LEFT side
            {
                return _game.renderer.pixelAt(checkX - 1, checkY) is null;
            }, true // all
        );
        step = calculateStepSize(freeSlots, yFrom, yTo, 1, _coinProbability);
        for (size_t i = uniform(0, step, rnd); i < freeSlots.length; i += step)
        {
            _coins ~= new Coin(this, freeSlots[i].x, freeSlots[i].y);
        }

        // Create and place Spiders
        freeSlots = findSuitableSlots(
            yFrom, yTo, 8, 1,
            delegate(size_t checkX, size_t checkY)  // Along the TOP side
            {
                for (size_t sY = 1; sY <= 5; sY++)
                {
                    if (_game.renderer.pixelAt(checkX, checkY - sY) !is null)
                    {
                        return false;
                    }
                }
                return true;
            }, true,  // all
            delegate(size_t checkX, size_t checkY)  // Along the RIGHT side
            {
                return _game.renderer.pixelAt(checkX + 1, checkY) is null;
            }, true, // all
            delegate(size_t checkX, size_t checkY)  // Along the BOTTOM side
            {
                for (size_t sY = 1; sY <= 5; sY++)
                {
                    if (_game.renderer.pixelAt(checkX, checkY + sY) !is null)
                    {
                        return false;
                    }
                }
                return true;
            }, true, // all
            delegate(size_t checkX, size_t checkY)  // Along the LEFT side
            {
                return _game.renderer.pixelAt(checkX - 1, checkY) is null;
            }, true // all
        );
        step = calculateStepSize(freeSlots, yFrom, yTo, 9, _spiderProbability);
        for (size_t i = uniform(0, step, rnd); i < freeSlots.length; i += step)
        {
            _villains ~= new Spider(
                this,
                freeSlots[i].x,
                freeSlots[i].y,
                freeSlots[i].y - 5,
                freeSlots[i].y + 3 + 5
            );
        }

        // Create and place Swords
        freeSlots = findSuitableSlots(
            yFrom, yTo, 8, 1,
            delegate(size_t checkX, size_t checkY)  // Along the TOP side
            {
                return _game.renderer.pixelAt(checkX, checkY - 1) is null;
            }, true,  // all
            delegate(size_t checkX, size_t checkY)  // Along the RIGHT side
            {
                return _game.renderer.pixelAt(checkX + 1, checkY) is null;
            }, true, // all
            delegate(size_t checkX, size_t checkY)  // Along the BOTTOM side
            {
                return _game.renderer.pixelAt(checkX, checkY + 1) !is null;
            }, false, // at least 1
            delegate(size_t checkX, size_t checkY)  // Along the LEFT side
            {
                return _game.renderer.pixelAt(checkX - 1, checkY) is null;
            }, true // all
        );
        step = calculateStepSize(freeSlots, yFrom, yTo, 8, _swordProbability);
        for (size_t i = uniform(0, step, rnd); i < freeSlots.length; i += step)
        {
            _villains ~= new Sword(
                this,
                freeSlots[i].x,
                freeSlots[i].y,
                Direction.RIGHT,
                freeSlots[i].x - 5,
                freeSlots[i].x + 8 + 5
            );
        }
    }

    /**
    Create and place a house at a given position
    */
    override House createHouse(size_t x, size_t y)
    {
        House house = new House(this, x, y);
        _staticObjects ~= house;
        return house;
    }

    /**
    Make game object updatable (move it from static object list to updatable
    object list) and return true if it was not previously updatable.
    */
    override bool turnIntoUpdatable(GameObject gameObject)
    {
        // TODO there must be more efficient ways of doing this
        bool found = false;
        size_t id = 0;

        // Search for provided object in the list from which it would be removed
        foreach (size_t currentId, ref GameObject staticObject; _staticObjects)
        {
            if (staticObject == gameObject)
            {
                found = true;
                id = currentId;
                break;
            }
        }

        // If provided object is found, remove it from the source list and put
        // it in the destination list
        if (found)
        {
            _updatableObjects ~= gameObject;
            _staticObjects = _staticObjects[0..id] ~ _staticObjects[id + 1..$];
        }

        return found;
    }

    /**
    Make game object static (move it from updatable object list to static object
    list) and return true if it was not previously static.
    */
    override bool turnIntoStatic(GameObject gameObject)
    {
        if (_updatableObjects.length == 0)
        {
            return false;
        }

        // TODO there must be more efficient ways of doing this
        bool found = false;
        size_t id = 0;

        // Search for provided object in the list from which it would be removed
        // Since the reason to make updatable object static in most cases is that
        // it has already been made updateble before, it means that this object
        // is most likely stored in the end of the updatable objects list, that's
        // why it is faster to iterate it backwards.
        for (size_t currentId = _updatableObjects.length - 1; currentId == 0; currentId--)
        {
            if (_updatableObjects[currentId] == gameObject)
            {
                found = true;
                id = currentId;
                break;
            }
        }

        // If provided object is found, remove it from the source list and put
        // it in the destination list
        if (found)
        {
            _staticObjects ~= gameObject;
            _updatableObjects = _updatableObjects[0..id] ~ _updatableObjects[id + 1..$];
        }

        return found;
    }

    /**
    Adds given object to the list of static transferable objects. That means
    when the game switches to another Area, provided object would be transferred
    to that new Area as static object.
    This is used primarily for carried words, that a player can carry to another
    Area and throw it there.
    */
    override void makeTransferableStatic(GameObject gameObject)
    {
        _transferableStaticObjects ~= gameObject;
    }

    /**
    Remove given GameObject from the list of static transferable objects.
    */
    override void removeFromTransferableStatic(GameObject gameObject)
    {
        // TODO there must be more efficient ways of doing this
        bool found = false;
        size_t id = 0;

        // Search for provided object in the list from which it would be removed
        foreach (size_t currentId, ref GameObject transferableObject; _transferableStaticObjects)
        {
            if (transferableObject == gameObject)
            {
                found = true;
                id = currentId;
                break;
            }
        }

        // If found, remove GameObject from the list of static transferable objects
        if (found)
        {
            _transferableStaticObjects =
                _transferableStaticObjects[0..id] ~ _transferableStaticObjects[id + 1..$];
        }
    }

    /**
    Actions to take when two GameObjects collide
    */
    override void handleCollision(GameObject gameObject1, GameObject gameObject2)
    {
        if (gameObject1 == _player)
        {
            if (Coin coin = cast(Coin) gameObject2)
            {
                removeCoin(coin);
                // TODO remove coin from Area's list of coins for better performance
                _game.coinsCollected = _game.coinsCollected + 1;
            }
            else if (House house = cast(House) gameObject2)
            {
                _player.remove;
                _game.finish(true);
            }
            else if (Villain villain = cast(Villain) gameObject2)
            {
                _player.remove;
                _game.finish(false);
            }
        }
        else if (gameObject2 == _player)
        {
            if (Coin coin = cast(Coin) gameObject1)
            {
                removeCoin(coin);
                // TODO remove coin from Area's list of coins for better performance
                _game.coinsCollected = _game.coinsCollected + 1;
            }
            else if (House house = cast(House) gameObject1)
            {
                _player.remove;
                _game.finish(true);
            }
            else if (Villain villain = cast(Villain) gameObject1)
            {
                _player.remove;
                _game.finish(false);
            }
        }
        else if (gameObject1.isThrownWeapon)
        {
            if (Villain villain = cast(Villain) gameObject2)
            {
                if (!villain.isBlinking)
                {
                    removeUpdatableObject(gameObject1);
                    villain.health = villain.health - 1;
                    if (villain.health <= 0)
                    {
                        _game.villainsEliminated = _game.villainsEliminated + 1;
                    }
                }
            }
        }
        else if (gameObject2.isThrownWeapon)
        {
            if (Villain villain = cast(Villain) gameObject1)
            {
                if (!villain.isBlinking)
                {
                    removeUpdatableObject(gameObject2);
                    villain.health = villain.health - 1;
                    if (villain.health <= 0)
                    {
                        _game.villainsEliminated = _game.villainsEliminated + 1;
                    }
                }
            }
        }
    }

    /// Remove villain from villains list
    override void removeVillain(Villain removableVillain)
    {
        // TODO there must be more efficient ways of doing this
        bool found = false;
        size_t id = 0;

        // Search for provided object in the list from which it would be removed
        foreach (size_t currentId, ref Villain villain; _villains)
        {
            if (removableVillain == villain)
            {
                found = true;
                id = currentId;
                break;
            }
        }

        // If provided object is found, remove it from the source list and put
        // it in the destination list
        if (found)
        {
            _villains = _villains[0..id] ~ _villains[id + 1..$];
        }
    }

    /**
    Call update methods of all updatable game objects of the Area, as well as
    handle game logic based on objects' position and interaction within the Area.
    This method is ment to be called each iteration of the game loop.
    */
    void updateObjects()
    {
        _player.update;

        // Check player's impact on the game
        if (player.getY + player.getHeight(player.direction) >= _bottomY)
        {
            if (!_isLast)
            {
                _game.switchToNextArea;
            }
        }

        // TODO repeating code
        foreach (ref GameObject updatableObject; _updatableObjects)
        {
            if (updatableObject.getY
                + updatableObject.getHeight(updatableObject.direction) >= _bottomY)
            {
                removeUpdatableObject(updatableObject);
            }
            else
            {
                updatableObject.update;
            }
        }
        foreach (ref Coin coin; _coins)
        {
            if (coin.getY
                + coin.getHeight(coin.direction) >= _bottomY)
            {
                removeCoin(coin);
            }
            else
            {
                coin.update;
            }
        }
        foreach (ref Villain villain; _villains)
        {
            if (villain.getY
                + villain.getHeight(villain.direction) >= _bottomY)
            {
                removeVillain(villain);
            }
            else
            {
                villain.update;
            }
        }
    }

    /**
    Call render methods of all game objects of the Area.
    */
    void renderAllObjects()
    {
        _game.renderer.place(_player);
        foreach (ref GameObject updatableObject; _updatableObjects)
        {
            _game.renderer.place(updatableObject);
        }
        foreach (ref GameObject staticObject; _staticObjects)
        {
            _game.renderer.place(staticObject);
        }
        foreach (ref Coin coin; _coins)
        {
            _game.renderer.place(coin);
        }
        foreach (ref Villain villain; _villains)
        {
            _game.renderer.place(villain);
        }
    }

    /// Create new coin at provided coordinates
    Coin addCoin(size_t x, size_t y)
    {
        Coin coin = new Coin(this, x, y);
        _coins ~= coin;
        return coin;
    }

    /// Create new Sword villain at provided coordinates
    Sword addSword(size_t x, size_t y,
                   size_t maxLeftDistance, size_t maxRightDistance)
    {
        Sword sword = new Sword(
            this,
            x,
            y,
            Direction.RIGHT,
            x - maxLeftDistance,
            x + 8 + maxRightDistance
        );
        _villains ~= sword;
        return sword;
    }

    /// Return current number of coins in the Area
    ulong coinsTotal()
    {
        return _coins.length;
    }

    /// Return current number of villains in the Area
    ulong villainsTotal()
    {
        return _villains.length;
    }

    /// Return game that contains list of Areas, including this one
    override @property IAreaListContainer game()
    {
        return _game;
    }

    /// Return player object
    @property GameObject player()
    {
        return _player;
    }

    /// Set reference to player object
    @property void player(LivingObject value)
    {
        _player = value;
    }

    /// Set first indicator of the Area
    @property void isFirst(bool value)
    {
        _isFirst = value;
    }

    /// Set last indicator of the Area
    @property void isLast(bool value)
    {
        _isLast = value;
    }

    /// Return list of transferable static GameObjects
    @property GameObject[] transferableStaticObjects()
    {
        return _transferableStaticObjects;
    }

    /**
    Set list of transferable static GameObjects and add its GameObjects to the
    list of static objects.
    */
    @property void transferableStaticObjects(GameObject[] value)
    {
        _transferableStaticObjects = value;
        foreach (ref GameObject gamoObject; value)
        {
            gamoObject.area = this;
            _staticObjects ~= value;
        }
    }
}

/**
Rectangle to mark an area in the Area.
*/
private class Slot
{
    size_t x, y, w, h;

    this(size_t x, size_t y, size_t w, size_t h)
    {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
    }
}