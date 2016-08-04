package mobi.eyeline.bots.game15;

import org.apache.log4j.Logger;

import java.text.DateFormat;
import java.util.*;

public class Game
{
  private final static Logger logger = Logger.getLogger(Game.class);

  public static class Score implements Comparable<Score>
  {
    protected int  time  = 0;
    protected int  moves = 0;

    protected Score(int time, int moves) {
      this.time = time; this.moves = moves;
    }
    protected Score(Score s) {
      this(s.time, s.moves);
    }
    public Score() {
      this(0, 0);
    }

    @Override
    public int compareTo(Score o) {
      return (this.time == o.time) ? this.moves-o.moves : this.time-o.time;
    }

    public synchronized int getTime() {
      return time;
    }
    public synchronized int getMoves() {
      return this.moves;
    }
  }

  public static class GameScore extends Score
  {
    protected long startTime;

    public GameScore() {
      super(); this.startTime = System.currentTimeMillis();
    }
    protected GameScore(int time, int moves) {
      this(); this.startTime -= time*1000;
      this.time = time; this.moves = moves;
    }

    @Override
    public synchronized int getTime() {
      time = (int)(System.currentTimeMillis() - startTime)/1000;
      return time;
    }

    public synchronized int incMoves() {
      this.moves++;
      return this.moves;
    }
  }

  private String    subscriber;
  private int       subscriberLocale = GameResourceBundle.DEFAULT_LOCALE; //pers

  private long      firstTime;            //pers
  private long      totalGamesCount = 0;  //pers
  private long      winGamesCount = 0;    //pers
  private Score     bestScore = null;     //pers
  private boolean   bestScoreSet = false;

  private long      lastTime;             //sess
  private GameScore currScore = null;     //sess
  private byte[][]  cells;                //sess
  private int       empty;                //sess
  private boolean   gameStarted = false;  //sess
  private int       easyDebug = 0; //TODO: remove for fare game

  private GameResourceBundle grb = null;

  public static boolean isSubscriberValid(String subscriber) {
    return subscriber != null; // TODO: Check MSISDN
  }

  public Game(String subscriber) {
    this.subscriber = subscriber;
    this.subscriberLocale = GameResourceBundle.DEFAULT_LOCALE;
    this.grb = new GameResourceBundle(this.subscriberLocale);
    this.firstTime = System.currentTimeMillis();
    this.lastTime = this.firstTime;
  }
  protected Game(String subscriber, String persData) throws Exception {
    this.subscriber = subscriber;
    loadGamePers(persData);
  }
  protected Game(String subscriber, String persData, String sessData) throws Exception {
    this(subscriber, persData);
    loadGameSess(sessData);
  }

  public String getSubscriber() {
    return subscriber;
  }
  public void switchLocale() {
    grb.switchLocale();
    easyDebug++;
  }
  public String getText(String key) {
    return grb.getString(key);
  }
  public String getNextText(String key) {
    return grb.getNextString(key);
  }
  public byte[][] getCells() {
    return cells;
  }
  public long getTotalGames() {
    return totalGamesCount;
  }
  public long getWinGames() {
    return winGamesCount;
  }

  private String formatDate(long date) {
    if (date <= 0 || grb == null) return "";
    final DateFormat df = DateFormat.getDateTimeInstance(DateFormat.LONG, DateFormat.MEDIUM, grb.getCurrentLocale());
    return df.format(new Date(date));
  }
  public String getFirstTime() {
    return formatDate(firstTime);
  }
  public String getLastTime() {
    return formatDate(lastTime);
  }

