// import 'dart:html';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'かしかりメモ',
      home: List(),
    );
  }
}

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

class InputForm extends StatefulWidget {
  InputForm(this.document);
  final DocumentSnapshot document;

  @override
  _MyInputFormState createState() => _MyInputFormState();
}

class _FormData {
  String borrowOrLend = "borrow";
  String user;
  String stuff;
  DateTime date = DateTime.now();
}

class _MyInputFormState extends State<InputForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();

  Future <DateTime> _selectTime(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: _data.date,
      firstDate: DateTime(_data.date.year - 2),
      lastDate: DateTime(_data.date.year + 2),
    );
  }

  void _setLendOrRent(String value) {
    setState(() {
      _data.borrowOrLend = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference _mainReference;
    _mainReference = FirebaseFirestore.instance.collection('kashikari-memo').doc();

    if (widget.document != null) {
      if (_data.user == null && _data.stuff == null) {
        _data.borrowOrLend = widget.document['borrowOrLend'];
        _data.user = widget.document['user'];
        _data.stuff = widget.document['stuff'];
        _data.date = widget.document['date'].toDate();
      }

      _mainReference = FirebaseFirestore.instance.collection('kashikari-memo').doc(widget.document.id);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('貸し借り入力'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                print("保存ボタンを押しました");
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  _mainReference.set(
                    {
                      'borrowOrLend': _data.borrowOrLend,
                      'user': _data.user,
                      'stuff': _data.stuff,
                      'date': _data.date
                    },
                    SetOptions(merge: true),
                  );
                  Navigator.pop(context);
                }
              }
              ),
          IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                print("削除ボタンを押しました");
              }
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.person),
                  hintText: '相手の名前',
                  labelText: '誰に',
                ),
                onSaved: (String value) {
                  _data.user = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return '名前は必須入力項目です';
                  }
                },
                initialValue: _data.user,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.business_center),
                  hintText: '借りたもの、貸したもの',
                  labelText: '何を',
                ),
                onSaved: (String value) {
                  _data.stuff = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return '借りたもの、貸したものは必須入力項目です';
                  }
                },
                initialValue: _data.stuff,
              ),
              RadioListTile(
                value: "borrow",
                groupValue: _data.borrowOrLend,
                title: Text("借りた"),
                onChanged: (String value) {
                  print("借りたを押しました");
                  _setLendOrRent(value);
                },
              ),
              RadioListTile(
                value: "lend",
                groupValue: _data.borrowOrLend,
                title: Text("貸した"),
                onChanged: (String value) {
                  print("貸したを押しました");
                  _setLendOrRent(value);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("期限: ${_data.date.toString().substring(0, 10)}"),
              ),
              RaisedButton(
                child: const Text("締め切り日変更"),
                onPressed: () {
                  print("締め切り日変更をタップしました");
                  _selectTime(context).then((time) {
                    if (time != null && time != _data.date) {
                      setState(() {
                      _data.date = time;
                      });
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}
