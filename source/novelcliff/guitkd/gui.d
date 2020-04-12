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
	}

private:
    Game game;
    Label renderer, coinValue, villainValue, areaCurrentValue, areaTotalValue;

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
        areaTotalValue = new Label(hud, "1")
            .setTextAnchor(AnchorPosition.northWest)
			.pack(0, 0,
                  GeometrySide.right, GeometryFill.none, AnchorPosition.northWest,
                  false);
        new Label(hud, " of ")
            .setTextAnchor(AnchorPosition.northWest)
			.pack(0, 0,
                  GeometrySide.right, GeometryFill.none, AnchorPosition.northWest,
                  false);
        areaCurrentValue = new Label(hud, "1")
            .setTextAnchor(AnchorPosition.northWest)
			.pack(0, 0,
                  GeometrySide.right, GeometryFill.none, AnchorPosition.northWest,
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

    void startNewGame(CommandArgs args)
    {
        auto openFileDialog = new OpenFileDialog("Open text file for a game")
            .setMultiSelection(false)
            .addFileType("{{All files} {*}}")
            .show();
        string fileName = openFileDialog.getResult;
        if (fileName !is null)
        {
            game = new Game(fileName, 120, 35, this);
            mainWindow.setIdleCommand(
                delegate(CommandArgs args)
                {
                    game.update;
                    renderer.setText(game.renderString);
                    mainWindow.setIdleCommand(args.callback, 70);
                },
                70
            );
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

    void showAbout(CommandArgs args)
    {
        // TODO
    }
}
