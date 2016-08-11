import mobi.eyeline.utils.restclient.web.RestClient;

import static mobi.eyeline.utils.restclient.web.RestClient.delete;
import static mobi.eyeline.utils.restclient.web.RestClient.post;

import java.io.IOException;
import java.text.DateFormat;
import java.util.Date;

public class StoreUtility
{
  static final String API_ROOT = "http://ec2.globalussd.mobi:11201/wstorage";

  public static void main(String[] args) throws IOException
  {
    final String wnumber = "3f340dfd-09e1-4f2d-b511-5c52cb7cb0f0";
    final String pers_var = "services.game15.pers";
    final String sess_var = "services.game15.sess";

    //new RestClient().json(API_ROOT + "/profile/" + wnumber + "/mobile.msisdn", post(RestClient.content("123456")));
    new RestClient().json(API_ROOT + "/profile/" + wnumber + "/" + pers_var, delete());
    new RestClient().json(API_ROOT + "/profile/" + wnumber + "/" + sess_var, delete());

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
