package mobi.eyeline.bots.game15;

import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

import java.util.Date;

public class GameSessionListener implements HttpSessionListener
{
  private String getTime() {
    return new Date(System.currentTimeMillis()).toString();
  }

  @Override
  public void sessionCreated(HttpSessionEvent event) {
    HttpSession session = event.getSession();
    System.out.print(getTime() + " (session) Created:");
    System.out.println("ID=" + session.getId() + " MaxInactiveInterval=" + session.getMaxInactiveInterval());
  }

  @Override
  public void sessionDestroyed(HttpSessionEvent event) {
    HttpSession session = event.getSession();
    System.out.println(getTime() + " (session) Destroyed:ID=" + session.getId());
    GameStore.finalizeGame(session.getId());
  }

}
