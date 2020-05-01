/**
Common interfaces used across all modules of the application
*/
module novelcliff.core.interfaces;

import novelcliff.core.base;
import novelcliff.core.enums;

/**
Interface representing UI. An instance of a class implementing this interface is
passed to a game constructor and the game is reporting its state data this instance.
*/
interface IUserInterface
{
    /// Display provided number of collected coins
    void displayCoins(uint coins);

    /// Display provided number of eliminated villains
    void displayVillains(uint villains);

    /// Display provided order number of current area
    void displayCurrentAreaNumber(size_t area);

    /// Display provided total number of areas in the current game
    void displayAreasTotal(size_t areasTotal);

    /// Show message about finishing current game
    void showFinishedGameMessage(bool isSuccess, uint coins, uint villains);
}

/**
Interface for an object that contains 2D array of Pixel objects
*/
interface IPixelGridContainer
{
    /// Fill all slots of the Pixel grid with nulls
    void clear();

    /// Place Pixels of GameObject into appropriate slots of container's Pixel grid
    void place(GameObject gameObject);

    /// Safely get Pixel at the specified position.
    Pixel pixelAt(size_t x, size_t y);

    /// Return 2D array of Pixel objects.
    @property Pixel[][] pixelGrid();
}

/**
Interface for an Area: a container of lists of GameObjects of different types.
*/
interface IObjectContainer
{
    /// Create and add static game object to the appropriate list
    GameObject createStaticObject(size_t x, size_t y, Direction direction);

    /// Analyze empty space and randomly fill it with coins and villains in the specified range
    void createCoinsAndVillains(size_t yFrom, size_t yTo);

    /// Create and place a house at a given position
    House createHouse(size_t x, size_t y);

    /// Make game object updatable and return true if it was not previously updatable
    bool turnIntoUpdatable(GameObject gameObject);

    /// Make game object static and return true if it was not previously static
    bool turnIntoStatic(GameObject gameObject);

    /**
    Adds given GameObject to the list of static transferable objects. That means
    when the game switches to another Area, provided object would be transferred
    to that new Area as static object.
    */
    void makeTransferableStatic(GameObject gameObject);

    /// Remove given GameObject from the list of static transferable objects.
    void removeFromTransferableStatic(GameObject gameObject);

    /// Actions to take when two GameObjects collide
    void handleCollision(GameObject gameObject1, GameObject gameObject2);

    /// Return game that contains list of Areas, including this one
    @property IAreaListContainer game();
}

/**
Interface that represents a class that contains list of Areas related to Game
*/
interface IAreaListContainer
{
    /// Make next Area of the Game active
    void switchToNextArea();

    /// Create new Area, append it to the list of Areas and make it active
    void createNextActiveArea();

    /// Finish current game
    void finish(bool isSuccess);

    /// Return reference to the currently active Area
    @property IObjectContainer activeArea();

    /// Return reference to Pixel grid container
    @property IPixelGridContainer renderer();

    /// Return the amount of collected coins for the current game
    @property uint coinsCollected();

    /// Set the amount of collected coins for the current game
    @property void coinsCollected(uint value);
}