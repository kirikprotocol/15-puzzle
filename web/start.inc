<%@ page import="org.apache.log4j.Logger" %>
<%@ page import="mobi.eyeline.bots.game15.Game" %>
<%@ page import="mobi.eyeline.bots.game15.GameStore" %>
<%!
    private final static Logger logger = Logger.getRootLogger();
%>
<%
    String user_id = request.getParameter("user_id");
    String action  = request.getParameter("action");
    String gp_lang = request.getParameter("gp_lang");
    String gp_back_url = request.getParameter("gp_back_url");
    if (logger.isDebugEnabled()) {
        logger.debug("user_id: " + user_id + ", action: " + action +
                     ", gp_lang: " + gp_lang + ", gp_back_url: " + gp_back_url +
                     ". URI=" + request.getRequestURI());
    }

    Game game = null; boolean NEW_GAME = false;
    if (!Game.isSubscriberValid(user_id)) {
        logger.warn("user_id: " + user_id + " is invalid");
    } else {
        game = (Game) request.getSession().getAttribute("game");
        if (game == null) {
            final String sessionId = request.getSession().getId();
            game = GameStore.getGame(user_id, sessionId);
            if (game == null) {
                game = GameStore.newGame(user_id, sessionId, gp_lang);
                request.getSession().setAttribute("game", game);
                NEW_GAME = true;
            }
        }
    }

    if (game != null)
    {
      if (gp_lang != null) game.setGpLang(gp_lang);
      if (gp_back_url != null) game.setGpBackURL(gp_back_url);

      if ("new".equalsIgnoreCase(action)) {
        game.newGame();
%>
    <div>
       <%= game.getText("msg.new_game")%><br/>
    </div>
<%
      } else if ("lang".equalsIgnoreCase(action)) {
        game.switchLocale();
%>
    <div>
        <%= game.getText("selected_lang")%> - <%= game.getText("lang")%><br/>
    </div>
<%
      }
    } else {
%>
    <div>
        Failed to load game. Sorry<br/>
    </div>
<%
    }
%>
