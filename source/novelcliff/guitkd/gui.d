module novelcliff.guitkd;

import novelcliff.core;
import tkd.tkdapplication;
import std.conv : to;
import std.stdio;
import dprefhandler;

private
{
    static const string WIN_X = "win.x";
    static const string WIN_Y = "win.y";
    static const string WIN_W = "win.w";
    static const string WIN_H = "win.h";
    static const string WIN_FULLSCREEN = "win.fullscreen";
    static const string FRAME_DELAY = "frame.delay";
    static const string FONT_NAME = "font.name";
    static const string FONT_SIZE = "font.size";
    static const string RENDERER_W = "renderer.w";
    static const string RENDERER_H = "renderer.h";
    static const string COIN_DENSITY = "coin.density";
    static const string SPIDER_DENSITY = "spider.density";
    static const string SWORD_DENSITY = "sword.density";
}

/**
Graphical User Interface for the game
*/
class Gui : TkdApplication, IUserInterface
{
public:
    override void displayCoins(uint coins)
    {
        coinValue.setText(to!string(coins));
    }

    override void displayVillains(uint villains)
    {
        villainValue.setText(to!string(villains));
    }

    override void displayCurrentAreaNumber(size_t area)
    {
        areaCurrentValue.setText(to!string(area));
    }

    override void displayAreasTotal(size_t areasTotal)
    {
        areaTotalValue.setText(to!string(areasTotal));
    }

    override void showFinishedGameMessage(bool isSuccess,
                                          uint coins, uint villains,
                                          uint coinsTotal, uint villainsTotal)
    {
        isRunning = false;
        double actuals = cast(double) coins + villains;
        double totals = coinsTotal + villainsTotal;
        if (totals == 0)
        {
            totals = actuals;    // handle division by zero
        }
        const uint totalScore = cast(uint) (actuals / totals * 100);
        new MessageDialog(mainWindow, "Done")
            .setMessage(
                isSuccess
                    ? "GOOD JOB\n\n" ~ "Coins collected: " ~ to!string(coins)
                        ~ " of " ~ to!string(coinsTotal)
                        ~ "\nVillains eliminated: " ~ to!string(villains)
                        ~ " of " ~ to!string(villainsTotal) ~ "\n\n"
                        ~ "TOTAL SCORE: " ~ to!string(totalScore) ~ "%"
                    : "FAIL\n\n" ~ "Coins collected: " ~ to!string(coins)
                        ~ " of " ~ to!string(coinsTotal)
                        ~ "\nVillains eliminated: " ~ to!string(villains)
                        ~ " of " ~ to!string(villainsTotal) ~ "\n\n"
                        ~ "TOTAL SCORE: " ~ to!string(totalScore) ~ "%"
            )
            .show;
    }

protected:
    override void initInterface()
    {
        // Create default preferences and fill its actual values from config file
        prefHandler = new DPrefHandler("novelcliff");
        prefHandler
            .addPref!int(WIN_X, 45)
            .addPref!int(WIN_Y, 30)
            .addPref!int(WIN_W, 800)
            .addPref!int(WIN_H, 600)
            .addPref!bool(WIN_FULLSCREEN, false)
            .addPref!int(FRAME_DELAY, 70)
            .addPref!string(FONT_NAME, "Consolas")
            .addPref!int(FONT_SIZE, 11)
            .addPref!size_t(RENDERER_W, 120)
            .addPref!size_t(RENDERER_H, 35)
            .addPref!float(COIN_DENSITY, 0.5)
            .addPref!float(SPIDER_DENSITY, 0.1)
            .addPref!float(SWORD_DENSITY, 0.3)
        ;
        prefHandler.loadFromFile;

        mainWindow.setTitle("Novelcliff");
        mainWindow.setGeometry(
            prefHandler.getActualValue!int(WIN_W),
            prefHandler.getActualValue!int(WIN_H),
            prefHandler.getActualValue!int(WIN_X),
            prefHandler.getActualValue!int(WIN_Y)
        );

        // Path to icons folder defined inside dub.json --> dflags --> -J switch
        mainWindow.setDefaultIcon([
            new EmbeddedPng!("icon16.png"),
            new EmbeddedPng!("icon24.png"),
            new EmbeddedPng!("icon32.png"),
            new EmbeddedPng!("icon64.png")
        ]);

        // Action to perform when X button is clicked
        mainWindow.setProtocolCommand("WM_DELETE_WINDOW", &exitApp);

        initMenuBar;
        initHud;
        initRenderer;
        setKeyBindings;

        initLicenseDialog;
        initAboutDialog;

        initGameAndStartGuiLoop;
    }

private:
    Game game;
    DPrefHandler prefHandler;
    Label renderer, coinValue, villainValue, areaCurrentValue, areaTotalValue;
    MessageDialog licenseDialog, aboutDialog;
    bool isRunning;

