<%@ page import="org.apache.log4j.Logger" %>
<%@ page import="mobi.eyeline.bots.game15.Game" %>
<%@ page import="mobi.eyeline.bots.game15.GameStore" %>
<%!
    private final static Logger logger = Logger.getRootLogger();
%>
<%
    //String subscriber = (request.getParameter("wnumber") != null) ? request.getParameter("subscriber"):null;
    String subscriber = request.getParameter("abonent");
    String action = request.getParameter("action");
    if (logger.isDebugEnabled()) {
        logger.debug("Subscriber: " + subscriber + ", action: " + action + ", URI=" + request.getRequestURI());
    }
    GameStore.init();

    Game game = null; boolean NEW_GAME = false;
    if (!Game.isSubscriberValid(subscriber)) {
        logger.warn("Subscriber: " + subscriber + " is invalid");
    } else {
        game = (Game) request.getSession().getAttribute("game");
        if (game == null) {
            final String sessionId = request.getSession().getId();
            game = GameStore.getGame(subscriber, sessionId);
            if (game == null) {
                game = GameStore.newGame(subscriber, sessionId);
                request.getSession().setAttribute("game", game);
                NEW_GAME = true;
            }
        }
    }

    if (game != null) {
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
