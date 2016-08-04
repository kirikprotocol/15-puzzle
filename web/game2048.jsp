<%@ page language="java" contentType="text/xml; charset=UTF-8"%><?xml version="1.0" encoding="UTF-8"?>
<%@ page import="org.apache.log4j.Logger" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.util.*" %>
<%@ page import="ru.sibinco.util.DBConnectionManager" %>
<page version="2.0">

  <%!
    // ========== Game code ==========

    //private final static org.apache.log4j.Category logger = org.apache.log4j.Category.getInstance("telegame.game.jsp");
    private final static Logger logger = Logger.getRootLogger();

    private final static String[] tips = new String[] {
        "Разберитесь, как перемещаются цифры",
        "Не гонитесь за большими числами",
        "Загоняйте большие цифры в углы",
        "Просчитывайте ходы наперед",
        "Остановитесь и подумайте",
        "Делайте комбо-ходы",
        "Сокращайте количество пустых ходов",
        "Попробуйте делать ходы только в трех направлениях. Например: влево, вниз и вправо",
        "Практика, практика и еще раз практика!",
        "Пытайтесь не использовать направление вверх"
    };

    private static String getGameTip(HttpServletRequest request) {
      Integer lastTip = (Integer) request.getSession().getAttribute("game_tip_index");
      Random rnd = new Random(System.nanoTime());
      int tipIndex = rnd.nextInt(tips.length);
      if(lastTip != null && lastTip >= 0) {
        int loop = 0;
        while(tipIndex == lastTip) {
          if(loop == 5) {
            break;
          }
          tipIndex = rnd.nextInt(tips.length);
          loop++;
        }
      }
      request.getSession().setAttribute("game_tip_index", tipIndex);
      return tips[tipIndex];
    }

    public static boolean isGameWin(int[][] gameField) {
      for (int x = 0; x < 4; x++) {
        for (int y = 0; y < 4; y++) {
          if (gameField[x][y] == 2048) {
            return true;
          }
        }
      }
      return false;
    }

    public static boolean isGameOver(int[][] gameField) {
      return isGameFieldFull(gameField) && !isMovePossible(gameField);
    }

    private static boolean isGameFieldFull(int[][] gameField) {
      for (int x = 0; x < 4; x++) {
        for (int y = 0; y < 4; y++) {
          if (gameField[x][y] == 0) {
            return false;
          }
        }
      }
      return true;
    }

    private static boolean isMovePossible(int[][] gameField) {
      for (int x = 0; x < 4; x++) {
        for (int y = 0; y < (4 - 1); y++) {
          int yTmp = y + 1;
          if (gameField[x][y] == gameField[x][yTmp]) {
            return true;
          }
        }
      }
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < (4 - 1); x++) {
          int xTmp = x + 1;
          if (gameField[x][y] == gameField[xTmp][y]) {
            return true;
          }
        }
      }
      return false;
    }

    private static void firstMoveAddNewCells(int[][] gameField) {
      addNewCell(gameField);
      addNewCell(gameField);
    }

    private static void afterMoveAddNewCells(int[][] gameField) {
      addNewCell(gameField);
    }

    private static void addNewCell(int[][] gameField) {
      ArrayList<int[]> cells = null;
      for (int x = 0; x < 4; x++) {
        for (int y = 0; y < 4 ; y++) {
          if (gameField[x][y] == 0) {
            if(cells == null) {
              cells = new ArrayList<int[]>();
            }
            cells.add(new int[] {x, y});
          }
        }
      }
      if(cells == null || cells.size() == 0) {
        if(logger.isDebugEnabled()) {
          logger.debug("Can't add new cell");
        }
        return;
      }
      Random rnd = new Random(System.nanoTime());
      int value = (rnd.nextInt(10) < 9) ?  2 : 4;
      //int value = 2;
      Collections.shuffle(cells, rnd);
      int[] cellIndex = cells.get(rnd.nextInt(cells.size()));
      if (gameField[cellIndex[0]][cellIndex[1]] == 0) {
        gameField[cellIndex[0]][cellIndex[1]] = value;
        if(logger.isDebugEnabled()) {
          logger.debug("Add new cell x: " + cellIndex[0] + ", y: " + cellIndex[1] + ", value: " + value);
        }
      }
    }

    private static boolean combineCells(HttpServletRequest request, int[][] gameField, int x1, int y1, int x2, int y2, boolean dirty) {
      if (gameField[x1][y1] != 0) {
        int value = gameField[x1][y1];
        if (gameField[x2][y2] == value) {
          int newValue = value + value;
          gameField[x2][y2] = newValue;
          gameField[x1][y1] = 0;
          updateScore(request, newValue);
          dirty = true;
        }
      }
      return dirty;
    }

    private static boolean moveCell(int[][] gameField, int x1, int y1, int x2, int y2) {
      if (gameField[x1][y1] != 0 && gameField[x2][y2] == 0) {
        gameField[x2][y2] = gameField[x1][y1];
        gameField[x1][y1] = 0;
        return true;
      }
      return false;
    }

    private static void updateScore(HttpServletRequest request, int value) {
      Integer score = (Integer) request.getSession().getAttribute("game_score");
      if(score == null) {
        score = 0;
      }
      score += value;
      request.getSession().setAttribute("game_score", score);
      Integer highScore = (Integer) request.getSession().getAttribute("game_high_score");
      if(highScore == null) {
        highScore = 0;
      }
      if(score > highScore) {
        highScore = score;
        String abonent = request.getParameter("abonent");
        if(abonent != null) {
          setHighScore(abonent, highScore);
        }
      }
      request.getSession().setAttribute("game_high_score", highScore);
    }

    public static boolean moveCellsLeft(HttpServletRequest request, int[][] gameField) {
      boolean dirty = false;
      if (moveCellsLeftLoop(gameField)) dirty = true;
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < (4 - 1); x++) {
          int xx = x + 1;
          dirty = combineCells(request, gameField, xx, y, x, y, dirty);
        }
      }
      if (moveCellsLeftLoop(gameField)) dirty = true;
      return dirty;
    }

    private static boolean moveCellsLeftLoop(int[][] gameField) {
      boolean dirty = false;
      for (int y = 0; y < 4; y++) {
        boolean rowDirty = false;
        do {
          rowDirty = false;
          for (int x = 0; x < (4 - 1); x++) {
            int xx = x + 1;
            boolean cellDirty = moveCell(gameField, xx, y, x, y);
            if (cellDirty) {
              rowDirty = true;
              dirty = true;
            }
          }
        } while (rowDirty);
      }
      return dirty;
    }

    public static boolean moveCellsRight(HttpServletRequest request, int[][] gameField) {
      boolean dirty = false;
      if (moveCellsRightLoop(gameField))   dirty = true;
      for (int y = 0; y < 4; y++) {
        for (int x = (4 - 1); x > 0; x--) {
          int xx = x - 1;
          dirty = combineCells(request, gameField, xx, y, x, y, dirty);
        }
      }
      if (moveCellsRightLoop(gameField))   dirty = true;
      return dirty;
    }

    private static boolean moveCellsRightLoop(int[][] gameField) {
      boolean dirty = false;
      for (int y = 0; y < 4; y++) {
        boolean rowDirty = false;
        do {
          rowDirty = false;
          for (int x = (4 - 1); x > 0; x--) {
            int xx = x - 1;
            boolean cellDirty = moveCell(gameField, xx, y, x, y);
            if (cellDirty) {
              rowDirty = true;
              dirty = true;
            }
          }
        } while (rowDirty);
      }
      return dirty;
    }

    public static boolean moveCellsUp(HttpServletRequest request, int[][] gameField) {
      boolean dirty = false;
      if (moveCellsUpLoop(gameField))  dirty = true;
      for (int x = 0; x < 4; x++) {
        for (int y = 0; y < (4 - 1); y++) {
          int yy = y + 1;
          dirty = combineCells(request, gameField, x, yy, x, y, dirty);
        }
      }
      if (moveCellsUpLoop(gameField))  dirty = true;
      return dirty;
    }

    private static boolean moveCellsUpLoop(int[][] gameField) {
      boolean dirty = false;
      for (int x = 0; x < 4; x++) {
        boolean columnDirty = false;
        do {
          columnDirty = false;
          for (int y = 0; y < (4 - 1); y++) {
            int yy = y + 1;
            boolean cellDirty = moveCell(gameField, x, yy, x, y);
            if (cellDirty) {
              columnDirty = true;
              dirty = true;
            }
          }
        } while (columnDirty);
      }
      return dirty;
    }

    public static boolean moveCellsDown(HttpServletRequest request, int[][] gameField) {
      boolean dirty = false;
      if (moveCellsDownLoop(gameField)) dirty = true;
      for (int x = 0; x < 4; x++) {
        for (int y = 4 - 1; y > 0; y--) {
          int yy = y - 1;
          dirty = combineCells(request, gameField, x, yy, x, y, dirty);
        }
      }
      if (moveCellsDownLoop(gameField)) dirty = true;
      return dirty;
    }

    private static boolean moveCellsDownLoop(int[][] gameField) {
      boolean dirty = false;
      for (int x = 0; x < 4; x++) {
        boolean columnDirty = false;
        do {
          columnDirty = false;
          for (int y = 4 - 1; y > 0; y--) {
            int yy = y - 1;
            boolean cellDirty = moveCell(gameField, x, yy, x, y);
            if (cellDirty) {
              columnDirty = true;
              dirty = true;
            }
          }
        } while (columnDirty);
      }
      return dirty;
    }

    private static  Connection getConnection(String poolName) throws SQLException {
      return DBConnectionManager.getInstance().getConnectionFromPool(poolName);
    }

    private final static String stmtSelectGameField = "select game_field from game2048_personal_data b where abonent=? and service = 'telegram' order by score desc";
    private final static String stmtInsertGameField = "insert into game2048_personal_data (abonent, service, game_field) values (?, 'telegram', ?) on duplicate key update tm=current_timestamp, game_field = ?";
    private final static String stmtSelectRank = "select score, 1+(select count(*) from game2048_personal_data a where a.Score > b.Score) as rank from game2048_personal_data b where abonent=? and service = 'telegram' order by score desc";
    private final static String stmtSelectRanks = "select score, 1+(select count(*) from game2048_personal_data a where a.Score > b.Score) as rank from game2048_personal_data b order by score desc limit 10";
    private final static String stmtInsertHighScore = "insert into game2048_personal_data (abonent, service, score) values (?, 'telegram', ?) on duplicate key update tm=current_timestamp, score = ?";

    private static String getGameField(String abonent) {
      PreparedStatement stmt = null;
      ResultSet res = null;
      Connection con = null;

      try {
        con = getConnection("telegram");

        if (logger.isDebugEnabled()) {
          logger.debug("getGameField abonent " + abonent);
        }

        stmt = con.prepareStatement(stmtSelectGameField);
        stmt.setString(1, abonent);
        res = stmt.executeQuery();

        if (res.next()) {
          return res.getString(1);
        }
      } catch (SQLException e) {
        logger.error("SQL Error (in getGameField): " + e, e);
      } catch (Exception e) {
        logger.error("Error: " + e, e);
      } finally {
        if (res != null) {
          try {
            res.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
        if (stmt != null) {
          try {
            stmt.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
        if (con != null) {
          try {
            con.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
      }
      return null;
    }

    private static void setGameField(String abonent, String gameFieldString) {
      Connection con = null;
      PreparedStatement stmt = null;
      try {
        con = getConnection("telegram");

        if (logger.isDebugEnabled()) {
          logger.debug("setGameField abonent " + abonent + ", add gameFieldString: " + gameFieldString);
        }

        stmt = con.prepareStatement(stmtInsertGameField);

        stmt.setString(1, abonent);
        stmt.setString(2, gameFieldString);
        stmt.setString(3, gameFieldString);

        if (stmt.executeUpdate() > 0) {
          if (!con.getAutoCommit()) {
            con.commit();
          }
          if (logger.isInfoEnabled()) {
            logger.info("Abonent " + abonent + ", add gameFieldString: " + gameFieldString + " updated");
          }
        } else {
          if(logger.isDebugEnabled())
            logger.debug("No rows update for abonent " + abonent);
        }
      } catch (SQLException e) {
        logger.error("SQL Error: " + e, e);
      } finally {
        if (stmt != null) {
          try {
            stmt.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
        if (con != null) {
          try {
            con.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
      }
    }

    private static int[] getRank(String abonent) {
      PreparedStatement stmt = null;
      ResultSet res = null;
      Connection con = null;

      try {
        con = getConnection("telegram");

        if (logger.isDebugEnabled()) {
          logger.debug("getRank abonent " + abonent);
        }

        stmt = con.prepareStatement(stmtSelectRank);
        stmt.setString(1, abonent);
        res = stmt.executeQuery();

        if (res.next()) {
          // [score,  rank]
          return new int[] {res.getInt(1), res.getInt(2)};
        }
      } catch (SQLException e) {
        logger.error("SQL Error (in getRank): " + e, e);
      } catch (Exception e) {
        logger.error("Error: " + e, e);
      } finally {
        if (res != null) {
          try {
            res.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
        if (stmt != null) {
          try {
            stmt.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
        if (con != null) {
          try {
            con.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
      }
      return null;
    }

    private static List<int[]> getRanks(String abonent) {
      PreparedStatement stmt = null;
      ResultSet res = null;
      Connection con = null;

      List<int[]> ranks = null;

      try {
        con = getConnection("telegram");

        if (logger.isDebugEnabled()) {
          logger.debug("getRanks abonent " + abonent);
        }

        stmt = con.prepareStatement(stmtSelectRanks);
        res = stmt.executeQuery();

        while(res.next()) {
          if(ranks == null) {
            ranks = new ArrayList<int[]>();
          }
          // [score, rank]
          ranks.add(new int[] {res.getInt(1), res.getInt(2)});
        }
      } catch (SQLException e) {
        logger.error("SQL Error (in getRanks): " + e, e);
      } catch (Exception e) {
        logger.error("Error: " + e, e);
      } finally {
        if (res != null) {
          try {
            res.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
        if (stmt != null) {
          try {
            stmt.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
        if (con != null) {
          try {
            con.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
      }
      return ranks;
    }

    private static void setHighScore(String abonent, int highScore) {
      Connection con = null;
      PreparedStatement stmt = null;
      try {
        con = getConnection("telegram");

        if (logger.isDebugEnabled()) {
          logger.debug("setHighScore abonent " + abonent + ", add highScore: " + highScore);
        }

        stmt = con.prepareStatement(stmtInsertHighScore);

        stmt.setString(1, abonent);
        stmt.setLong(2, highScore);
        stmt.setLong(3, highScore);

        if (stmt.executeUpdate() > 0) {
          if (!con.getAutoCommit()) {
            con.commit();
          }
          if (logger.isInfoEnabled()) {
            logger.info("Abonent " + abonent + ", add highScore: " + highScore + " updated");
          }
        } else {
          if(logger.isDebugEnabled())
            logger.debug("No rows update for abonent " + abonent);
        }
      } catch (SQLException e) {
        logger.error("SQL Error: " + e, e);
      } finally {
        if (stmt != null) {
          try {
            stmt.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
        if (con != null) {
          try {
            con.close();
          } catch (SQLException e) {
            logger.error(e);
          }
        }
      }
    }

    public boolean isNeedHighlight(int value) {
      int counter = 0;
      if(value == 2) {
        return false;
      } else {
        while(value > 2) {
          value = value / 2;
          counter++;
        }
        if(counter % 2 != 0) {
          return true;
        }
      }
      return false;
    }

    public String getCellHighlightIcon(int cell) {
      /*if(isNeedHighlight(cell)) {
        return "&#128313;";
      }
      return "&#128312;";*/
      return "";
    }

    // 00:2048,10:2048,20:2048,30:2048,
    // 01:2048,11:2048,21:2048,31:2048,
    // 02:2048,12:2048,22:2048,32:2048,
    // 03:2048,13:2048,23:2048,33:2048
    public String gameFieldToString(int[][] gameField) {
      StringBuilder sb = new StringBuilder();
      if(gameField != null) {
        for(int y = 0 ; y < 4 ; y++) {
          for(int x = 0 ; x < 4 ; x++) {
            sb.append(x)
                .append(y)
                .append(":")
                .append(gameField[x][y]);
            if(y == 3 && x == 3) {
              sb.append("");
            } else {
              sb.append(",");
            }
          }
        }
      }
      return sb.toString();
    }

    public int[][] parseGameField(String gameFieldString) {
      if(gameFieldString != null && gameFieldString.length() > 0) {
        try {
          int[][] gameField = new int[4][4];
          int x = 0;
          int y = 0;
          String token = null;
          String xy = null;
          String value = null;
          StringTokenizer st = new StringTokenizer(gameFieldString, ",", false);
          while (st.hasMoreTokens()) {
            token = st.nextToken();
            int index = token.indexOf(":");
            if(index >= 0) {
              xy = token.substring(0, index);
              value = token.substring(index + 1, token.length());
              if(xy.length() == 2 && value.length() > 0) {
                x = Integer.parseInt(xy.substring(0, 1));
                y = Integer.parseInt(xy.substring(1, 2));
                gameField[x][y] = Integer.parseInt(value);
              }
            } else {
              logger.error("Wrong gameFieldString: " + gameFieldString + ", index: " + index + ", xy: " + xy + ", value: " + value);
              return null;
            }
          }
          return gameField;
        } catch(Exception e) {
          logger.error("Error: " + e.getMessage(), e);
          return null;
        }
      }
      return null;
    }
  %>

  <%
    String abonent = request.getParameter("abonent");
    String button = request.getParameter("button");
    if(logger.isDebugEnabled()) {
      logger.debug("Abonent: " + abonent + ", button: " + button);
    }
  %>

  <!-- ========== Check game field, score and high score ========== -->

  <%
    int[][] gameField = null;
    if(button != null && "restart".equalsIgnoreCase(button)) {
      gameField = new int[][] {
          {0, 0, 0, 0},
          {0, 0, 0, 0},
          {0, 0, 0, 0},
          {0, 0, 0, 0}
      };
      if(logger.isDebugEnabled()) {
        logger.debug("Abonent: " + abonent + ", restart - create default gameField");
      }
      firstMoveAddNewCells(gameField);
      request.getSession().setAttribute("game_field", gameField);
      request.getSession().setAttribute("game_score", 0);
      setGameField(abonent, gameFieldToString(gameField));
  %>
  <div>
    Вы на <%=request.getSession().getAttribute("game_rank")%> месте!<br/>
    Счёт: <%=request.getSession().getAttribute("game_score")%>, рекорд: <%=request.getSession().getAttribute("game_high_score")%><br/>
  </div>
  <%
    }

    gameField = parseGameField(getGameField(abonent));
    if(gameField == null) {
      gameField = (int[][]) request.getSession().getAttribute("game_field");
      if(gameField == null) {
        setGameField(abonent, gameFieldToString(gameField));
      }
    }
    // Check game field
    if(gameField == null) {
      gameField = new int[][] {
          {0, 0, 0, 0},
          {0, 0, 0, 0},
          {0, 0, 0, 0},
          {0, 0, 0, 0}
      };
      if(logger.isDebugEnabled()) {
        logger.debug("Abonent: " + abonent + ", gameField is null, create default gameField");
      }
      firstMoveAddNewCells(gameField);
      request.getSession().setAttribute("game_field", gameField);
      setGameField(abonent, gameFieldToString(gameField));
    } else {
      if(logger.isDebugEnabled()) {
        logger.debug("Abonent: " + abonent + ", gameField: " + Arrays.toString(gameField));
      }
    }

    // Check game score
    Integer score = (Integer) request.getSession().getAttribute("game_score");
    if(score == null) {
      score = 0;
      request.getSession().setAttribute("game_score", 0);
      if(logger.isDebugEnabled()) {
        logger.debug("Abonent: " + abonent + ", score is null, set default score = 0");
      }
    }

    // Check game high score and rank
    Integer abonentRank = null;
    Integer highScore = null;
    int[] rank = getRank(abonent);
    if(rank != null) {
      highScore = rank[0];
      if(highScore == null) {
        highScore = (Integer) request.getSession().getAttribute("game_high_score");
      }
      abonentRank = rank[1];
      if(abonentRank == null) {
        abonentRank = (Integer) request.getSession().getAttribute("game_rank");
      }
    }
    if(highScore == null) {
      highScore = 0;
    }
    if(abonentRank == null) {
      abonentRank = 0;
    }
    request.getSession().setAttribute("game_high_score", highScore);
    request.getSession().setAttribute("game_rank", abonentRank);
    if(logger.isDebugEnabled()) {
      logger.debug("Abonent: " + abonent + ", highScore: " + highScore + ", abonentRank: " + abonentRank);
    }
  %>

  <!-- ========== Processing game controls ========== -->

  <%
    if(logger.isDebugEnabled()) {
      StringBuilder sb = new StringBuilder();
      sb.append("[");
      for(int x = 0 ; x < 4 ; x++) {
        sb.append("[");
        for(int y = 0 ; y < 4 ; y++) {
          sb.append(gameField[x][y]);
          if(y < 3) {
            sb.append(", ");
          }
        }
        sb.append("]");
        if(x < 3) {
          sb.append(", ");
        } else {
          sb.append("");
        }
      }
      sb.append("]");
      logger.debug("gameField: " + sb.toString());
    }

    boolean win = false;
    boolean gameOver = false;
    if(isGameOver(gameField)) {
      gameOver = true;
  %>
  <div>
    Вы проиграли!<br/>
    &#128260; - начать игру заново.<br/>
  </div>
  <%
  } else if(isGameWin(gameField)) {
    win = true;
  %>
  <div>
    Вы победили!<br/>
    &#128260; - начать игру заново.<br/>
  </div>
  <%
    }
  %>

  <%
    if(button == null) {
  %>
  <div>
    Вы на <%=request.getSession().getAttribute("game_rank")%> месте!<br/>
    Счёт: <%=request.getSession().getAttribute("game_score")%>, рекорд: <%=request.getSession().getAttribute("game_high_score")%><br/>
  </div>
  <%
  } else if("field".equalsIgnoreCase(button)) {
  %>
  <div>
    Вы на <%=request.getSession().getAttribute("game_rank")%> месте!<br/>
    Счёт: <%=request.getSession().getAttribute("game_score")%>, рекорд: <%=request.getSession().getAttribute("game_high_score")%><br/>
  </div>
  <div>
    Для управления используйте только &#11013;, &#10145;, &#11014;, &#11015;<br/>
  </div>
  <div>
    &#9729; <%=getGameTip(request)%><br/>
  </div>
  <%
  } else if("left".equalsIgnoreCase(button)) {
    if(!win && !gameOver) {
      moveCellsLeft(request, gameField);
      afterMoveAddNewCells(gameField);
      setGameField(abonent, gameFieldToString(gameField));
    }
  %>
  <div>
    Вы на <%=request.getSession().getAttribute("game_rank")%> месте!<br/>
    Счёт: <%=request.getSession().getAttribute("game_score")%>, рекорд: <%=request.getSession().getAttribute("game_high_score")%><br/>
  </div>
  <div>
    &#9729; <%=getGameTip(request)%><br/>
  </div>
  <%
  } else if("right".equalsIgnoreCase(button)) {
    if(!win && !gameOver) {
      moveCellsRight(request, gameField);
      afterMoveAddNewCells(gameField);
      setGameField(abonent, gameFieldToString(gameField));
    }
  %>
  <div>
    Вы на <%=request.getSession().getAttribute("game_rank")%> месте!<br/>
    Счёт: <%=request.getSession().getAttribute("game_score")%>, рекорд: <%=request.getSession().getAttribute("game_high_score")%><br/>
  </div>
  <div>
    &#9729; <%=getGameTip(request)%><br/>
  </div>
  <%
  } else if("up".equalsIgnoreCase(button)) {
    if(!win && !gameOver) {
      moveCellsUp(request, gameField);
      afterMoveAddNewCells(gameField);
      setGameField(abonent, gameFieldToString(gameField));
    }
  %>
  <div>
    Вы на <%=request.getSession().getAttribute("game_rank")%> месте!<br/>
    Счёт: <%=request.getSession().getAttribute("game_score")%>, рекорд: <%=request.getSession().getAttribute("game_high_score")%><br/>
  </div>
  <div>
    &#9729; <%=getGameTip(request)%><br/>
  </div>
  <%
  } else if("down".equalsIgnoreCase(button)) {
    if(!win && !gameOver) {
      moveCellsDown(request, gameField);
      afterMoveAddNewCells(gameField);
      setGameField(abonent, gameFieldToString(gameField));
    }
  %>
  <div>
    Вы на <%=request.getSession().getAttribute("game_rank")%> месте!<br/>
    Счёт: <%=request.getSession().getAttribute("game_score")%>, рекорд: <%=request.getSession().getAttribute("game_high_score")%><br/>
  </div>
  <div>
    &#9729; <%=getGameTip(request)%><br/>
  </div>
  <%
  } else if("top10".equalsIgnoreCase(button)) {
  %>
  <div>
    Вы на <%=request.getSession().getAttribute("game_rank")%> месте!<br/>
    Счёт: <%=request.getSession().getAttribute("game_score")%>, рекорд: <%=request.getSession().getAttribute("game_high_score")%><br/>
  </div>
  <div>
    Топ 10 игроков:<br/>
    <%
      List<int[]> ranks = getRanks(abonent);
      if(ranks != null && ranks.size() > 0) {
        for(int i = 0 ; i < ranks.size() ; i++) {
          int[] rankTmp = ranks.get(i);
    %>
      <%=rankTmp[1]%> - рекорд: <%=rankTmp[0]%><br/>
    <%
      }
    } else {
    %>
    пока пуст<br/>
    <%
      }
    %>
  </div>
  <%
  } else if("help".equalsIgnoreCase(button)) {
  %>
  <div>
    Вы на <%=request.getSession().getAttribute("game_rank")%> месте!<br/>
    Счёт: <%=request.getSession().getAttribute("game_score")%>, рекорд: <%=request.getSession().getAttribute("game_high_score")%><br/>
  </div>
  <div>
    Для управления используйте только &#11013;, &#10145;, &#11014;, &#11015;<br/>
  </div>
  <div>
    В каждом раунде появляются новые цифры. Нажатием стрелки вы можете сдвинуть все цифры в одну из 4 сторон. Оказавшись рядом, две одинаковые цифры суммируются.<br/>
  </div>
  <div>
    2 + 2 = 4<br/>
    4 + 4 = 8<br/>
    2048 - победа!<br/>
  </div>
  <div>
    &#127942; - топ 10 игроков<br/>
    &#128260; - начать игру заново<br/>
    &#10067; - справка<br/>
  </div>
  <%
    }
  %>

  <!-- ========== Draw game field ========== -->

  <%
    for(int y = 0 ; y < 4 ; y++) {
  %>
  <!-- Zero Width Space &#8203; -->
  <navigation>
    <%
      for(int x = 0 ; x < 4 ; x++) {
        int cell = gameField[x][y];
        //----------------------------------------------------------------------------------------
        // Empty cell
        //----------------------------------------------------------------------------------------
        if(cell == 0) {
    %>
    <link pageId="game.jsp?button=field" accesskey="*">&#8203;</link>
    <%
      //----------------------------------------------------------------------------------------
      // Digit cell
      //----------------------------------------------------------------------------------------
    } else {
    %>
    <link pageId="game.jsp?button=field" accesskey="*"><%=cell%><%=getCellHighlightIcon(cell)%></link>
    <%
        }
      }

      // ========== Draw game controls and menu ========== -->

      if(y == 0) {
        if(win || gameOver) {
    %>
    <link pageId="game.jsp?button=field" accesskey="1">&#11014;</link>
    <link pageId="game.jsp?button=field" accesskey="2">&#10145;</link>
    <%
    } else {
    %>
    <link pageId="game.jsp?button=up" accesskey="1">&#11014;</link>
    <link pageId="game.jsp?button=down" accesskey="2">&#11015;</link>
    <%
      }
    } else if(y == 1) {
      if(win || gameOver) {
    %>
    <link pageId="game.jsp?button=field" accesskey="3">&#11013;</link>
    <link pageId="game.jsp?button=field" accesskey="4">&#11015;</link>
    <%
    } else {
    %>
    <link pageId="game.jsp?button=left" accesskey="3">&#11013;</link>
    <link pageId="game.jsp?button=right" accesskey="4">&#10145;</link>
    <%
      }
    } else if(y == 2) {
    %>
    <link pageId="game.jsp?button=top10" accesskey="*">&#127942;</link>
    <link pageId="game.jsp?button=restart" accesskey="*">&#128260;</link>
    <%
    } else if(y == 3) {
    %>
    <link pageId="index.jsp" accesskey="*">&#127968;</link>
    <link pageId="game.jsp?button=help" accesskey="*">&#10067;</link>
    <%
      }
    %>
  </navigation>
  <% } %>
  <%
    if(win) {
  %>
  <attachment
      type="photo"
      src="img/nichosi.png"
      fileName="nichosi.png"/>
  <%
  } else if(gameOver) {
  %>
  <attachment
      type="photo"
      src="img/nuchot.png"
      fileName="nuchot.png"/>
  <%
    }
  %>
</page>