    void initMenuBar()
    {
        auto menuBar = new MenuBar(mainWindow);

        new Menu(menuBar, "File", 0)
            .addEntry("New game", &startNewGame)
            .addEntry("Tutorial", &startTutorial)
            .addSeparator()
            .addEntry("Exit", &exitApp);

        new Menu(menuBar, "Edit", 0)
            .addEntry("Preferences", &showConfigWindow);
            // TODO Mac style preferences menu
        
        new Menu(menuBar, "Help", 0)
            .addEntry("Tutorial", &startTutorial)
            .addSeparator()
            .addEntry("License", &showLicense)
            .addEntry("About", &showAbout);
    }

    void initHud()
    {
        auto hud = new Frame(mainWindow, 5, ReliefStyle.groove)
            .pack(0, 0,
                  GeometrySide.top, GeometryFill.x, AnchorPosition.south,
                  false);
        new Label(hud, "Coins:")
            .setTextAnchor(AnchorPosition.northWest)
            .pack(0, 0,
                  GeometrySide.left, GeometryFill.none, AnchorPosition.northWest,
                  false);
        coinValue = new Label(hud, "0")
            .setTextAnchor(AnchorPosition.northWest)
            .pack(0, 0,
                  GeometrySide.left, GeometryFill.none, AnchorPosition.northWest,
                  false);
        new Label(hud, "        Villains:")
            .setTextAnchor(AnchorPosition.northWest)
            .pack(0, 0,
                  GeometrySide.left, GeometryFill.none, AnchorPosition.northWest,
                  false);
        villainValue = new Label(hud, "0")
            .setTextAnchor(AnchorPosition.northWest)
            .pack(0, 0,
                  GeometrySide.left, GeometryFill.none, AnchorPosition.northWest,
                  false);
        new Label(hud, "        Area:")
            .setTextAnchor(AnchorPosition.northWest)
            .pack(0, 0,
                  GeometrySide.left, GeometryFill.none, AnchorPosition.northWest,
                  false);
        areaCurrentValue = new Label(hud, "1")
            .setTextAnchor(AnchorPosition.northWest)
            .pack(0, 0,
                  GeometrySide.left, GeometryFill.none, AnchorPosition.northWest,
                  false);
        new Label(hud, "/")
            .setTextAnchor(AnchorPosition.northWest)
            .pack(0, 0,
                  GeometrySide.left, GeometryFill.none, AnchorPosition.northWest,
                  false);
        areaTotalValue = new Label(hud, "1")
            .setTextAnchor(AnchorPosition.northWest)
            .pack(0, 0,
                  GeometrySide.left, GeometryFill.none, AnchorPosition.northWest,
                  false);
    }

