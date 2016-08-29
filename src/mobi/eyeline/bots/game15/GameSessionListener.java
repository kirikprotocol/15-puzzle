package mobi.eyeline.bots.game15;

import org.apache.log4j.PropertyConfigurator;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

import java.io.File;
import java.util.Date;
import java.util.concurrent.TimeUnit;

public class GameSessionListener implements HttpSessionListener, ServletContextListener
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

  @Override
  public void contextInitialized(ServletContextEvent servletContextEvent)
  {
    final String configDir = System.getProperty("game15.config_dir");
    if (configDir == null)
      throw new RuntimeException("Failed to obtain Game15 config directory");

    final File log4jprops = new File(configDir, "log4j.properties");
    System.out.println("Log4j conf file: " + log4jprops.getAbsolutePath() +
                       ", exists: " + log4jprops.exists());

    PropertyConfigurator.configureAndWatch(log4jprops.getAbsolutePath(), TimeUnit.MINUTES.toMillis(1));

    GameStore.init(configDir);
  }

  @Override
  public void contextDestroyed(ServletContextEvent servletContextEvent) {

  }
}
