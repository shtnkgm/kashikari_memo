import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'input_form.dart';

class List extends StatefulWidget {
  @override
  _MyList createState() => _MyList();
}

class _MyList extends State<List> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("リスト画面"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('kashikari-memo').snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return const Text('読み込み中...');
              log(snapshot.data.docs.length);
              return ListView.builder(
                itemCount: snapshot.data.docs.length,
                padding: const EdgeInsets.only(top: 10.0),
                itemBuilder: (context, index) => _buildListItem(context, snapshot.data.docs[index]),
              );
            }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          print("新規作成ボタンを押しました");
          Navigator.push(
            context,
            MaterialPageRoute(
                settings: const RouteSettings(name: "/new"),
                builder: (BuildContext context) => InputForm(null)
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.add_shopping_cart_sharp),
            title: Text("[" + (document['borrowOrLend'] == "lend" ? "貸" : "借") + "] " + document['stuff']),
            subtitle: Text('期限: ' + DateTime.parse(document['date'].toDate().toString()).toString().substring(0, 10) + "\n相手:" + document['user']),
          ),
          ButtonTheme.bar(
            child: ButtonBar(
              children: <Widget>[
                FlatButton(child: const Text('編集'),
                    onPressed: (){
                      print("編集ボタンを押しました");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            settings: const RouteSettings(name: "/edit"),
                            builder: (BuildContext context) => InputForm(document)
                        ),
                      );
                    }),
              ],
            ),
          )
        ],
      ),
    );
  }
}