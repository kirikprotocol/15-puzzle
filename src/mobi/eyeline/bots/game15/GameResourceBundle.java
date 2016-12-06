package mobi.eyeline.bots.game15;

import java.util.Locale;
import java.util.ResourceBundle;

public class GameResourceBundle
{
  private ResourceBundle bundle;

  public  final static int RU_RU_LOCALE   = 0;
  public  final static int EN_US_LOCALE   = 1;
  public  final static int DEFAULT_LOCALE = RU_RU_LOCALE;

  private final Locale[] locales = new Locale[] { new Locale("ru", "ru"), new Locale("en", "us")};
  private int currentLocale = DEFAULT_LOCALE;

  private ResourceBundle getBundle(int locale) {
    return ResourceBundle.getBundle("game15", locales[locale]);
  }
  private void setLocale(int locale) {
    if (locale < 0 || locale >= locales.length) locale = DEFAULT_LOCALE;
    this.currentLocale = locale; this.bundle = getBundle(currentLocale);
  }

  public GameResourceBundle() {
    this(DEFAULT_LOCALE);
  }
  public GameResourceBundle(int locale) {
    setLocale(locale);
  }

  private int getNextLocaleIndex() {
    return (currentLocale+1)%locales.length;
  }
  public synchronized void switchLocale() {
    setLocale(getNextLocaleIndex());
  }
  private String getString(String key, ResourceBundle bundle) {
    String value = bundle.getString(key);
    try {
      return new String(value.getBytes("ISO-8859-1"), "UTF-8");
    } catch (Exception e) {
      return value;
    }
  }
  public String getString(String key){
    return getString(key, bundle);
  }
  public String getNextString(String key){
    ResourceBundle bundle = getBundle(getNextLocaleIndex());
    return getString(key, bundle);
  }

  protected synchronized Locale getCurrentLocale() {
    return locales[currentLocale];
  }

}
