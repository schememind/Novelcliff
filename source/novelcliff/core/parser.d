/**
Module for file content parsing
*/
module novelcliff.core.parser;

import std.stdio: File;
import novelcliff.core.base;
import novelcliff.core.interfaces;
import novelcliff.core.enums;

private
{
    const dchar[] numerics = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' ];
    const dchar[] punctuation = [ '.', ',', ';', ':', '/', '\\', '(', ')', '[', ']',
        '{', '}', '<', '>', '\"', '\'', '|', '?', '~', '!', '@', '#', '$',
        '%', '^', '&', '*', '_', '-', '+', '=', '°' ];
}

/**
Return length (symbol count) of the longest row in the file
*/
size_t getMaxLineLength(string fileName)
{
    import std.string : replace;
    import std.range.primitives : walkLength;

    size_t result = 1;
    File file = File(fileName, "r");
    while (!file.eof)
    {
        const auto lineLength = file.readln().replace("\t", "    ").walkLength;
        if (lineLength > result)
        {
            result = lineLength;
        }
    }
    return result;
}

/**
Parse provided file to identify game objects, create game objects and places
them into Areas
*/
void parse(IAreaListContainer game, string fileName,
           size_t maxWidth, size_t maxHeight, size_t initialY,
           size_t finalSpaceHeight, bool isCreateCoinsAndVillains=true)
{
    import std.file : readText;
    import std.algorithm : canFind;

    enum : int { NONE, WORD, NUMERIC, PUNCTUATION }
    
    int parseType = NONE;
    size_t cursorX = 0;
    size_t cursorY = initialY;
    GameObject gameobject;

    /**
    Internal function that does everything necessary for finishing of GameObject
    creation, as well as reset the parseType.
    */
    void finishCurrentObjectCreation()
    {
        if (gameobject !is null)
        {
            gameobject.copyPixelsBetweenDirections(
                Direction.RIGHT,
                Direction.LEFT,
                false
            );
            gameobject.recalculateProperties;
        }
        gameobject = null;
        parseType = NONE;
    }

    /**
    Internal function that understands when to start creation of a new GameObject
    and when to add a Pixel to already existing one.
    */
    void handleSymbol(dchar p_char, int p_parseType)
    {
        if (parseType == NONE || parseType != p_parseType)
        {
            // Finish previous GameObject creation
            finishCurrentObjectCreation;

            // Start creating new GameObject
            parseType = p_parseType;
            gameobject = game.activeArea.createStaticObject(
                cursorX,
                cursorY,
                Direction.RIGHT
            );

            // Add first Pixel to the newly created GameObject
            gameobject.addPixel(
                p_char,
                cursorX - gameobject.getX,
                0,
                Direction.RIGHT
            );

        }
        else
        {
            // Continue adding Pixels to already started object of the given type
            gameobject.addPixel(
                p_char,
                cursorX - gameobject.getX,
                0,
                Direction.RIGHT
            );
        }
    }

    void switchToNextRow(size_t wordWrapOffset = 0)
    {
        cursorX = 0 + wordWrapOffset;
        cursorY++;
        if (cursorY >= maxHeight)
        {
            // Before switching create coins and villains
            // (all words have been placed at this moment)
            if (isCreateCoinsAndVillains)
            {
                game.activeArea.createCoinsAndVillains(5, cursorY);
            }

            // Create next area and switch focus to it
            game.createNextActiveArea;
            cursorY = initialY;
        }
    }

    // Loop through each dchar in file
    foreach (dchar c; readText(fileName))
    {
        if (cursorX >= maxWidth)
        {
            // Word wrap
            if (gameobject !is null)
            {
                const size_t wordWrapOffset = cursorX - gameobject.getX;
                switchToNextRow(wordWrapOffset);
                gameobject.setPosition(cursorX - wordWrapOffset, cursorY, false);
            }
            else
            {
                switchToNextRow;
            }
        }

        if (c == '\n')
        {
            finishCurrentObjectCreation;
            switchToNextRow;
        }
        else if (c == '\r')
        {
            parseType = NONE;
        }
        else if (c == '\t')
        {
            finishCurrentObjectCreation;
            cursorX += 4;
        }
        else if (c == ' ')
        {
            finishCurrentObjectCreation;
            cursorX++;
        }
        else if (numerics.canFind(c))
        {
            handleSymbol(c, NUMERIC);
            cursorX++;
        }
        else if (punctuation.canFind(c))
        {
            handleSymbol(c, PUNCTUATION);
            cursorX++;
        }
        else
        {
            handleSymbol(c, WORD);
            cursorX++;
        }
    }

    // Ground in the last Area
    finishCurrentObjectCreation;
    for (size_t j = 0; j < finalSpaceHeight; j++)
    {
        switchToNextRow;
    }
    gameobject = game.activeArea.createStaticObject(
        cursorX,
        cursorY,
        Direction.RIGHT
    );
    for (size_t i = 0; i < maxWidth; i++)
    {
        gameobject.addPixel(
            '\U0000003d',
            i,
            0,
            Direction.RIGHT
        );
    }

    // House in the last Area
    game.activeArea.createHouse(1, cursorY - 5);

    // Create coins and villains in the last area
    if (isCreateCoinsAndVillains)
    {
        game.activeArea.createCoinsAndVillains(initialY, cursorY - 5);
    }
}