import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shire/models/user.dart';
import 'package:shire/databases/users.dart';
import 'package:shire/meta/current_user.dart';
import 'package:date_format/date_format.dart';

class ShoutBox extends StatefulWidget {
  @override
  _ShoutBoxState createState() => _ShoutBoxState();
}

class _ShoutBoxState extends State<ShoutBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.0),
      margin: EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: Colors.lightBlueAccent,
        border: Border.all(color: Colors.blueGrey, style: BorderStyle.solid),
      ),
      child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection("shouts")
              .orderBy("timestamp", descending: true)
              .limit(2)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
            if (!snapshots.hasData)
              return Container(
                  width: double.infinity, child: CircularProgressIndicator());

            var docs = snapshots.data.documents;

            return Column(
              children: <Widget>[
                Text("Shout Box"),

                //shout card 1
                docs.length > 0
                    ? FutureBuilder<User>(
                        future: getUser(docs[0].data["uid"]),
                        builder: (BuildContext context,
                            AsyncSnapshot<User> userSnap) {
                          return userSnap.hasData
                              ? ShoutCard(
                                  poster: userSnap.data,
                                  doc: docs[0],
                                )
                              : Padding(
                                  padding: EdgeInsets.all(5.0),
                                  child: CircularProgressIndicator());
                        },
                      )
                    : Container(),

                //shout card 2
                docs.length > 1
                    ? FutureBuilder<User>(
                        future: getUser(docs[1].data["uid"]),
                        builder: (BuildContext context,
                            AsyncSnapshot<User> userSnap) {
                          return userSnap.hasData
                              ? ShoutCard(
                                  poster: userSnap.data,
                                  doc: docs[1],
                                )
                              : Padding(
                                  padding: EdgeInsets.all(5.0),
                                  child: CircularProgressIndicator());
                        },
                      )
                    : Container(),

                //shout box actions
                Container(
                  margin: EdgeInsets.fromLTRB(2.0, 10.0, 2.0, 0.0),
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 204, 206, 209),
                      borderRadius: BorderRadius.circular(5.0)),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          MaterialButton(
                            onPressed: () {
                              Navigator.pushNamed(context, "/post_shout");
                            },
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.hearing),
                                Text("Shout")
                              ],
                            ),
                          ),
                          MaterialButton(
                            onPressed: () {
                              Navigator.pushNamed(context, "/shout_history");
                            },
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.history),
                                Text("History")
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 7.0,
                        decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(5.0),
                                bottomRight: Radius.circular(5.0))),
                      )
                    ],
                  ),
                )
              ],
            );
          }),
    );
  }
}

class ShoutCard extends StatefulWidget {
  final User poster;
  final DocumentSnapshot doc;

  ShoutCard({@required this.poster, @required this.doc});

  @override
  _ShoutCardState createState() => _ShoutCardState();
}

class _ShoutCardState extends State<ShoutCard> {
  CollectionReference likesRef;
  User currentUser;
  bool liked = false;

  @override
  void initState() {
    super.initState();
    likesRef =
        Firestore.instance.collection("/shouts/${widget.doc.documentID}/likes");
  }

  final List<String> menuOptions = const <String>["Delete", "Report to Staff"];

  void _viewProfile(User user) {
    print(user.displayName);
  }

  void _onLike() async {
    currentUser = await getCurrentUser();
    likesRef.document(currentUser.uid).setData({});
  }

  void _onUnlike() async {
    currentUser = await getCurrentUser();
    likesRef.document(currentUser.uid).delete().catchError((e) {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(2.0),
      padding: EdgeInsets.all(3.0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0), color: Colors.white),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              //avatar and name
              Container(
                margin: EdgeInsets.only(left: 5.0, top: 3.0),
                child: InkWell(
                  onTap: () => _viewProfile(widget.poster),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(widget.poster.photoUrl == null
                        ? "https://www.shareicon.net/download/512x512/2016/09/15/829473_man_512x512.png"
                        : widget.poster.photoUrl),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.only(left: 10.0),
                  child: InkWell(
                    child: Text(
                      widget.poster.displayName,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _viewProfile(widget.poster),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: null,
                itemBuilder: (BuildContext context) {
                  return menuOptions.map((String s) {
                    return PopupMenuItem<String>(
                      value: s,
                      child: Text(s),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          Container(
            width: double.infinity,
            height: 1.0,
            color: Colors.black26,
            margin: EdgeInsets.only(bottom: 20.0, top: 5.0),
          ),

          //date time
          Container(
            alignment: Alignment.topRight,
            child: Text(formatDate((widget.doc.data["timestamp"] as DateTime), [yyyy,"-",mm,"-",dd," ",HH,":",nn," ",am])),
          ),

          //shout text
          Html(
            data: widget.doc.data["shout"],
          ),
          Container(
            margin: EdgeInsets.only(top: 5.0),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(
                        style: BorderStyle.solid,
                        width: 1.0,
                        color: Colors.black26))),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    FutureBuilder<User>(
                      future: getCurrentUser(),
                      builder:
                          (BuildContext context, AsyncSnapshot<User> userSnap) {
                        if (!userSnap.hasData)
                          return Row(
                            children: <Widget>[
                              Icon(Icons.thumb_up),
                              Text("Like")
                            ],
                          );
                        return StreamBuilder<QuerySnapshot>(
                          stream: Firestore.instance
                              .collection(
                                  "/shouts/${widget.doc.documentID}/likes")
                              .snapshots(),
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot> snapshots) {
                            if (!snapshots.hasData)
                              return GestureDetector(
                                onTap: liked ? _onUnlike : _onLike,
                                child: Row(
                                  children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Icon(Icons.thumb_up),
                                    ),
                                    Text("Like")
                                  ],
                                ),
                              );
                            if (snapshots.data.documents
                                .map((doc) {
                                  return doc.documentID;
                                })
                                .toList()
                                .contains(userSnap.data.uid)) {
                              liked = true;
                              return GestureDetector(
                                onTap: liked ? _onUnlike : _onLike,
                                child: Row(
                                  children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Icon(
                                        Icons.thumb_up,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      "Unlike[${snapshots.data.documents.length}]",
                                      style: TextStyle(
                                        color: Colors.blue,
                                      ),
                                    )
                                  ],
                                ),
                              );
                            } else {
                              liked = false;
                              return GestureDetector(
                                onTap: liked ? _onUnlike : _onLike,
                                child: Row(
                                  children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Icon(
                                        Icons.thumb_up,
                                      ),
                                    ),
                                    Text(
                                        "Like[${snapshots.data.documents.length}]")
                                  ],
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                    Row(
                      children: <Widget>[
                        IconButton(icon: Icon(Icons.message), onPressed: null),
                        Text("Comment")
                      ],
                    ),
                  ],
                ),
                Container(
                  height: 7.0,
                  decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(5.0),
                          bottomRight: Radius.circular(5.0))),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
