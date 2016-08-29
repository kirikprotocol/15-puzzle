package mobi.eyeline.bots.game15;

import static mobi.eyeline.utils.restclient.web.RestClient.*;

import mobi.eyeline.utils.restclient.web.RestClient;
import org.apache.log4j.Logger;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.*;

public class GameStore
{
  private final static Logger logger = Logger.getLogger(GameStore.class);
  private final static Object storeSync = new Object();

  private static HashMap<String, Game> gamesBySubscriber = null;
  private static HashMap<String, Game> getGamesBySubscriber() {
    if (gamesBySubscriber == null) { gamesBySubscriber = new HashMap<>(); }
    return gamesBySubscriber;
  }
  private static HashMap<String, Game> gamesBySession = null;
  private static HashMap<String, Game> getGamesBySession() {
    if (gamesBySession == null) { gamesBySession = new HashMap<>(); }
    return gamesBySession;
  }

  private static boolean  configured = false;
  private static int      maxGameActivityTime = 0;
  private static String   ANOTHER_GAMES_URL;
  private static String   REST_PERS_API_ROOT;
  private static String   REST_SESS_API_ROOT;
  private static String   GAME_VAR_BASE;
  private static String   PERS_GAME_VAR;
  private static String   SESS_GAME_VAR;

  public static boolean init(String configDir)
  {
    synchronized (storeSync) {
      if (!configured) {
        ResourceBundle bundle = null;
        File configFile = new File(configDir, "config.properties");
        try (FileInputStream fis = new FileInputStream(configFile)) {
          bundle = new PropertyResourceBundle(fis);
        } catch (IOException e) {
          logger.warn("Failed to load Game15 config", e);
          return false;
        }
        maxGameActivityTime   = Integer.parseInt(bundle.getString("game.activity.time"));
        ANOTHER_GAMES_URL     = bundle.getString("another.games.url");
        REST_PERS_API_ROOT    = bundle.getString("api.root.pers");
        REST_SESS_API_ROOT    = bundle.getString("api.root.sess");
        GAME_VAR_BASE         = bundle.getString("game.var.base");
        PERS_GAME_VAR = GAME_VAR_BASE + ".pers";
        SESS_GAME_VAR = GAME_VAR_BASE + ".sess";
        configured = true;
      }
    }
    return true;
  }
  public static int getMaxGameActivityTime() {
    return maxGameActivityTime;
  }
  public static String getAnotherGamesUrl() {
    return ANOTHER_GAMES_URL;
  }
  private static boolean storeGameData(String apiRoot, String varName, String subscriber, String data) {
    try {
      new RestClient().json(apiRoot + "profile/" + subscriber + "/" + varName, post(RestClient.content(data)));
    } catch (IOException exc) {
      logger.warn("Store game for '" + subscriber + "', var=" + varName + ", data='" + data + "'. Failed. Details: " + exc.getMessage());
      return false;
    }
    if (logger.isDebugEnabled()) {
      logger.debug("Store game for '" + subscriber + "', var=" + varName + ", data='" + data + "'. Ok");
    }
    return true;
  }
  public static boolean storePersData(Game game) {
    return storeGameData(REST_PERS_API_ROOT, PERS_GAME_VAR, game.getSubscriber(), game.getPersData());
  }
  public static boolean storeSessData(Game game) {
    return storeGameData(REST_SESS_API_ROOT, SESS_GAME_VAR, game.getSubscriber(), game.getSessData());
  }