    void initRenderer()
    {
        auto frame = new Frame(2, ReliefStyle.groove)
            .pack(0, 0,
                  GeometrySide.top, GeometryFill.both, AnchorPosition.northWest,
                  true);

        renderer = new Label(frame, "Welcome!")
            .setFont("Consolas", 11, FontStyle.normal)
            .setTextAnchor(AnchorPosition.northWest)
            .setBackgroundColor(Color.white)
            .setPadding(5)
            .pack(0, 0,
                  GeometrySide.top, GeometryFill.both, AnchorPosition.northWest,
                  true);
    }

    void setKeyBindings()
    {
        mainWindow.bind(
            "<KeyPress-Left>",
            delegate(CommandArgs args)
            {
                if (game !is null) game.registerSignal(InputSignal.LEFT_PRESS);
            }
        );
        mainWindow.bind(
            "<KeyRelease-Left>",
            delegate(CommandArgs args)
            {
                if (game !is null) game.registerSignal(InputSignal.LEFT_RELEASE);
            }
        );
        mainWindow.bind(
            "<KeyPress-Right>",
            delegate(CommandArgs args)
            {
                if (game !is null) game.registerSignal(InputSignal.RIGHT_PRESS);
            }
        );
        mainWindow.bind(
            "<KeyRelease-Right>",
            delegate(CommandArgs args)
            {
                if (game !is null) game.registerSignal(InputSignal.RIGHT_RELEASE);
            }
        );
        mainWindow.bind(
            "<KeyPress-Up>",
            delegate(CommandArgs args)
            {
                if (game !is null) game.registerSignal(InputSignal.JUMP_PRESS);
            }
        );
        mainWindow.bind(
            "<KeyRelease-Up>",
            delegate(CommandArgs args)
            {
                if (game !is null) game.registerSignal(InputSignal.JUMP_RELEASE);
            }
        );
        mainWindow.bind(
            "<KeyPress-space>",
            delegate(CommandArgs args)
            {
                if (game !is null) game.registerSignal(InputSignal.USE_PRESS);
            }
        );
        mainWindow.bind(
            "<KeyRelease-space>",
            delegate(CommandArgs args)
            {
                if (game !is null) game.registerSignal(InputSignal.USE_RELEASE);
            }
        );
    }

    void initAboutDialog()
    {
        aboutDialog = new MessageDialog(mainWindow, "About")
            .setType(MessageDialogType.ok)
            .setMessage(
                "Novelcliff\n" ~
                "v 0.0.1 (alfa)\n\n" ~
                "by Žans Kļimovičs\n\n" ~
                "distributed under MIT license\n\n" ~
                "Source code repository URL:\n" ~
                "https://github.com/zkrolllock/Novelcliff"
            );
    }

    void initLicenseDialog()
    {
        licenseDialog = new MessageDialog(mainWindow, "License")
            .setType(MessageDialogType.ok)
            .setMessage(
                "MIT License\n\n" ~
                "Copyright (c) 2020 Žans Kļimovičs\n\n" ~ 
                "Permission is hereby granted, free of charge, to any person obtaining a copy " ~
                "of this software and associated documentation files (the \"Software\"), to deal " ~
                "in the Software without restriction, including without limitation the rights " ~
                "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell " ~
                "copies of the Software, and to permit persons to whom the Software is " ~
                "furnished to do so, subject to the following conditions:\n\n" ~

                "The above copyright notice and this permission notice shall be included in all " ~
                "copies or substantial portions of the Software.\n\n" ~

                "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR " ~
                "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, " ~
                "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE " ~
                "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER " ~
                "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, " ~
                "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE " ~
                "SOFTWARE."
            );
    }

    void startNewGame(CommandArgs args)
    {
        if (isRunning)
        {
            // TODO show Yes/No dialog asking user if current game should be cancelled
        }

        version(OSX)
        {
            auto openFileDialog = new OpenFileDialog("Open text file for a game")
                .setMultiSelection(false)
                .show();
        }
        else
        {
            auto openFileDialog = new OpenFileDialog("Open text file for a game")
                .setMultiSelection(false)
                .addFileType("{{All files} {*}}")   // Mandatory on Windows and Linux, however it disables files on OSX
                .show();
        }

        string fileName = openFileDialog.getResult;
        initGameAndStartGuiLoop(fileName);
    }

