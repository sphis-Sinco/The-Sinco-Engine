package funkin.ui.options;

import flixel.FlxSprite;
import funkin.graphics.shaders.HSVShader;
import funkin.input.Controls;
import funkin.ui.MusicBeatState;
import funkin.ui.Page.PageName;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.debug.latency.LatencyState;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.transition.LoadingState;

/**
 * The main options menu
 * It mainly is controlled via the "optionsCodex" object,
 * which handles paging and going to the different submenus
 */
class OptionsState extends MusicBeatState
{
  var optionsCodex:Codex<OptionsMenuPageName>;

  override function create():Void
  {
    persistentUpdate = true;

    var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBG'));
    var hsv:HSVShader = new HSVShader(-0.6, 0.9, 3.6);
    menuBG.shader = hsv;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    optionsCodex = new Codex<OptionsMenuPageName>(Options);
    add(optionsCodex);

    var options:OptionsMenu = optionsCodex.addPage(Options, new OptionsMenu());
    var preferences:PreferencesMenu = optionsCodex.addPage(Preferences, new PreferencesMenu());
    var controls:ControlsMenu = optionsCodex.addPage(Controls, new ControlsMenu());

    if (options.hasMultipleOptions())
    {
      options.onExit.add(exitToMainMenu);
      controls.onExit.add(exitControls);
      preferences.onExit.add(optionsCodex.switchPage.bind(Options));
    }
    else
    {
      // No need to show Options page
      controls.onExit.add(exitToMainMenu);
      optionsCodex.setPage(Controls);
    }

    super.create();
  }

  function exitControls():Void
  {
    // Apply any changes to the controls.
    PlayerSettings.reset();
    PlayerSettings.init();

    optionsCodex.switchPage(Options);
  }

  function exitToMainMenu():Void
  {
    optionsCodex.currentPage.enabled = false;
    // TODO: #3 Animate this transition?
    FlxG.switchState(() -> new MainMenuState());
  }
}

/**
 * Our default Page when we enter the OptionsState, a bit of the root
 */
class OptionsMenu extends Page<OptionsMenuPageName>
{
  var items:TextMenuList;

  public function new()
  {
    super();

    add(items = new TextMenuList());
    createItem("PREFERENCES", function() codex.switchPage(Preferences));
    createItem("CONTROLS", function() codex.switchPage(Controls));
    createItem("INPUT OFFSETS", function() {
      #if web
      LoadingState.transitionToState(() -> new LatencyState());
      #else
      FlxG.state.openSubState(new LatencyState());
      #end
    });

    createItem("CLEAR SAVE DATA", function() {
      promptClearSaveData();
    });

    createItem("EXIT", exit);
  }

  function createItem(name:String, callback:Void->Void, fireInstantly = false):TextMenuItem
  {
    var item:TextMenuItem = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  override function set_enabled(value:Bool):Bool
  {
    items.enabled = value;
    return super.set_enabled(value);
  }

  /**
   * True if this page has multiple options, excluding the exit option.
   * If false, there's no reason to ever show this page.
   */
  public function hasMultipleOptions():Bool
  {
    return items.length > 2;
  }

  var prompt:Prompt;

  function promptClearSaveData():Void
  {
    if (prompt != null) return;

    prompt = new Prompt("This will delete
      \nALL your save data.
      \nAre you sure?
    ", Custom("Delete", "Cancel"));
    prompt.create();
    prompt.createBgFromMargin(100, 0xFFFAFD6D);
    prompt.back.scrollFactor.set(0, 0);
    add(prompt);

    prompt.onYes = function() {
      // Clear the save data.
      funkin.save.Save.clearData();

      FlxG.switchState(() -> new funkin.InitState());
    }

    prompt.onNo = function() {
      prompt.close();
      prompt.destroy();
      prompt = null;
    }
  }
}

enum abstract OptionsMenuPageName(String) to PageName
{
  public var Options = "options";
  public var Controls = "controls";
  public var Colors = "colors";
  public var Mods = "mods";
  public var Preferences = "preferences";
}
