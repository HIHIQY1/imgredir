import 'dart:convert';
import "dart:io";
import "dart:async";
import "package:path/path.dart" as path;
//import "package:image/image.dart";

Map redirectUrls = {
  "340x430": "https://youtu.be/cvh0nX08nRw",
  "540x360": "https://youtu.be/oavMtUWDBTM",
  "520x420": "https://youtu.be/dQw4w9WgXcQ"
};
Map imgmap = {
  "340x430": "img/gaymeme.png",
  "540x360": "img/epicgamermeme.png",
  "520x420": "img/epictechmeme.png"
};
Map clixMap = {"340x430": 0, "540x360": 0, "520x420": 0};
String saveLocation = path.joinAll(["./", "analytics.json"]);

Future main() async {
  print("App started. Checking if analytics are saved...");
  await loadAnalytics();
  print("Setting interval...");
  new Timer.periodic(new Duration(seconds: 60), saveAnalytics);

  var server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    8081,
  );

  server.autoCompress = true;

  print("Listening @ " + server.address.address + ":" + server.port.toString());

  await for (HttpRequest req in server) {
    HttpResponse res = req.response;

    res.headers.removeAll("x-xss-protection");

    if (imgmap.keys.contains(toImgSizeString(req))) {
      if (isBot(req)) {
        res.headers.contentType = new ContentType("image", "png");
        res.add(getImage(req));
      } else {
        clixMap[toImgSizeString(req)]++;
        res.statusCode = 302;
        res.headers.set("location", redirectUrls[toImgSizeString(req)]);
      }
    } else if (toImgSizeString(req) == "ANALYTICS") {
      res.headers.contentType = ContentType.json;
      res.write(json.encode(clixMap));
    } else {
      res.headers.contentType = ContentType.text;
      res.write(
          "Yeah, that's not going to work. Both 'w' and 'h' need to be a valid query and supported size.\nHere's a list of supported sizes, but you need to find out for yourself which ones are which:\n\n" +
              imgmap.keys.join("\n"));
    }
    await res.close();
  }
}

List<int> getImage(HttpRequest req) {
  File imgFile = new File(imgmap[toImgSizeString(req)]);
  if (imgFile.existsSync()) {
    return imgFile.readAsBytesSync();
  }
  return [];
}

bool isBot(req) {
  bool hasAcceptLangHeader = req.headers["accept-language"] != null;
  String uaString = (req.headers["user-agent"] != null
          ? req.headers["user-agent"][0]
          : "User-Agent not found")
      .toLowerCase();
  return uaString.contains("+") ||
      uaString.contains("bot") ||
      !hasAcceptLangHeader;
}

String toImgSizeString(HttpRequest req) {
  if (req.uri.queryParameters.length > 0) {
    if (req.uri.queryParameters["w"] != null &&
        req.uri.queryParameters["h"] != null) {
      return req.uri.queryParameters["w"] + "x" + req.uri.queryParameters["h"];
    }
  }
  if (req.uri.queryParameters.containsKey("analytics")) {
    return "ANALYTICS";
  }
  return null;
}

void saveAnalytics(Timer timer) async {
  String encodedJSON = json.encode(clixMap);
  File questionsFile = new File(saveLocation);
  questionsFile.createSync(recursive: true);
  await questionsFile.writeAsString(encodedJSON);
}

void loadAnalytics() async {
  File questionsFile = new File(saveLocation);
  await questionsFile.exists().then((bool fileExists) {
    if (fileExists) {
      print("./analytics.json does indeed exist. Loading...");
      questionsFile.readAsString().then((String encodedJSON) {
        clixMap = json.decode(encodedJSON);
      });
    }
  });
}