  private static String loadGameData(String apiRoot, String varName, String subscriber) {
    String data;
    try {
      data = (String)((new RestClient()).json(apiRoot + "profile/" + subscriber + "/" + varName).object().get("value"));
    } catch (Exception exc) {
      logger.warn("Load game for '" + subscriber + "', var=" + varName + ". Failed. Details: " + exc.getMessage());
      return null;
    }

    if (logger.isDebugEnabled()) {
      logger.debug("Load game for '" + subscriber + "', var=" + varName + ", data='" + data + "'. Ok");
    }
    return data;
  }
  private static String loadPersData(String subscriber) {
    return loadGameData(REST_PERS_API_ROOT, PERS_GAME_VAR, subscriber);
  }
  private static String loadSessData(String subscriber) {
    return loadGameData(REST_SESS_API_ROOT, SESS_GAME_VAR, subscriber);
  }

  public static Game newGame(String subscriber, String sessionId) {
    Game game = new Game(subscriber);
    if (logger.isDebugEnabled()) {
      logger.debug("New game for '" + subscriber + "' SID=" + sessionId);
    }
    synchronized (storeSync) {
      Game old = getGamesBySubscriber().put(subscriber, game);
      if (old != null) {
        if (logger.isDebugEnabled()) {
          logger.warn("New game for '" + subscriber + "' SID=" + sessionId + ". Found old game by subscriber. Replaced");
        }
      }
      old = getGamesBySession().put(sessionId, game);
      if (old != null) {
        if (logger.isDebugEnabled()) {
          logger.warn("New game for '" + subscriber + "' SID=" + sessionId + ". Found old game by sessionId. Replaced");
        }
      }
    }
    storePersData(game);
    return game;
  }

  public static Game getGame(String subscriber, String sessionId) {
    Game game;
    synchronized (storeSync) {
      game = getGamesBySubscriber().get(subscriber);
      if (game != null) {
        if (logger.isDebugEnabled()) {
          logger.debug("Get game for '" + subscriber + "' SID=" + sessionId + ". Got by subscriber");
        }
        return game;
      }
    }
    if (logger.isDebugEnabled()) {
      logger.debug("Get game for '" + subscriber + "' SID=" + sessionId + ". Loading...");
    }
    game = loadGame(subscriber);
    if (game != null) {
      if (logger.isDebugEnabled()) {
        logger.debug("Get game for '" + subscriber + "' SID=" + sessionId + ". Loaded");
      }
      synchronized (storeSync) {
        getGamesBySubscriber().put(game.getSubscriber(), game);
        getGamesBySession().put(sessionId, game);
      }
    }
    return game;
  }

  public static boolean finalizeGame(String sessionId) {
    Game game;
    synchronized (storeSync) {
      game = getGamesBySession().remove(sessionId);
      if (game == null) {
        if (logger.isDebugEnabled()) {
          logger.debug("Fin game for SID=" + sessionId + ". Not found");
        }
        return false;
      }
      getGamesBySubscriber().remove(game.getSubscriber());
      if (logger.isDebugEnabled()) {
        logger.debug("Fin game for '" + game.getSubscriber() + "' SID=" + sessionId + ". Ok");
      }
    }
    return (storePersData(game) && storeSessData(game));
  }

