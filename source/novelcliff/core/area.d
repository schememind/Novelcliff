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

    // Y coordinate of the bottom row of the Area
    size_t _bottomY;

    // Indicates whether this Area is the first/last one in the list of game Areas.
    bool _isFirst, _isLast;
    
public:
    this(IAreaListContainer game, LivingObject player, size_t bottomY)
    {
        _game = game;
        _player = player;
        _bottomY = bottomY;
    }

    this(IAreaListContainer game, size_t bottomY)
    {
        this(game, null, bottomY);
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
    Create and place a coin at a given position
    */
    override void createCoins()
    {
        // TODO
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
        // TODO there must be more efficient ways of doing this
        bool found = false;
        size_t id = 0;

        // Search for provided object in the list from which it would be removed
        // Since the reason to make updatable object static in most cases is that
        // it has already been made updateble before, it means that this object
        // is most likely stored in the end of the updatable objects list, that's
        // why it is faster to iterate it backwards.
        for (size_t currentId = _updatableObjects.length - 1; currentId >= 0; currentId--)
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
    void handleCollision(GameObject gameObject1, GameObject gameObject2)
    {
        if (gameObject1 == _player)
        {
            if (Coin coin = cast(Coin) gameObject2)
            {
                coin.remove;
                // TODO remove coin from Area's list of coins for better performance
                _game.coinsCollected = _game.coinsCollected + 1;
            }
            else if (House house = cast(House) gameObject2)
            {
                _player.remove;
                _game.finish(true);
            }
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

        foreach (ref GameObject updatableObject; _updatableObjects)
        {
            if (updatableObject.getY
                + updatableObject.getHeight(updatableObject.direction) >= _bottomY)
            {
                updatableObject.remove;
            }
            updatableObject.update;
        }
        foreach (ref Coin coin; _coins)
        {
            coin.update;
        }
    }

    /**
    Call render methods of all game objects of the Area.
    Each game object contains reference to the Renderer.
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