  private void newCells() {
    this.cells = new byte[][] {{0,1,2,3}, {4,5,6,7}, {8,9,10,11}, {12,13,14,15}};
    this.empty = 0;
  }
  public void newGame()
  {
    newCells();

    final Byte[] array = {0, 2, 3, 4, 1, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
    final ArrayList<Byte> list = new ArrayList<>(Arrays.asList(array));
    if (easyDebug <= 0 || (easyDebug % 5 != 0))
      Collections.shuffle(list, new Random(System.nanoTime()));

    for (int y=0,i=0; y<4; y++) {
      for (int x=0; x<4; x++,i++) {
        byte b = list.get(i); this.cells[y][x] = b;
        if (b == 0) this.empty = i;
      }
    }

    this.lastTime = System.currentTimeMillis();
    this.totalGamesCount++; this.bestScoreSet = false;
    this.currScore = new GameScore();
    this.gameStarted = true;
  }

  private void loadGamePers(String data) throws Exception
  {
    final String GAME_LOAD_ERROR = "Game load error (pers): ";
    final String PARSE_FAILED = "Failed to parse game data ";

    if (data == null)
      throw new Exception(GAME_LOAD_ERROR + "Game data is null");

    try {
      StringTokenizer st = new StringTokenizer(data, ",");

      this.subscriberLocale = Integer.parseInt(st.nextToken());
      this.grb = new GameResourceBundle(this.subscriberLocale);
      this.firstTime = Long.parseLong(st.nextToken());
      if (this.firstTime <= 0) this.firstTime = System.currentTimeMillis();
      this.lastTime = System.currentTimeMillis();
      this.totalGamesCount = Long.parseLong(st.nextToken());
      this.winGamesCount = Long.parseLong(st.nextToken());
      this.currScore = new GameScore();
      int time = Integer.parseInt(st.nextToken());
      int moves = Integer.parseInt(st.nextToken());
      this.bestScore = (time >= 0 && moves >= 0) ? new Score(time, moves) : null;
      this.bestScoreSet = false;
    } catch (Exception exc) {
      throw new Exception(GAME_LOAD_ERROR + PARSE_FAILED + "details=" + exc.getMessage());
    }
  }

  private void loadGameSess(String data) throws Exception
  {
    final String GAME_LOAD_ERROR = "Game load error (sess): ";
    final String PARSE_FAILED = "Failed to parse game data ";

    newCells();
    if (data == null)
      throw new Exception(GAME_LOAD_ERROR + "Game data is null");

    try {
      StringTokenizer st = new StringTokenizer(data, ",");
      for (int y=0,i=0; y<4; y++) {
        for (int x=0; x<4; x++, i++) {
          if (!st.hasMoreTokens())
            throw new Exception("(cells)");
          byte b = Byte.parseByte(st.nextToken());
          if (b<0 || b>15)
            throw new Exception("(cell range[0..15])");
          this.cells[y][x]=b; if (b == 0) this.empty = i;
        }
      }

      this.lastTime = Long.parseLong(st.nextToken());
      if (this.lastTime <= 0) this.lastTime = System.currentTimeMillis();
      int time = Integer.parseInt(st.nextToken());
      int moves = Integer.parseInt(st.nextToken());
      this.currScore = new GameScore(time, moves);
      this.bestScoreSet = false;
      this.gameStarted = (st.hasMoreTokens() ? Integer.parseInt(st.nextToken()) > 0 : !isWin());
    } catch (Exception exc) {
      throw new Exception(GAME_LOAD_ERROR + PARSE_FAILED + "details=" + exc.getMessage());
    }
  }

  public String getPersData()
  {
    final StringBuilder sb = new StringBuilder(64);
    sb.append(this.subscriberLocale); sb.append(',');
    sb.append(this.firstTime); sb.append(',');
    sb.append(this.totalGamesCount); sb.append(',');
    sb.append(this.winGamesCount); sb.append(',');
    sb.append(this.bestScore != null ? bestScore.getTime()  : -1); sb.append(',');
    sb.append(this.bestScore != null ? bestScore.getMoves() : -1);
    return sb.toString();
  }

  public String getSessData()
  {
    final StringBuilder sb = new StringBuilder(64);
    for (int y=0,i=0; y<4; y++) {
      for (int x=0; x<4; x++,i++) {
        byte b = cells[y][x];
        if( b<0 || b>15 ) return null;
        sb.append(b); sb.append(',');
      }
    }
    sb.append(this.lastTime); sb.append(',');
    sb.append(this.currScore.getTime()); sb.append(',');
    sb.append(this.currScore.getMoves()); sb.append(',');
    sb.append(this.gameStarted ? 1:0);
    return sb.toString();
  }

  public String getStatus() {
    final StringBuilder sb = new StringBuilder(64);
    sb.append(grb.getString("msg.st.status"));sb.append(' ');
    sb.append(grb.getString("msg.st.moves")); sb.append(' '); sb.append(currScore.getMoves());
    sb.append(','); sb.append(' '); sb.append(grb.getString("msg.st.time")); sb.append(' ');
    sb.append(getTimeString(currScore));
    return sb.toString();
  }

  public boolean isWin() {
    if (cells == null) return false;
    for (int y=0,i=0; y<4; y++) {
      for (int x=0; x<4; x++) {
        if (cells[y][x] == 0) continue;
        if (cells[y][x] != ++i) return false;
      }
    }
    this.gameStarted = false;
    return true;
  }
  public boolean hasBestScore() {
    return bestScore != null;
  }
  private boolean isBestScore() {
    return bestScore == null || currScore.compareTo(bestScore) < 0;
  }
  public boolean isBestScoreSet() {
    return bestScoreSet;
  }
  public String getBestScoreTime() {
    return getTimeString(bestScore);
  }
  public int getBestScoreMoves() { return bestScore.moves; }

  public String getTimeString(Score score) {
    final StringBuilder sb = new StringBuilder(64);
    int time = score.getTime();
    int val = time / (3600 * 24);
    if (val > 0) { sb.append(val); sb.append(' '); sb.append(grb.getString("msg.st.days")); sb.append(' '); }
    val = (time / 3600) % 24; if (val < 10) sb.append('0'); sb.append(val); sb.append(':');
    val = (time / 60) % 60; if (val < 10) sb.append('0'); sb.append(val); sb.append(':');
    val = time % 60; if (val < 10) sb.append('0'); sb.append(val);
    return sb.toString();
  }

  public boolean isStarted() {
    return this.gameStarted;
  }
  public boolean isInProgress() {
    return !isWin() && this.gameStarted && lastTime > 0 && ((System.currentTimeMillis() - lastTime) < GameStore.getMaxGameActivityTime()*1000);
  }

  private byte get(int index) {
    if (index < 0 || index > 15) return -1;
    return cells[index/4][index%4];
  }
  private boolean set(int index, byte value) {
    if (index < 0 || index > 15) return false;
    cells[index/4][index%4] = value;
    return true;
  }
  private void incMoves()
  {
    this.currScore.incMoves();
    this.lastTime = System.currentTimeMillis();
    this.bestScoreSet = false;
    if (isWin()) {
      this.gameStarted = false;
      this.winGamesCount++;
      if (isBestScore()) {
        this.bestScore = new Score(currScore);
        this.bestScoreSet = true;
      }
      GameStore.storePersData(this);
    }
    GameStore.storeSessData(this);
  }
  public boolean move(int index)
  {
    if (index < 0 || empty == index || index > 15) return false;

    if (empty/4 == index/4)       // empty cell & index in the same row
    {
      while (empty > index) {     // shift cells right (empty cell moves to the left)
        set(empty, get(empty - 1)); empty--; set(empty, (byte)0);
      }
      while (empty < index) {     // shift cells left (empty moves to the right)
        set(empty, get(empty + 1)); empty++; set(empty, (byte)0);
      }
      incMoves();
      return true;
    }
    else if (empty%4 == index%4)  // empty cell & index in the same column
    {
      while (empty > index) {     // shift cells down (empty cell moves up)
        set(empty, get(empty - 4)); empty -= 4; set(empty, (byte) 0);
      }
      while (empty < index) {     // shift cells up (empty cell moves down)
        set(empty, get(empty + 4)); empty += 4; set(empty, (byte) 0);
      }
      incMoves();
      return true;
    }
    return false;
  }

}
