import mobi.eyeline.utils.restclient.web.RestClient;
import org.apache.log4j.Logger;

import static mobi.eyeline.utils.restclient.web.RestClient.delete;
import static mobi.eyeline.utils.restclient.web.RestClient.post;

import java.io.IOException;
import java.text.DateFormat;
import java.util.Date;

public class StoreUtility
{
  //private final static Logger logger = Logger.getLogger(StoreUtility.class);
  static final String API_ROOT = "http://ec2.globalussd.mobi:11201/wstorage";

  public static void main(String[] args) throws IOException
  {
    final String wnumber = "a761f808-da01-48ea-add8-360bef724af9";
    final String pers_var = "services.game15.pers";
    final String sess_var = "services.game15.sess";

    //new RestClient().json(API_ROOT + "/profile/" + wnumber + "/mobile.msisdn", post(RestClient.content("123456")));
    new RestClient().json(API_ROOT + "/profile/" + wnumber + "/" + pers_var, delete());
    new RestClient().json(API_ROOT + "/profile/" + wnumber + "/" + sess_var, delete());

    String data = null;
    try {
      data = (String)((new RestClient()).json(API_ROOT + "/profile/" + wnumber + "/" + pers_var).object().get("value"));
      if (data != null) {
        System.out.println("Load game for '" + wnumber + "', var=" + pers_var + ", data='" + data + "'. Ok");
      }
    } catch (Exception exc) {
      System.out.println("Load game for '" + wnumber + "', var=" + pers_var + ". Failed. Details: " + exc.getMessage());
    }

    /*final int time = 40*3600 + 3600*15 + 60*10 + 15;
    final StringBuilder sb = new StringBuilder(64);

    int val = time / (3600 * 24);
    if (val > 0) { sb.append(val); sb.append(' '); sb.append("days"); sb.append(' '); }
    val = (time / 3600) % 24; if (val < 10) sb.append('0'); sb.append(val); sb.append(':');
    val = (time / 60) % 60; if (val < 10) sb.append('0'); sb.append(val); sb.append(':');
    val = time % 60; if (val < 10) sb.append('0'); sb.append(val);

    System.out.println("Time: " + sb.toString());*/

    System.out.println("Done");
  }
}