    void startTutorial(CommandArgs args)
    {
        if (isRunning)
        {
            // TODO show Yes/No dialog asking user if current game should be cancelled
        }
        initGameAndStartGuiLoop;
    }

    void initGameAndStartGuiLoop(string fileName=null)
    {
        // Define whether this is the first time a game is created in the
        // current application session.
        // This is required, because setIdleCommand must be called only once.
        const bool firstSetOfIdleCommand = game is null;
        
        if (fileName !is null)
        {
            // Actual game
            game = new Game(
                fileName,
                prefHandler.getActualValue!size_t(RENDERER_W),
                prefHandler.getActualValue!size_t(RENDERER_H),
                prefHandler.getActualValue!float(COIN_DENSITY),
                prefHandler.getActualValue!float(SWORD_DENSITY),
                prefHandler.getActualValue!float(SPIDER_DENSITY),
                this
            );
        }
        else
        {
            // Tutorial
            game = new Game(
                fileName,
                81,
                30,
                0.0,
                0.0,
                0.0,
                this
            );
        }
        isRunning = true;

        // This seemingly unnecessary call somehow fixes a bug of coins
        // getting rendered inside of other objects :)
        game.renderString;

        if (firstSetOfIdleCommand)
        {
            mainWindow.setIdleCommand(
                delegate(CommandArgs args)
                {
                    if (isRunning)
                    {
                        game.update;
                        renderer.setText(game.renderString);
                    }
                    mainWindow.setIdleCommand(
                        args.callback,
                        prefHandler.getActualValue!int(FRAME_DELAY)
                    );
                },
                prefHandler.getActualValue!int(FRAME_DELAY)
            );
        }
    }

    void exitApp(CommandArgs args)
    {
        prefHandler.setActualValue!int(WIN_X, mainWindow.getXPos);
        prefHandler.setActualValue!int(WIN_Y, mainWindow.getYPos);
        prefHandler.setActualValue!int(WIN_W, mainWindow.getWidth);
        prefHandler.setActualValue!int(WIN_H, mainWindow.getHeight);
        prefHandler.saveToFile;
        exit();
    }

    void showConfigWindow(CommandArgs args)
    {
        new ConfigWindow(mainWindow, prefHandler);
    }

    void showLicense(CommandArgs args)
    {
        licenseDialog.show;
    }

    void showAbout(CommandArgs args)
    {
        aboutDialog.show;
    }
}

private class ConfigWindow : Window
{
    DPrefHandler _prefHandler;
    Entry rendererWidth, rendererHeight, frameDelay;
    Scale coinDensity, swordDensity, spiderDensity;

