<%@ page language="java" contentType="text/xml; charset=UTF-8" %><?xml version="1.0" encoding="UTF-8"?>
<page version="2.0">
  <%@ include file="start.inc"%>
  <%
  if (game != null)
  {
    if (NEW_GAME && !"new".equalsIgnoreCase(action)) {
      request.getRequestDispatcher("index.jsp").forward(request, response);
    } else if ("cell".equalsIgnoreCase(action)) {
      String cell = request.getParameter("cell");
      int gameCell = -1;
      try { gameCell = Integer.parseInt(cell); } catch (Exception exc) {
        logger.warn("Invalid cell=" + cell + ", exc=" + exc.getMessage());
      }
      if (!game.move(gameCell)) {
  %>
  <div>
      <%= game.getText("msg.invalid_move")%><br/>
  </div>
  <%
      } else {
  %>
  <div>
      <%= game.getStatus()%><br/>
  </div>
  <%
      }
    } else if ("rules".equalsIgnoreCase(action)) {
  %>
  <div>
        <%= game.getText("rules1")%><br/>
      <br/>
        <%= game.getText("rules2")%><br/>
        <%= game.getText("rules3")%><br/>
        <br/>
        <%= game.getText("rules4")%><br/>
        <br/>
        <%= game.getText("rules5")%><br/>
  </div>
  <%
    } else if ("achievements".equalsIgnoreCase(action)) {
  %>
  <div>
      <%= game.getText("msg.ach.first_time") %>: <%= game.getFirstTime() %><br/>
      <%= game.getText("msg.ach.last_time")  %>: <%= game.getLastTime()  %><br/>
      <%= game.getText("msg.ach.total_games")%>: <%= game.getTotalGames()%><br/>
      <%= game.getText("msg.ach.win_games")  %>: <%= game.getWinGames()  %><br/>
  <%if (game.hasBestScore()) { %>
      <br/>
      <%= game.getText("msg.ach.best_result")%>:
      <%= game.getBestScoreTime()%>, <%= game.getText("msg.st.moves")%> <%= game.getBestScoreMoves()%><br/>
  <%} %>
  </div>
  <%
    }

    if (game.isWin())
    {
      if ("cell".equalsIgnoreCase(action)) {
  %>
  <div>
    <%= game.getText("msg.win")%><br/>
    <% if (game.isBestScoreSet()) { %><%= game.getText("msg.best_achievement")%><br/><% } %>
  </div>
  <%
      }
  %>
  <div>
    &#128260; - <%= game.getText("play_again")%><br/>
    &#127942; - <%= game.getText("achievements")%><br/>
  </div>
  <navigation>
    <link pageId="game.jsp?action=new" accesskey="*">&#128260; <%= game.getText("btn.play_again")%></link>
    <link pageId="game.jsp?action=achievements" accesskey="10">&#127942; <%= game.getText("btn.achievements")%></link>
  </navigation>
  <%
      if ("cell".equalsIgnoreCase(action)) {
  %>
  <attachment type="photo" src="img/nichosi.png" fileName="nichosi.png"/>
  <%
      }
    } else { // if (game.isWin())
  %>
  <!-- ========== Draw game cells & controls ========== -->
  <%
      for (int y=0,i=0; y<4; y++) {
  %>
  <navigation>
    <%
        for (int x=0; x<4; x++,i++) {
          byte cell = game.getCells()[y][x];
          if (cell == 0) {  // Zero Width Space &#8203;
    %>
    <link pageId="game.jsp?action=empty" accesskey="00">&#8203;</link>
    <%
          } else {
    %>
    <link pageId="game.jsp?action=cell&amp;cell=<%= i%>" accesskey="<%= i%>"><%=cell%></link>
    <%
          }
        } // end for (int x = 0 ; x < 4 ; x++)

        switch (y) {
        case 0:
    %>
    <link pageId="index.jsp?action=return" accesskey="*">&#8617;</link>
    <%
        break;
        case 1:
    %>
    <link pageId="game.jsp?action=rules" accesskey="100">&#128214;</link>
    <%
        break;
        case 2:
    %>
    <link pageId="game.jsp?action=achievements" accesskey="200">&#127942;</link>
    <%
        break;
        case 3:
    %>
    <link pageId="game.jsp?action=lang" accesskey="300">&#127758;</link>
    <%
        break;
        default:
        break;
        }
    %>
  </navigation>
  <%
      } // end for (int y=0 ; y<4 ; y++)
    }
  }
  %>
</page>