  private static Game loadGame(final String subscriber) {
    Game game;
    try {
      game = new Game(subscriber, loadPersData(subscriber), loadSessData(subscriber));
    } catch (Exception exc) {
      logger.warn("Load game for '" + subscriber + "'. Failed. Details: " + exc.getMessage());
      return null;
    }
    if (logger.isDebugEnabled()) {
      logger.debug("Load game for '" + subscriber + "'. Ok");
    }
    return game;
  }

/*
  private static ClientConfig pvssClientConfig = null;
  private static SetCommand pvssSetCommand = null;
  private static GetCommand pvssGetCommand = null;
  private static Protocol pvssProtocol = null;
  private static Client pvssClient = null;
  private static Client getPvssClient() {
    synchronized (storeSync) {
      if (pvssClient == null) {
        pvssClientConfig = new ClientConfig(); // TODO: init from properties file
        pvssProtocol = new PvapProtocol();
        pvssClient = new ClientCore(pvssClientConfig, pvssProtocol);
        pvssSetCommand = new SetCommand();
        pvssSetCommand.setVarName(PVSS_VAR_NAME);
        pvssSetCommand.getProperty().setTimePolicy(new InfinitTimePolicy());
        pvssGetCommand = new GetCommand();
        pvssGetCommand.setVarName(PVSS_VAR_NAME);
        try {
          pvssClient.startup();
        } catch (PvssException e) {
          logger.error(e.getMessage());
        }
      }
    }
    return pvssClient;
  }

  private final static String PVSS_VAR_NAME = "game15";
  private static boolean storePVSSGame(Game game)
  {
    final String subscriber = game.getSubscriber();
    final String gameData = game.toString();
    if (logger.isDebugEnabled()) {
      logger.debug("storeGame for '" + subscriber + "'");
    }
    try {
      pvssSetCommand.setStringValue(gameData);
      final ProfileRequest pvssReq = new ProfileRequest(pvssSetCommand);
      pvssReq.getProfileKey().setAbonentKey(subscriber);
      final Response pvssResp = getPvssClient().processRequestSync(pvssReq);
      if (logger.isDebugEnabled()) {
        logger.debug("storeGame for '" + subscriber + "' PVSS Response: " + pvssResp);
      }
    } catch (PvssException e) {
      logger.error("storeGame for '" + subscriber + "' PVSS Error: " + e.getMessage());
      return false;
    }

    if (logger.isDebugEnabled()) {
      logger.debug("storeGame for '" + game.getSubscriber() + "'. Stored");
    }
    return true;
  }

  private final static class PVSSResponseVisitor implements ResponseVisitor
  {
    private final String subscriber;
    private String gameData = null;

    private PVSSResponseVisitor(String subscriber) {
      this.subscriber = subscriber;
    }
    public String getGameData() {
      return gameData;
    }

    @Override
    public boolean visitErrResponse(ErrorResponse resp) throws PvssException {
      if (logger.isDebugEnabled()) {
        logger.debug("PVSS for '" + subscriber + "' Err Response: " + resp);
      }
      return true;
    }
    @Override
    public boolean visitProfileResponse(ProfileResponse resp) throws PvssException {
      if (logger.isDebugEnabled()) {
        logger.debug("PVSS for '" + subscriber + "' Ok Response: " + resp);
      }
      gameData = ((GetResponse)resp.getResponse()).getStringValue();
      return true;
    }
    @Override
    public boolean visitPingResponse(PingResponse resp) throws PvssException {
      return false;
    }
    @Override
    public boolean visitAuthResponse(AuthResponse resp) throws PvssException {
      return false;
    }
  }
  private static Game loadPVSSGame(final String subscriber)
  {
    if (logger.isDebugEnabled()) {
      logger.debug("loadGame for '" + subscriber + "'");
    }

    Game game = null;
    String gameData = null; // "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,-1,-1,0,0,0,0,0,0";
    try {
      final ProfileRequest pvssReq = new ProfileRequest(pvssGetCommand);
      pvssReq.getProfileKey().setAbonentKey(subscriber);
      final Response pvssResp = getPvssClient().processRequestSync(pvssReq);
      if (logger.isDebugEnabled()) {
        logger.debug("loadGame for '" + subscriber + "' PVSS Response: " + pvssResp);
      }
      final PVSSResponseVisitor grv = new PVSSResponseVisitor(subscriber);
      pvssResp.visit(grv);
      gameData = grv.getGameData();
    } catch (PvssException e) {
      logger.error("loadGame for '" + subscriber + "' PVSS Error: " + e.getMessage());
    }

    try {
      game = new Game(subscriber, gameData);
    } catch (Exception e) {
      logger.warn("loadGame for '" + subscriber + "'. Failed. Details: " + e.getMessage());
      return null;
    }

    if (logger.isDebugEnabled()) {
      logger.debug("loadGame for '" + subscriber + "'. Loaded");
    }
    return game;
  }
*/
}