    this(Window parent, DPrefHandler prefHandler)
    {
        super(parent, "Preferences");
        _prefHandler = prefHandler;

        Frame mainFrame = new Frame(this, 2, ReliefStyle.groove)
            .pack(5, 5,
                  GeometrySide.top, GeometryFill.both, AnchorPosition.northWest,
                  true);
        mainFrame.configureGeometryColumn(1, 1);

        new Label(mainFrame, "Max area width: ").grid(0, 0);
        rendererWidth = new Entry(mainFrame)
                .grid(1, 0, 5, 0, 1, 1, "nsew")
                .setValue(_prefHandler.getActualValue!string(RENDERER_W));

        new Label(mainFrame, "Max area height: ").grid(0, 1);
        rendererHeight = new Entry(mainFrame)
                .grid(1, 1, 5, 0, 1, 1, "nsew")
                .setValue(_prefHandler.getActualValue!string(RENDERER_H));
        
        new Label(mainFrame, "Coin density (%): ").grid(0, 2);
        coinDensity = new Scale(mainFrame)
                .setFromValue(0.0)
                .setToValue(1.0)
                .grid(1, 2, 5, 0, 1, 1, "nsew")
                .setValue(_prefHandler.getActualValue!float(COIN_DENSITY));

        new Label(mainFrame, "Sword density (%): ").grid(0, 3);
        swordDensity = new Scale(mainFrame)
                .setFromValue(0.0)
                .setToValue(1.0)
                .grid(1, 3, 5, 0, 1, 1, "nsew")
                .setValue(_prefHandler.getActualValue!float(SWORD_DENSITY));

        new Label(mainFrame, "Spider density (%): ").grid(0, 4);
        spiderDensity = new Scale(mainFrame)
                .setFromValue(0.0)
                .setToValue(1.0)
                .grid(1, 4, 5, 0, 1, 1, "nsew")
                .setValue(_prefHandler.getActualValue!float(SPIDER_DENSITY));

        new Label(mainFrame, "Frame delay (ms): ").grid(0, 5);
        frameDelay = new Entry(mainFrame)
                .grid(1, 5, 5, 0, 1, 1, "nsew")
                .setValue(_prefHandler.getActualValue!string(FRAME_DELAY));

        Frame buttonFrame = new Frame(this, 2)
            .pack(5, 5,
                  GeometrySide.top, GeometryFill.both, AnchorPosition.northWest,
                  true);
        Button okBtn = new Button(buttonFrame, "OK")
                .setCommand(&saveAndExit)
                .pack(0, 0, GeometrySide.left, GeometryFill.none, AnchorPosition.center, true);
        Button resetBtn = new Button(buttonFrame, "Restore defaults")
                .setCommand(&restoreDefaults)
                .pack(0, 0, GeometrySide.left, GeometryFill.none, AnchorPosition.center, true);
        Button cancelBtn = new Button(buttonFrame, "Cancel")
                .setCommand(&cancel)
                .pack(0, 0, GeometrySide.left, GeometryFill.none, AnchorPosition.center, true);

        this.setGeometry(this.getWidth + 100, this.getHeight + 100,
                         parent.getXPos + 50, parent.getYPos + 50);
    }

    void saveAndExit(CommandArgs args)
    {
        validate;
        _prefHandler.setActualValue!string(RENDERER_W, rendererWidth.getValue);
        _prefHandler.setActualValue!string(RENDERER_H, rendererHeight.getValue);
        _prefHandler.setActualValue!float(COIN_DENSITY, coinDensity.getValue);
        _prefHandler.setActualValue!float(SWORD_DENSITY, swordDensity.getValue);
        _prefHandler.setActualValue!float(SPIDER_DENSITY, spiderDensity.getValue);
        _prefHandler.setActualValue!string(FRAME_DELAY, frameDelay.getValue);
        this.destroy;
    }

    /**
    Set field values from default values of the configuration
    */
    void restoreDefaults(CommandArgs args)
    {
        rendererWidth.setValue(_prefHandler.getDefaultValue!string(RENDERER_W));
        rendererHeight.setValue(_prefHandler.getDefaultValue!string(RENDERER_H));
        coinDensity.setValue(_prefHandler.getDefaultValue!float(COIN_DENSITY));
        swordDensity.setValue(_prefHandler.getDefaultValue!float(SWORD_DENSITY));
        spiderDensity.setValue(_prefHandler.getDefaultValue!float(SPIDER_DENSITY));
        frameDelay.setValue(_prefHandler.getDefaultValue!string(FRAME_DELAY));
    }

    /**
    Close window without saving
    */
    void cancel(CommandArgs args)
    {
        this.destroy;
    }

    void validate()
    {
        try
        {
            to!size_t(rendererWidth.getValue);
            to!size_t(rendererHeight.getValue);
            to!int(frameDelay.getValue);
        }
        catch (Exception e)
        {
            throw new Exception("Invalid value");
        }
    }
}
