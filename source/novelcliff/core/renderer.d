/**
ASCII renderer of visible game content
*/
module novelcliff.core.renderer;

import novelcliff.core.base;
import novelcliff.core.interfaces;

/**
ASCII renderer of visible game content, contains grid of Pixels.
*/
class Renderer : IPixelGridContainer
{
private:
    static const dchar carriageReturnChar = '\U0000000d';   // '\r'
    static const dchar newLineChar = '\U0000000a';          // '\n'
    static const dchar verticalWallChar = '\U0000007c';     // '|'
    static const dchar spaceChar = '\U00000020';            // ' '

    // number of chars in the end of each ASCII row (e.g. \r\n| sequence)
    const size_t lineEndCharQty = 2;

    const size_t width, height;
    Pixel[][] _pixelGrid;
    dchar[] visibleContent;

    void fillVisibleContent()
    {
        for (size_t x = 0; x < width + lineEndCharQty; x++)
        {
            for (size_t y = 0; y < height; y++)
            {
                size_t currid = y * (width + lineEndCharQty) + x;
                if (x == width)
                {
                    visibleContent[currid] = verticalWallChar;
                }
                // else if (x == width + 1)
                // {
                //     visibleContent[currid] = carriageReturnChar;
                // }
                else if (x == width + 1)
                {
                    visibleContent[currid] = newLineChar;
                }
                else
                {
                    visibleContent[currid] = _pixelGrid[x][y] !is null
                        ? _pixelGrid[x][y].symbol
                        : spaceChar;
                }
            }
        }
    }

public:
    this(size_t width, size_t height)
    {
        this.width = width;
        this.height = height;
        
        // Fill array of parts with empty values
        for (size_t x = 0; x < width; x++)
        {
            _pixelGrid ~= null;
            for (size_t y = 0; y < height; y++)
            {
                _pixelGrid[x] ~= null;
            }
        }
        
        // Fill ascii array with spaces
        for (size_t c = 0; c < (width + lineEndCharQty) * height; c++)
        {
            visibleContent ~= spaceChar;
        }
    }

    /**
    Fill all slots of the Pixel grid with nulls
    */
    void clear()
    {
        for (size_t x = 0; x < width; x++)
        {
            for (size_t y = 0; y < height; y++)
            {
                _pixelGrid[x][y] = null;
            }
        }
    }
    
    /**
    Generate and return dstring representation of the game
    */
    dstring toAsciiDstring()
    {
        fillVisibleContent;
        return visibleContent.idup;
    }

    /**
    Generate and return string representation of the game
    */
    string toAsciiString()
    {
        import std.conv : to;

        fillVisibleContent;
        return to!string(visibleContent);
    }

    /**
    Place Pixels of GameObject into appropriate slots of the Pixel grid
    */
	override void place(GameObject gameObject)
	{
		foreach (ref Pixel pixel; gameObject.pixels)
		{
            if (pixel.isVisible
                && pixel.absoluteX < width
                && pixel.absoluteY < height)
            {
                _pixelGrid[pixel.absoluteX][pixel.absoluteY] = pixel;
            }
		}
	}

    /**
    Return the Pixel grid
    */
	override @property Pixel[][] pixelGrid()
	{
		return _pixelGrid;
	}
}