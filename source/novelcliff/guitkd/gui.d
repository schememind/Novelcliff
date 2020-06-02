module novelcliff.guitkd;

import novelcliff.core;
import tkd.tkdapplication;
import std.conv: to;

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

    override void showFinishedGameMessage(bool isSuccess, uint coins, uint villains)
    {
        isRunning = false;
        new MessageDialog(mainWindow, "Done")
            .setMessage(
                isSuccess
                    ? "Congratulations!\n\n" ~ to!string(coins) ~ " coins collected\n"
                        ~ to!string(villains) ~ " villains eliminated"
                    : "Fail!\n\n" ~ to!string(coins) ~ " coins collected\n"
                        ~ to!string(villains) ~ " villains eliminated"
            )
            .show;
    }

protected:
    override void initInterface()
    {
        mainWindow.setTitle("Novelcliff");
        mainWindow.setGeometry(800, 600, 10, 10);
        // mainWindow.setDefaultIcon([new EmbeddedPng!("icon.png")]);

        initMenuBar;
        initHud;
        initRenderer;
        setKeyBindings;

        initLicenseDialog;
        initAboutDialog;

        isRunning = false;
    }

private:
    Game game;
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
        auto openFileDialog = new OpenFileDialog("Open text file for a game")
            .setMultiSelection(false)
            .addFileType("{{All files} {*}}")
            .show();
        string fileName = openFileDialog.getResult;
        if (fileName !is null)
        {
            // Define whether this is the first time a game is created in the
            // current application session.
            // This is required, because setIdleCommand must be called only once.
            const bool firstSetOfIdleCommand = game is null;

            game = new Game(fileName, 120, 35, this);
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
                            mainWindow.setIdleCommand(args.callback, 70);
                        }
                    },
                    70
                );
            }
        }
    }

    void startTutorial(CommandArgs args)
    {
        // TODO
    }

    void exitApp(CommandArgs args)
    {
        exit();
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
