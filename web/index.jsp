<%@ page language="java" contentType="text/xml; charset=UTF-8" %><?xml version="1.0" encoding="UTF-8"?>
<page version="2.0">
  <%@ include file="start.inc"%>
  <%
  if (game != null)
  {
    final boolean isReturn = "return".equalsIgnoreCase(action);
    if (action == null || isReturn) {
      if (!NEW_GAME && !isReturn && game.isInProgress()) {
        request.getRequestDispatcher("game.jsp?action=resume").forward(request, response);
      } else {
  %>
  <div>
    <%= game.getText("welcome")%><br/>
  </div>
  <div>
    &#8617; - <%= game.getText("return")%><br/>
    &#128214; - <%= game.getText("help")%><br/>
    &#127942; - <%= game.getText("achievements")%><br/>
    &#127758; - <%= game.getText("lang_select")%><br/>
  </div>
  <%
      }
    } else if("rules".equalsIgnoreCase(action)) {
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
    }
  %>
  <navigation>
    <link accesskey="1" pageId="game.jsp?action=new">&#128260; <%= game.getText("btn.new_game")%></link>
  <% if (game.isStarted() && !game.isWin()) { %>
    <link accesskey="2" pageId="game.jsp?action=resume">&#9654; <%= game.getText("btn.resume_game")%></link>
  <% } %>
  </navigation>
  <navigation>
    <link accesskey="3" pageId="index.jsp?action=rules">&#128214; <%= game.getText("btn.rules")%></link>
    <link accesskey="4" pageId="index.jsp?action=lang">&#127758; <%= game.getNextText("lang")%></link>
  </navigation>
  <navigation>
    <link accesskey="5" pageId="<%= GameStore.getAnotherGamesUrl()%>">&#127918; <%= game.getText("btn.another_games")%></link>
  </navigation>
  <%
  }
  %>
</page>
